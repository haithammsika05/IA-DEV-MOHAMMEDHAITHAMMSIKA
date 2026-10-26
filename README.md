# sentiment-app : dépôt du binôme

Application fil rouge du cours *Développement et déploiement d'applications intelligentes*.

Ce dépôt grandit chaque semaine ; la semaine 1 met en place le cadrage et l'environnement.

## Installation (3 commandes)

```bash
python -m venv .venv
source .venv/bin/activate
# Windows PowerShell : .\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

## Vérifier son installation

```bash
python scripts/check_setup.py
pytest -q
```

La démarche complète de test, étape par étape, est dans `TESTS.md`.

## Structure

```text
sentiment-app/
├── README.md
├── TP1-ENONCE.md
├── TESTS.md
├── requirements.txt
├── .gitignore
├── data/           # Jeux de données
├── models/         # Modèles entraînés (jamais dans Git)
├── app/            # API FastAPI (semaine 3)
├── ui/             # Streamlit (semaine 5)
├── tests/          # Tests pytest
├── scripts/        # Scripts utilitaires
└── docs/cadrage/   # Fiches de cadrage du TP1
```

## Membres du binôme

| Rôle | Nom | Identifiant GitHub | Travail de la semaine 1 |
|---|---|---|---|
| Membre A | Mohammed Haitham Msika | [@haithammsika05](https://github.com/haithammsika05) | Création du dépôt GitHub, initialisation Git, premier commit et configuration de l'environnement Python |
| Membre B | Mohammed Haitham Msika | [@haithammsika05](https://github.com/haithammsika05) | Travail individuel (rôle B) : vérification de l'environnement et validation des tests |

## Objectifs de la semaine 1

- [x] Création du dépôt Git et premier commit
- [x] Publication du projet sur GitHub
- [x] Préparation de l'environnement Python
- [ ] Compléter les trois fiches de cadrage
- [ ] Vérifier les tests avec `pytest -q`
- [ ] Vérifier que les deux membres ont chacun un commit
