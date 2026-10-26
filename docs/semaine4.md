# Semaine 4 : tests approfondis et qualité, notes du binôme

## 1. Couverture

- **Avant (étape A)** : 91 % sur `api/` (6 lignes jamais exécutées : lignes 49, 76, 78, 79, 85, 87 de `api/main.py`).
- **Pour chacune, le comportement qu'aucun test ne vérifiait** :
  - Ligne 49 : cas où le modèle n'est pas chargé dans `app.state` (retour 503).
  - Ligne 76 : exception `ValueError` levée lors de la prédiction (retour 422).
  - Lignes 78-79 : exception inattendue quelconque journalisée puis convertie en 500 interne.
  - Lignes 85 et 87 : bloc `if __name__ == "__main__":` d'exécution directe avec uvicorn.
- **Après (étape D)** : 100 % de couverture sur `api/` (87/87 instructions couvertes).
- **Ligne exclue de la mesure et justification** : seul le bloc `if __name__ == "__main__":` a reçu `# pragma: no cover` car l'API est démarrée en production par la commande CLI `uvicorn api.main:app` ou par un orchestrateur/conteneur, et jamais par exécution directe du script `main.py`.

## 2. Défauts trouvés

| Symptôme | Test qui l'a révélé | Correction |
| --- | --- | --- |
| Chaîne d'espaces `{"text": "   "}` acceptée par le schéma Pydantic (`len >= 1`) au lieu de renvoyer une 422 structurée | `test_frontieres_du_contrat[texte-espaces]` et test de propriété hypothesis `test_propriete_texte_blancs` | Ajout d'un `@field_validator("text")` dans `api/schemas.py` vérifiant `bool(v.strip())` |
| Panne interne du modèle (`ValueError`) renvoyant par erreur un code 422 avec fuite du message d'erreur interne | `test_modele_en_panne_value_error` dans `tests/test_integration.py` | Suppression de l'interception `except ValueError` dans `api/main.py` pour laisser le bloc `except Exception` renvoyer une 500 générique |
| Avis constitué de mots inventés classifié arbitrairement avec confiance basse (~52 %) | Contrôle T24 sur textes inconnus | Ajout d'une constante `SEUIL_ABSTENTION = 0.60` dans `api/model.py` renvoyant le label `INDETERMINE` sous ce seuil |
| Absence de contrôle sur les classes du modèle chargé au démarrage | `test_modele_classes_inconnues_refuse_demarrage` dans `tests/test_integration.py` | Vérification stricte dans `SentimentClassifier.__init__` que `set(pipeline.classes_)` correspond à `LABEL_MAPPING` |

## 3. Seuil d'abstention

- **Points de la courbe (`python src/courbe_seuil.py`)** :
  - Seuil 0.50 : 58 avis (100 %), exactitude 0.879, 7 erreurs, 0 renvoyé vers un humain.
  - Seuil 0.60 : 42 avis (72 %), exactitude 0.952, 2 erreurs, 16 renvoyés vers un humain.
  - Seuil 0.70 : 37 avis (64 %), exactitude 1.000, 0 erreur, 21 renvoyés vers un humain.
- **Seuil retenu** : 0.60.
- **Part des avis envoyés à un humain** : 16 avis sur 58 (soit 28 %).
- **Justification** : Le seuil de 0.60 fait passer l'exactitude de 87,9 % à 95,2 % en éliminant 5 erreurs sur les 7 commises par le modèle (réduction de 71 % des erreurs), tout en conservant une forte automatisation (72 % des avis restent traités immédiatement sans intervention humaine).

## 4. Jeu d'or

- **Bilan (`python src/bilan_jeu_or.py`)** : sur 20 avis rédigés : 13 justes, 6 abstentions (`INDETERMINE`), 1 erreur franche déclarée (0 erreur franche non déclarée).
- **Ce que ces chiffres disent du modèle** : Le classifieur linéaire sur sac de mots fonctionne de manière robuste sur des formulations directes contenant les n-grammes d'apprentissage (livraison rapide, service impeccable, produit cassé). Il s'abstient sainement face à des registres hors domaine (ex: mécanique) ou des avis nuancés. En revanche, il reste aveugle à la sémantique complexe : un terme positif fort comme « qualité » masque totalement des qualificatifs négatifs hors vocabulaire (« médiocre », « bâclées »), conduisant à une erreur franche déclarée en `xfail`.

## 5. Outils statiques

- **Remarques au départ** : 11 remarques de ruff (E741, B904, B905, F401, I001) ; 0 remarque de mypy (car le typage était lâche et renvoyait du `Any`).
- **Analyse des apports** : Parmi les 4 défauts fonctionnels identifiés dans la partie 2, **aucun** n'avait été détecté par ruff ou mypy. Les analyseurs statiques garantissent la propreté stylistique, le respect des imports et la cohérence des signatures, mais sont totalement incapables de repérer des failles logiques dans les contrats d'API, l'absence de gestion d'abstention ou des gestions d'exception erronées à l'exécution. Les tests dynamiques (limites, propriétés, intégration) restent indispensables.
