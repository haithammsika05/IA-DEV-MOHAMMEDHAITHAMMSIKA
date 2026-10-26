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

## TP3 à TP6
*(Sera complété au fil de l'avancement de chaque TP)*
