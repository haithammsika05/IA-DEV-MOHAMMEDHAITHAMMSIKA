# Liste des captures d'écran à réaliser

Pour chaque contrôle, effectuez la capture avec `Windows + Maj + S` (zone : commande et résultat), puis enregistrez au format PNG dans le dossier `docs/captures/` avec le nom exact indiqué.

---

## 0. La préparation des postes
- [ ] `docs/captures/tp0-poste-membre-a.png`  
  *Commande* : `py -0 ; py -3.11 --version ; git --version ; git config --global user.name`
- [ ] `docs/captures/tp0-poste-membre-b.png`  
  *Même écran ou terminal montrant le poste unique pour travail individuel.*

---

## TP1 : Cadrer l'application et préparer l'environnement
- [ ] `docs/captures/tp1-t0-structure.png`  
  *Commande* : `Get-ChildItem -Force` à la racine montrant tous les dossiers.
- [ ] `docs/captures/tp1-t1-pytest.png`  
  *Commande* : Sortie du premier lancement de pytest.
- [ ] `docs/captures/tp1-t2-cadrage.png`  
  *Commande* : `python -m pytest tests/test_cadrage.py -q` montrant `12 passed`.
- [ ] `docs/captures/tp1-t3-depot-github.png`  
  *Capture* : Page web GitHub du dépôt `https://github.com/haithammsika05/IA-DEV-MOHAMMEDHAITHAMMSIKA` montrant les fichiers après le premier push.
- [ ] `docs/captures/tp1-t4-check-setup-b.png`  
  *Commande* : Sortie de `python scripts/check_setup.py` montrant `0 erreur(s)`.
- [ ] `docs/captures/tp1-t5-shortlog.png`  
  *Commande* : `git shortlog -sn --all` et le résultat du test `test_git_history.py`.
- [ ] `docs/captures/tp1-t6-pytest.png`  
  *Commande* : `python -m pytest -q` final du TP1.
- [ ] `docs/captures/tp1-t6-actions.png`  
  *Capture* : Onglet GitHub Actions sur le navigateur montrant l'exécution CI.
- [ ] `docs/captures/tp1-t7-clone-frais.png`  
  *Commande* : Diagnostic et pytest exécutés dans le dossier cloné temporaire `verif`.

---

## TP2 : Entraîner, évaluer et sauvegarder le modèle
- [ ] `docs/captures/tp2-c1-pytest.png`  
  *Commande* : Exécution de `appliquer_tp2.py` puis `pytest -q`.
- [ ] `docs/captures/tp2-c2-make-demo.png`  
  *Commande* : `python src/make_demo.py` affichant 290 avis écrits.
- [ ] `docs/captures/tp2-c3-train.png`  
  *Commande* : `python src/train.py` et `git status --short`.
- [ ] `docs/captures/tp2-c4-evaluate.png`  
  *Commande* : `python src/evaluate.py` affichant la matrice de confusion.
- [ ] `docs/captures/tp2-c5-allocine.png`  
  *Commande* : `python src/train.py --allocine` et `pytest -q`.
- [ ] `docs/captures/tp2-membre-b.png`  
  *Commande* : Résultat de pytest pour le poste du membre B.

---

## TP3 : Exposer le modèle par une API
- [ ] `docs/captures/tp3-t14-pytest.png`  
  *Commande* : Exécution de `appliquer_tp3.py`, `src/train.py`, et `pytest -q`.
- [ ] `docs/captures/tp3-t15-health.png`  
  *Capture* : Documentation interactive Swagger (`/docs`) exécutant `GET /health` renvoyant 200 OK.
- [ ] `docs/captures/tp3-t16-positif.png`  
  *Capture* : Requête `POST /predict` avec avis positif renvoyant label POSITIVE (0.777).
- [ ] `docs/captures/tp3-t17-negatif.png`  
  *Capture* : Requête `POST /predict` avec avis négatif renvoyant label NEGATIVE (0.7465).
- [ ] `docs/captures/tp3-t18-refus.png`  
  *Capture* : Requête `POST /predict` invalide renvoyant 422 Unprocessable Entity.
- [ ] `docs/captures/tp3-t19-actions.png`  
  *Capture* : Onglet GitHub Actions montrant le workflow de la semaine 3.
- [ ] `docs/captures/tp3-t20-sans-modele.png`  
  *Commande* : Tentative de démarrage de l'API sans modèle avec exception FileNotFoundError.
- [ ] `docs/captures/tp3-membre-b.png`  
  *Commande* : Résultat de pytest pour le poste du membre B.

---

## TP4 : Tests approfondis et qualité
- [ ] `docs/captures/tp4-t21-couverture.png`  
  *Commande* : `python -m pytest -q --cov=api --cov-report=term-missing` montrant la couverture initiale à 91 % et les 6 lignes manquantes.
- [ ] `docs/captures/tp4-t22-espaces.png`  
  *Capture* : Documentation interactive `/docs` montrant `POST /predict` avec `{"text": "   "}` renvoyant 422 avec detail en liste.
- [ ] `docs/captures/tp4-t23-proprietes.png`  
  *Commande* : `python -m pytest -q tests/test_limites.py` affichant `10 passed`.
- [ ] `docs/captures/tp4-t24-courbe.png`  
  *Commande* : `python src/courbe_seuil.py` affichant la table seuil / exactitude / erreurs.
- [ ] `docs/captures/tp4-t24-indetermine.png`  
  *Capture* : Documentation interactive `/docs` montrant un texte inventé recevant l'étiquette `INDETERMINE`.
- [ ] `docs/captures/tp4-t25-jeu-or.png`  
  *Commande* : `python src/bilan_jeu_or.py` affichant le bilan sur les 20 avis.
- [ ] `docs/captures/tp4-t26-couverture.png`  
  *Commande* : `python -m pytest -q --cov=api --cov-report=term-missing --cov-fail-under=95` affichant 100 % de couverture.
- [ ] `docs/captures/tp4-t27-pre-commit.png`  
  *Commande* : Tentative de commit fautif rejetée par le crochet pre-commit (`ruff` ou `mypy`).
- [ ] `docs/captures/tp4-t27-actions.png`  
  *Capture* : Onglet GitHub Actions montrant le workflow du TP4 avec les étapes ruff, mypy et couverture.
- [ ] `docs/captures/tp4-membre-b.png`  
  *Commande* : Sortie de `python -m pytest -q` après pull et entraînement sur le poste membre B.

---

## TP5 : L'interface Streamlit
- [ ] `docs/captures/tp5-t28-pytest.png`  
  *Commande* : `python -m pytest -q` affichant `95 passed` (12 tests de plus qu'au TP4).
- [ ] `docs/captures/tp5-t29-page.png`  
  *Capture* : Page Streamlit sur `http://localhost:8501` montrant `API prête : tfidf-logreg (TP2, models/sentiment.joblib)`.
- [ ] `docs/captures/tp5-t30-positif.png`  
  *Capture* : Saisie de « Livraison rapide, produit conforme, très satisfait » montrant `Avis positif, 78 %`.
- [ ] `docs/captures/tp5-t30-negatif.png`  
  *Capture* : Saisie de « Produit cassé et service injoignable, à fuir » montrant `Avis négatif, 75 %`.
- [ ] `docs/captures/tp5-t31-abstention.png`  
  *Capture* : Saisie de mots inventés « xqzvb wlkptr grombu » montrant `Je ne sais pas : à faire vérifier par un humain, 52 %` et le message de seuil.
- [ ] `docs/captures/tp5-t32-refus.png`  
  *Capture* : Saisie de trois espaces affichant l'avertissement `Texte refusé : vide, fait d'espaces, ou de plus de 2000 caractères.`
- [ ] `docs/captures/tp5-t32-injoignable.png`  
  *Capture* : API arrêtée affichant l'erreur `API injoignable : lancez d'abord uvicorn api.main:app`.
- [ ] `docs/captures/tp5-t33-lot.png`  
  *Capture* : Onglet « Un fichier d'avis » avec `data/avis_exemple.csv` montrant le tableau, le résumé `{'INDETERMINE': 1, 'NEGATIVE': 2, 'POSITIVE': 3}` et le bouton Télécharger.
- [ ] `docs/captures/tp5-t34-actions.png`  
  *Capture* : Onglet GitHub Actions montrant le workflow du TP5 avec Streamlit et les tests.
- [ ] `docs/captures/tp5-membre-b.png`  
  *Commande* : Sortie de `python -m pytest -q` et lancement de Streamlit pour le membre B.

---

## TP6
*(Sera complété au fil de l'avancement du TP6)*
