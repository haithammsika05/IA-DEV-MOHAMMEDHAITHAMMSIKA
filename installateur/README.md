# Installateur Windows autonome — `sentiment_app`

Ce dossier contient l'outillage permettant de transformer la roue Python `dist\sentiment_app-<version>-py3-none-any.whl` en un installateur Windows autonome (`sentiment-app-<version>-setup.exe`), utilisable sur un poste client **sans Python ni connexion Internet**.

---

## 1. Principe technique

1. **Python embarqué officiel (*Windows embeddable package*)** :
   Lors de la construction, le script télécharge l'archive officielle `python-<version>-embed-amd64.zip` (~11 Mo) depuis `python.org` dans la même version que l'interpréteur Python actif et la décompresse dans `installateur\build\app\python`.
2. **Pré-installation binaire des dépendances** :
   La roue `sentiment_app` (qui embarque le modèle `.joblib`) ainsi que toutes ses dépendances compilées (`numpy`, `scipy`, `scikit-learn`, `joblib`, `threadpoolctl`) sont installées à l'avance dans `build\app\python\Lib\site-packages` via :
   ```powershell
   pip install --target build\app\python\Lib\site-packages --platform win_amd64 --only-binary=:all: -c contraintes.txt <roue>
   ```
   Rien n'est téléchargé chez le client lors de l'installation.
3. **Isolement total (`python3XX._pth`)** :
   Le fichier `python3XX._pth` du Python embarqué est réécrit (en UTF-8 sans BOM) avec uniquement :
   ```text
   python311.zip
   .
   Lib\site-packages
   ```
   Sans directive `import site`, le Python embarqué ignore `PYTHONPATH`, le registre Windows et toute autre installation de Python présente sur la machine du client.
4. **Cohérence stricte des versions avec le modèle entraîné** :
   Un modèle `.joblib` sérialisé avec `scikit-learn` et `numpy` doit être relu par les **mêmes versions** que celles ayant servi à l'entraîner. Le script relève `pip freeze` de l'environnement actif `.venv` dans un fichier de contraintes temporaire (`build\contraintes.txt`), l'impose à `pip install`, puis vérifie que les paquets installés et le modèle `.joblib` sont parfaitement cohérents. En cas d'écart, la construction s'arrête immédiatement avec `ECHEC : versions incohérentes avec le modèle`.
5. **Lanceur portable (`sentiment.cmd`)** :
   L'exécutable `sentiment.exe` généré par `pip` contenant le chemin absolu du Python du développeur, il est supprimé et remplacé par `sentiment.cmd`. Ce lanceur invoque `"%~dp0python\python.exe"`, transmet tous les arguments (`%*`) et propage le code de retour (`exit /b %ERRORLEVEL%`).

---

## 2. Prérequis (poste de construction)

- **Système** : Windows 10/11 (64 bits), PowerShell 5.1+.
- **Environnement Python** : l'environnement virtuel `.venv` ayant entraîné le modèle `.joblib`.
- **Roue construite** : `dist\sentiment_app-<version>-py3-none-any.whl` (produite par `python -m build --wheel`).
- **Inno Setup 6** : nécessaire pour l'étape 5 (compilation du `.exe`). S'il n'est pas encore installé :
  ```powershell
  winget install JRSoftware.InnoSetup
  ```
- **Accès réseau** : requis **uniquement** sur la machine de construction (téléchargement de `python-<version>-embed-amd64.zip` et des roues binaires si absentes du cache `pip`).

---

## 3. Construction de l'installateur

Depuis la **racine du dépôt** :

```powershell
# Construction complète (build\app + vérification + compilation setup.exe)
powershell -ExecutionPolicy Bypass -File installateur\build_installateur.ps1
```

### Options disponibles

| Paramètre | Description | Défaut |
| :--- | :--- | :--- |
| `-Roue <chemin>` | Chemin vers le fichier `.whl` à empaqueter | Roue la plus récente dans `dist\` |
| `-PythonVersion <x.y.z>` | Version du Python embarqué à récupérer sur `python.org` | Version du Python actif |
| `-SansCompilation` | Prépare et valide `build\app` (étapes 1 à 4) sans appeler Inno Setup | Désactivé |

Exemples :

```powershell
# Préparer et vérifier uniquement le dossier autonome build\app (sans Inno Setup)
powershell -ExecutionPolicy Bypass -File installateur\build_installateur.ps1 -SansCompilation

# Forcer une version précise du Python embarqué (ex. si Python 3.11.10+ n'a pas de binaire Windows)
powershell -ExecutionPolicy Bypass -File installateur\build_installateur.ps1 -PythonVersion 3.11.9
```

### Les 5 étapes du script

1. **Vérifications** : détection de la roue et extraction de la version, détection du Python actif, recherche de `ISCC.exe` (dans `PATH`, `%LOCALAPPDATA%\Programs\Inno Setup 6`, `C:\Program Files (x86)\Inno Setup 6`).
2. **Python embarqué** : téléchargement de `python-<version>-embed-amd64.zip`, extraction dans `installateur\build\app\python`, réécriture de `python3XX._pth`.
3. **Installation** : génération de `contraintes.txt` depuis `pip freeze`, installation binaire dans `Lib\site-packages`, affichage d'une ligne `+ <paquet> <version>` par paquet, mise en place de `sentiment.cmd` et `LISEZMOI.txt`.
4. **Vérification en conditions réelles** : contrôle des versions par rapport au modèle et aux contraintes, puis 4 tests via `build\app\sentiment.cmd` (`--version`, avis positif, avis négatif en `--json`, texte vide renvoyant le code `2`) et calcul de la taille de `build\app`.
5. **Compilation** : appel de `ISCC.exe` sur `sentiment.iss` et génération de `installateur\Output\sentiment-app-<version>-setup.exe` avec affichage de son empreinte `SHA-256`.

---

## 4. Test en conditions clientes (Windows Sandbox, sans Python)

Pour valider l'installateur comme un vrai client sur une machine vierge :

1. Activez et lancez **Windows Sandbox** (ou une machine virtuelle Windows sans Python), puis copiez-y `installateur\Output\sentiment-app-<version>-setup.exe`.
2. Double-cliquez sur `sentiment-app-<version>-setup.exe`, cliquez sur **Suivant** (la case « Ajouter le dossier d'installation au PATH de l'utilisateur » est cochée par défaut) et terminez l'installation (aucun droit administrateur n'est demandé, installation dans `%LOCALAPPDATA%\Programs\sentiment-app`).
3. Ouvrez un **nouveau terminal** (`PowerShell` ou `cmd`) et vérifiez :
   ```powershell
   # 1. Aucun Python n'est installé sur la machine
   where.exe python

   # 2. Version de la commande
   sentiment --version

   # 3. Avis positif -> affiche : positive (confiance ...)
   sentiment "Livraison rapide, très satisfait"

   # 4. Avis négatif en JSON -> affiche : {"label": "negative", ...}
   sentiment --json "Colis abîmé, service client injoignable"

   # 5. Texte vide -> affiche : erreur : texte vide (et $LASTEXITCODE vaut 2)
   sentiment " "
   echo $LASTEXITCODE
   ```
4. Vérifiez le raccourci du menu Démarrer : **Menu Démarrer > Sentiment App > Analyser un avis** (ouvre une console affichant `sentiment --help`).
5. Désinstallez l'application via **Paramètres > Applications > Applications installées** (ou le raccourci **Désinstaller** du menu Démarrer), ouvrez un **nouveau terminal**, et vérifiez que `sentiment` est désormais introuvable et que l'entrée a été retirée du `PATH` utilisateur.

---

## 5. Publication et distribution

- **Ne commitez jamais** `installateur/build/` ni `installateur/Output/` dans Git (ces dossiers sont exclus dans `.gitignore`).
- Publiez le fichier `sentiment-app-<version>-setup.exe` en **pièce jointe d'une Release GitHub** associée au tag de version (ex. `v1.0.0`), en indiquant dans les notes de version l'empreinte **SHA-256** affichée par `build_installateur.ps1`.
- **Avertissement Windows SmartScreen** : l'installateur n'étant pas signé avec un certificat de signature de code payant (*Authenticode*), Windows Defender SmartScreen peut afficher un écran « Windows a protégé votre ordinateur » au premier lancement chez le client (cliquer sur *Informations complémentaires* > *Exécuter quand même*).

---

## 6. Problèmes fréquents

| Symptôme | Cause | Solution |
| :--- | :--- | :--- |
| Échec du téléchargement de `python-3.11.10-embed-amd64.zip` (404) | Python.org ne publie plus d'installateurs/archives binaires Windows pour les versions de sécurité `3.11.10+` | Relancer avec `-PythonVersion 3.11.9` |
| `ISCC.exe` introuvable | Inno Setup 6 n'est pas installé sur le poste | Installer avec `winget install JRSoftware.InnoSetup` ou tester avec `-SansCompilation` |
| `ECHEC : versions incohérentes avec le modèle` | Le modèle `.joblib` de la roue a été entraîné avec une version de `scikit-learn`/`numpy` différente de celle de l'environnement actif | Activer le `.venv` d'entraînement (`.venv\Scripts\Activate.ps1`), ré-entraîner ou reconstruire la roue avec cet environnement |
| `'sentiment' n'est pas reconnu...` après l'installation | Le terminal était déjà ouvert avant l'exécution de `setup.exe` | Fermer le terminal et en ouvrir un **nouveau** pour recharger le `PATH` utilisateur |
| Doublon dans le `PATH` lors d'une mise à jour | Mise à jour par-dessus une ancienne version | Géré automatiquement : `sentiment.iss` utilise un `AppId` fixe et vérifie l'absence de doublon dans `HKCU\Environment\Path` |
