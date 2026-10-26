# Semaine 5 : l'interface, notes du binôme

## 1. Pourquoi l'interface n'importe-t-elle jamais `predict()` ni le fichier `.joblib` ?

L'interface Streamlit est conçue comme un client léger (frontend) strictement découplé du backend de prédiction. Elle communique avec le service d'inférence exclusivement par requêtes HTTP via le module client (`ui.client`).

Ce découplage architectural apporte trois bénéfices essentiels :
1. **Économie de ressources** : l'interface ne charge pas les artefacts volumineux (`.joblib`) ni les bibliothèques lourdes d'apprentissage statistique (scikit-learn), ce qui accélère son démarrage et réduit son empreinte mémoire.
2. **Déploiement indépendant** : l'interface et l'API peuvent évoluer, être déployées et être redimensionnées sur des conteneurs ou serveurs distincts sans dépendance directe de code.
3. **Respect du contrat d'interface** : toute refonte interne du modèle (changement d'algorithme ou de bibliothèque de ML) reste totalement transparente pour l'interface tant que le schéma OpenAPI (`PredictRequest` et `PredictResponse`) est maintenu.

## 2. Que montre l'interface quand le modèle hésite, et pourquoi est-ce mieux qu'un verdict forcé ?

Quand la probabilité maximale calculée par le classifieur est inférieure au seuil d'abstention (`SEUIL_ABSTENTION = 0.60`), l'API renvoie le verdict `INDETERMINE`. L'interface Streamlit affiche alors l'indicateur « Je ne sais pas : à faire vérifier par un humain », le pourcentage de confiance exact (ex: 52 %), et affiche une bannière informative : « La confiance est sous le seuil d'abstention : un humain doit trancher ».

Ce comportement est nettement préférable à un verdict forcé binaire (positif/négatif) car il prévient les erreurs de décision dommageables sur les requêtes ambiguës, bruitées ou contenant des mots hors vocabulaire. L'abstention contrôlée fiabilise le système et protège l'expérience utilisateur en transmettant les cas critiques à un relecteur humain.

## 3. Que voit l'utilisateur quand l'API tombe ? Et le fichier `data/avis_exemple.csv` : combien d'avis partent vers un humain ?

- **Quand l'API est arrêtée ou injoignable** : le client intercepte l'exception réseau (`httpx.ConnectError`) et l'interface affiche un message d'alerte explicite : `API injoignable : lancez d'abord uvicorn api.main:app`. L'utilisateur comprend immédiatement l'origine du problème technique et l'application ne plante pas.
- **Sur le fichier `data/avis_exemple.csv`** : sur les 6 avis analysés en lot, exactement **1 avis** part vers un humain : l'avis « xqzvb wlkptr grombu » qui obtient le verdict `INDETERMINE` (confiance de 52 %). Le résumé global donne : `{'INDETERMINE': 1, 'NEGATIVE': 2, 'POSITIVE': 3}`.
