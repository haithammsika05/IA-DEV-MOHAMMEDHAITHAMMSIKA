"""Tests d'intégration : l'API telle qu'elle tourne vraiment (TP4, étape D).

Les tests du TP3 vérifient des réponses ; ceux-ci vérifient le démarrage de l'API
et son comportement quand le modèle manque ou tombe en panne.
"""
import sys
from pathlib import Path

import pytest

MODELE = Path(__file__).resolve().parents[1] / "models" / "sentiment.joblib"
pytestmark = pytest.mark.skipif(not MODELE.exists(), reason="modèle non produit : python src/train.py")


def test_demarrage_reel_charge_le_modele():
    """D.1 : un client ouvert par « with » exécute le lifespan."""
    from fastapi.testclient import TestClient

    from api.main import app

    with TestClient(app) as client:
        reponse = client.get("/health")
    assert reponse.status_code == 200
    assert "TP2" in reponse.json()["model"]


def test_modele_absent_refuse_demarrage(monkeypatch):
    """D.2 : chemin du modèle redirigé, cache vidé, l'API refuse de démarrer."""
    from fastapi.testclient import TestClient

    import api.model
    from api.main import app

    predict_mod = sys.modules.get("predict")
    if predict_mod is None:
        import src.predict as predict_mod  # noqa: F401

    predict_mod.charger_modele.cache_clear()
    monkeypatch.setattr(predict_mod, "MODELE", Path("models/absent_inexistant.joblib"))
    monkeypatch.setattr(api.model, "MODELE", Path("models/absent_inexistant.joblib"))

    with pytest.raises(FileNotFoundError, match="absent"):
        with TestClient(app):
            pass


def test_modele_non_charge():
    """D.3 : modèle retiré de app.state, 503 sur /health et /predict."""
    from fastapi.testclient import TestClient

    from api.main import app

    with TestClient(app) as client:
        app.state.classifier = None
        r_health = client.get("/health")
        assert r_health.status_code == 503
        assert r_health.json()["detail"] == "Modèle non chargé"

        r_predict = client.post("/predict", json={"text": "Un texte quelconque"})
        assert r_predict.status_code == 503
        assert r_predict.json()["detail"] == "Modèle non chargé"


def test_modele_en_panne_runtime_error():
    """D.4a : predict lève RuntimeError -> 500 sans fuite de message interne."""
    from fastapi.testclient import TestClient

    from api.main import app

    class PanneRuntimeClassifier:
        model_name = "test-runtime"

        def predict(self, text: str):
            raise RuntimeError("panne matérielle grave")

    with TestClient(app) as client:
        app.state.classifier = PanneRuntimeClassifier()
        reponse = client.post("/predict", json={"text": "Un avis valide"})
        assert reponse.status_code == 500
        assert reponse.json()["detail"] == "Erreur interne du serveur"
        assert "panne matérielle" not in reponse.text


def test_modele_en_panne_value_error():
    """D.4b : predict lève ValueError -> 500 sans fuite de message interne."""
    from fastapi.testclient import TestClient

    from api.main import app

    class PanneValueClassifier:
        model_name = "test-value"

        def predict(self, text: str):
            raise ValueError("bug interne inattendu")

    with TestClient(app) as client:
        app.state.classifier = PanneValueClassifier()
        reponse = client.post("/predict", json={"text": "Un avis valide"})
        assert reponse.status_code == 500
        assert reponse.json()["detail"] == "Erreur interne du serveur"
        assert "bug interne" not in reponse.text


def test_modele_classes_inconnues_refuse_demarrage(monkeypatch):
    """E.3 : modèle avec classes non prévues dans LABEL_MAPPING refuse de démarrer."""
    from fastapi.testclient import TestClient

    import api.model
    from api.main import app

    class DummyModel:
        classes_ = ["neutre", "bizarre"]

    monkeypatch.setattr(api.model, "charger_modele", lambda: DummyModel())

    with pytest.raises(ValueError, match="Classes inconnues"):
        with TestClient(app):
            pass
