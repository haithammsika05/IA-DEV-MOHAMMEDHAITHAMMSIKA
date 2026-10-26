# Fiche de cadrage : Priorisation des avis négatifs

> Remplir chaque rubrique en une à trois phrases. Les rubriques marquées (obligatoire) sont vérifiées par `pytest`.

## Besoin en une phrase (obligatoire)

Classer et prioriser les avis clients négatifs afin d'aider le service client à traiter en premier les problèmes les plus urgents.


## Utilisateur final (obligatoire)

Les agents du service client et les responsables qualité d'une boutique en ligne.


## Approche retenue (obligatoire)

Cocher une seule case :

- [ ] Règles métier
- [x] Machine learning
- [ ] RAG
- [ ] Modèle génératif seul

## Justification (obligatoire, citer au moins deux critères de la grille : (a) données étiquetées, (b) vérifiabilité, (c) coût par requête, (d) conséquence d'une erreur)

(a) Des avis historiques étiquetés par catégorie et priorité peuvent servir à entraîner et évaluer le modèle. (c) Un modèle automatisé permet de traiter un grand volume d'avis à un coût par requête faible. (d) Une mauvaise priorité peut retarder le traitement d'un problème important, donc un agent doit pouvoir corriger le classement.


## Données nécessaires et leur origine (obligatoire)

Utiliser des avis clients historiques anonymisés et étiquetés par catégorie et priorité, provenant du système de service client, ainsi qu'un jeu de test distinct.


## Métrique de succès et seuil d'acceptation (obligatoire)

Atteindre un F1-score macro d'au moins 0,80 sur un jeu de test séparé et mesurer spécifiquement le rappel de la classe urgente.


## Conséquence d'une erreur et validation humaine prévue (obligatoire)

Un avis urgent mal classé peut retarder une réponse au client. Les agents doivent pouvoir modifier la priorité et traiter manuellement les cas urgents ou incertains.


## Risques éthiques ou de confidentialité (obligatoire)

Les avis peuvent contenir des noms, coordonnées ou informations sensibles. Anonymiser les données, limiter leur conservation et vérifier que le modèle ne défavorise pas certains groupes de clients.


## Approche écartée et pourquoi (facultatif)

