# Fiche de cadrage : Ordonnances incomplètes en pharmacie

> Remplir chaque rubrique en une à trois phrases. Les rubriques marquées (obligatoire) sont vérifiées par `pytest`.

## Besoin en une phrase (obligatoire)

Détecter les informations manquantes ou incohérentes dans une ordonnance avant sa validation par le pharmacien.


## Utilisateur final (obligatoire)

Le pharmacien utilise l'application comme aide au contrôle et reste responsable de la décision finale de délivrance.


## Approche retenue (obligatoire)

Cocher une seule case :

- [x] Règles métier
- [ ] Machine learning
- [ ] RAG
- [ ] Modèle génératif seul

## Justification (obligatoire, citer au moins deux critères de la grille : (a) données étiquetées, (b) vérifiabilité, (c) coût par requête, (d) conséquence d'une erreur)

(a) Aucun jeu de données étiquetées n'est nécessaire pour appliquer des règles explicites. (b) Chaque anomalie peut être expliquée par une règle vérifiable. (d) Une erreur peut avoir des conséquences graves sur la santé, donc le pharmacien doit valider la décision.


## Données nécessaires et leur origine (obligatoire)

Utiliser des ordonnances fictives, les champs de prescription et des règles de vérification validées par des professionnels. Aucune donnée réelle de patient ne doit être utilisée.


## Métrique de succès et seuil d'acceptation (obligatoire)

Atteindre 100 % de détection des anomalies prévues dans un jeu de tests fictifs défini à l'avance, sans présenter ce résultat comme une garantie médicale réelle.


## Conséquence d'une erreur et validation humaine prévue (obligatoire)

Une anomalie non détectée peut contribuer à une erreur de délivrance. Le pharmacien vérifie les alertes et valide toute ordonnance avant toute décision.


## Risques éthiques ou de confidentialité (obligatoire)

Les ordonnances contiennent des données de santé sensibles. Utiliser uniquement des données fictives dans le TP, limiter les accès et protéger les informations.


## Approche écartée et pourquoi (facultatif)

