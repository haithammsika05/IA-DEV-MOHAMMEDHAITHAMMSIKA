"""Raccord entre l'API et le modèle entraîné au TP2.

L'API n'entraîne rien et ne connaît pas scikit-learn : elle appelle la fonction
predict() de src/predict.py, qui charge models/sentiment.joblib une seule fois.
"""
import sys
from pathlib import Path
from typing import Literal, TypedDict

RACINE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(RACINE / "src"))
from predict import charger_modele  # noqa: E402  (fonctions du TP2)
from predict import predict as _predict  # noqa: E402

SEUIL_ABSTENTION: float = 0.60

LABEL_MAPPING: dict[str, Literal["POSITIVE", "NEGATIVE"]] = {
    "positive": "POSITIVE",
    "negative": "NEGATIVE",
}

LabelContrat = Literal["POSITIVE", "NEGATIVE", "INDETERMINE"]


class PredictionResult(TypedDict):
    label: LabelContrat
    score: float
    text: str


class SentimentClassifier:
    """Enveloppe du modèle TP2 avec l'interface attendue par l'API."""

    model_name = "tfidf-logreg (TP2, models/sentiment.joblib)"

    def __init__(self) -> None:
        pipeline = charger_modele()  # échoue immédiatement si le joblib manque : on ne démarre pas sans modèle
        classes_inconnues = set(pipeline.classes_) - set(LABEL_MAPPING.keys())
        if classes_inconnues:
            raise ValueError(f"Classes inconnues dans le modèle : {classes_inconnues}")

    def predict(self, text: str) -> PredictionResult:
        """Renvoie {'label': 'POSITIVE'|'NEGATIVE'|'INDETERMINE', 'score': float, 'text': aperçu}."""
        r = _predict(text)  # lève ValueError si le texte est vide
        score = float(r["score"])
        if score < SEUIL_ABSTENTION:
            label: LabelContrat = "INDETERMINE"
        else:
            label = LABEL_MAPPING.get(r["label"].lower(), "INDETERMINE")
        return {"label": label, "score": score, "text": text[:100]}


def load_model() -> SentimentClassifier:
    """Construit le classifier (le cache de chargement est dans src/predict.py)."""
    return SentimentClassifier()
