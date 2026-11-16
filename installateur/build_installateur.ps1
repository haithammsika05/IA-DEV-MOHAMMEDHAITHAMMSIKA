<#
.SYNOPSIS
    Construit et vérifie l'environnement autonome (build\app) puis compile
    l'installateur Windows setup.exe pour sentiment_app.

.DESCRIPTION
    Exécutable depuis la racine du dépôt :
      powershell -ExecutionPolicy Bypass -File installateur\build_installateur.ps1

.PARAMETER Roue
    Chemin vers le fichier .whl à empaqueter (par défaut : la roue la plus récente dans dist\).

.PARAMETER PythonVersion
    Version du paquet Python embarqué à télécharger depuis python.org
    (par défaut : version exacte du Python actif).

.PARAMETER SansCompilation
    Prépare et vérifie build\app sans appeler Inno Setup (ISCC.exe).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Roue = "",

    [Parameter(Mandatory = $false)]
    [string]$PythonVersion = "",

    [Parameter(Mandatory = $false)]
    [switch]$SansCompilation
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Arreter-EnErreur {
    param([string]$Message)
    Write-Host ""
    Write-Host $Message -ForegroundColor Red
    exit 1
}

function Executer-Externe {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Commande
    )
    $AncienEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $Sortie = & $Commande 2>&1
        $Code = $LASTEXITCODE
        $Lignes = foreach ($Item in $Sortie) {
            if ($Item -is [System.Management.Automation.ErrorRecord]) {
                $Item.Exception.Message
            } else {
                "$Item"
            }
        }
        return [PSCustomObject]@{
            Code   = $Code
            Sortie = ($Lignes -join "`n").Trim()
        }
    } finally {
        $ErrorActionPreference = $AncienEAP
    }
}

try {
    $DossierInstallateur = $PSScriptRoot
    $Racine = Split-Path -Parent $DossierInstallateur
    $DossierBuild = Join-Path $DossierInstallateur "build"
    $DossierBuildApp = Join-Path $DossierBuild "app"
    $DossierPythonEmbarque = Join-Path $DossierBuildApp "python"
    $DossierOutput = Join-Path $DossierInstallateur "Output"

    # =========================================================================
    # ÉTAPE 1 : Vérifications (roue, Python actif, Inno Setup)
    # =========================================================================
    Write-Host "=== [1/5] Vérifications préalables ===" -ForegroundColor Cyan

    # 1.a Recherche de la roue .whl
    if ([string]::IsNullOrWhiteSpace($Roue)) {
        $CandidatsDist = @(
            (Join-Path $Racine "dist"),
            (Join-Path (Get-Location).Path "dist"),
            (Join-Path $DossierInstallateur "dist"),
            (Join-Path $DossierBuild "roue")
        )
        $FichierRoue = $null
        foreach ($DossierDist in $CandidatsDist) {
            if (Test-Path -LiteralPath $DossierDist) {
                $Trouve = Get-ChildItem -LiteralPath $DossierDist -Filter "sentiment*app-*.whl" -File -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -First 1
                if ($null -ne $Trouve) {
                    $FichierRoue = $Trouve
                    break
                }
            }
        }
        if ($null -eq $FichierRoue) {
            Arreter-EnErreur "ERREUR : Aucune roue sentiment_app-*.whl trouvée dans 'dist\'. Construisez d'abord la roue (python -m build --wheel) ou passez -Roue <chemin>."
        }
    } else {
        if (-not (Test-Path -LiteralPath $Roue -PathType Leaf)) {
            Arreter-EnErreur "ERREUR : La roue spécifiée est introuvable : '$Roue'."
        }
        $FichierRoue = Get-Item -LiteralPath $Roue
    }

    $CheminRoue = $FichierRoue.FullName
    if ($FichierRoue.Name -notmatch '^sentiment[_-]app-([0-9]+\.[0-9]+\.[0-9]+[A-Za-z0-9._]*)-.*\.whl$') {
        Arreter-EnErreur "ERREUR : Impossible de lire la version depuis le nom de la roue '$($FichierRoue.Name)'."
    }
    $AppVersion = $Matches[1]
    Write-Host "  Roue trouvée      : $($FichierRoue.Name) (version $AppVersion)"

    # 1.b Détection du Python actif (.venv en priorité)
    $CandidatsPython = @()
    if ($env:VIRTUAL_ENV) {
        $CandidatsPython += (Join-Path $env:VIRTUAL_ENV "Scripts\python.exe")
    }
    $CandidatsPython += (Join-Path $Racine ".venv\Scripts\python.exe")
    $CandidatsPython += (Join-Path (Get-Location).Path ".venv\Scripts\python.exe")

    $CmdPythonPath = Get-Command python.exe -ErrorAction SilentlyContinue
    if ($null -ne $CmdPythonPath -and $CmdPythonPath.Source -notlike "*\WindowsApps\*") {
        $CandidatsPython += $CmdPythonPath.Source
    }
    $CandidatsPython += "C:\IA-DEV\membre-b\sentiment-app\.venv\Scripts\python.exe"
    $CandidatsPython += (Join-Path $env:LOCALAPPDATA "Programs\Python\Python311\python.exe")

    $PythonActif = $null
    foreach ($Candidat in $CandidatsPython) {
        if ($Candidat -and (Test-Path -LiteralPath $Candidat -PathType Leaf)) {
            $PythonActif = (Get-Item -LiteralPath $Candidat).FullName
            break
        }
    }
    if ($null -eq $PythonActif) {
        Arreter-EnErreur "ERREUR : Aucun interpréteur Python actif (.venv) n'a été trouvé. Activez d'abord votre environnement virtuel (.venv\Scripts\Activate.ps1)."
    }

    $ResVerPy = Executer-Externe { & $PythonActif -c "import platform; print(platform.python_version())" }
    if ($ResVerPy.Code -ne 0 -or [string]::IsNullOrWhiteSpace($ResVerPy.Sortie)) {
        Arreter-EnErreur "ERREUR : Impossible d'exécuter le Python actif '$PythonActif'."
    }
    $VersionPythonActif = $ResVerPy.Sortie
    if ([string]::IsNullOrWhiteSpace($PythonVersion)) {
        $PythonVersion = $VersionPythonActif
    }
    Write-Host "  Python actif      : $PythonActif (v$VersionPythonActif)"
    Write-Host "  Python embarqué   : v$PythonVersion"

    # 1.c Recherche d'Inno Setup (ISCC.exe) sauf si -SansCompilation
    $CheminISCC = $null
    if (-not $SansCompilation) {
        $CmdISCC = Get-Command ISCC.exe -ErrorAction SilentlyContinue
        if ($null -ne $CmdISCC) {
            $CheminISCC = $CmdISCC.Source
        } else {
            $CandidatsISCC = @(
                (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe"),
                (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe"),
                (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe"),
                (Join-Path $env:LOCALAPPDATA "Programs\Antigravity IDE\resources\app\node_modules\innosetup\bin\ISCC.exe")
            )
            foreach ($CandidatISCC in $CandidatsISCC) {
                if ($CandidatISCC -and (Test-Path -LiteralPath $CandidatISCC -PathType Leaf)) {
                    $CheminISCC = $CandidatISCC
                    break
                }
            }
        }
        if ($null -eq $CheminISCC) {
            Arreter-EnErreur "ERREUR : Inno Setup 6 (ISCC.exe) est introuvable dans le PATH et les dossiers habituels.`nInstallez-le avec : winget install JRSoftware.InnoSetup`nOu lancez ce script avec l'option -SansCompilation pour préparer et vérifier build\app uniquement."
        }
        Write-Host "  Inno Setup (ISCC) : $CheminISCC"
    } else {
        Write-Host "  Inno Setup (ISCC) : ignoré (-SansCompilation)"
    }

    # =========================================================================
    # ÉTAPE 2 : Téléchargement et configuration du Python embarqué
    # =========================================================================
    Write-Host ""
    Write-Host "=== [2/5] Préparation du Python embarqué ($PythonVersion) ===" -ForegroundColor Cyan

    if (Test-Path -LiteralPath $DossierBuildApp) {
        Remove-Item -LiteralPath $DossierBuildApp -Recurse -Force
    }
    New-Item -ItemType Directory -Path $DossierPythonEmbarque -Force | Out-Null

    $NomZipEmbed = "python-$PythonVersion-embed-amd64.zip"
    $CheminZipEmbed = Join-Path $DossierBuild $NomZipEmbed
    $UrlPythonEmbed = "https://www.python.org/ftp/python/$PythonVersion/$NomZipEmbed"

    if (-not (Test-Path -LiteralPath $CheminZipEmbed -PathType Leaf)) {
        Write-Host "  Téléchargement de $UrlPythonEmbed ..."
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $UrlPythonEmbed -OutFile $CheminZipEmbed -UseBasicParsing
        } catch {
            if (Test-Path -LiteralPath $CheminZipEmbed) {
                Remove-Item -LiteralPath $CheminZipEmbed -Force -ErrorAction SilentlyContinue
            }
            Arreter-EnErreur "ERREUR : Échec du téléchargement de '$UrlPythonEmbed'.`nNote : les versions de maintenance de sécurité (ex. Python 3.11.10+) ne publient pas de binaire Windows sur python.org.`nRelancez la commande avec : -PythonVersion 3.11.9"
        }
    } else {
        Write-Host "  Archive présente en cache : $NomZipEmbed"
    }

    Expand-Archive -LiteralPath $CheminZipEmbed -DestinationPath $DossierPythonEmbarque -Force

    # Réécriture du fichier python3XX._pth pour isoler strictement l'environnement
    $FichierPth = Get-ChildItem -LiteralPath $DossierPythonEmbarque -Filter "python*._pth" -File | Select-Object -First 1
    $FichierZipStdlib = Get-ChildItem -LiteralPath $DossierPythonEmbarque -Filter "python*.zip" -File | Select-Object -First 1
    if ($null -eq $FichierPth -or $null -eq $FichierZipStdlib) {
        Arreter-EnErreur "ERREUR : Fichier ._pth ou archive stdlib introuvable dans le Python embarqué."
    }

    $LignesPth = @(
        $FichierZipStdlib.Name,
        ".",
        "Lib\site-packages"
    )
    $Utf8SansBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($FichierPth.FullName, $LignesPth, $Utf8SansBom)
    Write-Host "  Fichier d'isolement réécrit : $($FichierPth.Name) ($($LignesPth -join ', '))"

    # =========================================================================
    # ÉTAPE 3 : Installation de la roue et de ses dépendances sous contraintes
    # =========================================================================
    Write-Host ""
    Write-Host "=== [3/5] Installation de la roue et des dépendances ===" -ForegroundColor Cyan

    # Relevé de pip freeze de l'environnement actif comme fichier de contraintes
    $FichierContraintes = Join-Path $DossierBuild "contraintes.txt"
    $ResFreeze = Executer-Externe { & $PythonActif -m pip freeze --disable-pip-version-check }
    if ($ResFreeze.Code -ne 0) {
        Arreter-EnErreur "ERREUR : Impossible de relever 'pip freeze' depuis l'environnement actif."
    }

    $LignesContraintes = @()
    $DictContraintes = @{}
    foreach ($Ligne in ($ResFreeze.Sortie -split "`r?`n")) {
        $LignePropre = $Ligne.Trim()
        if ($LignePropre -match '^([A-Za-z0-9_.-]+)==([^;\s]+)$') {
            $NomPkg = $Matches[1]
            $VerPkg = $Matches[2]
            $NomNorm = ($NomPkg.ToLower() -replace '[-_.]', '-')
            if ($NomNorm -ne "sentiment-app") {
                $LignesContraintes += "$NomPkg==$VerPkg"
                $DictContraintes[$NomNorm] = $VerPkg
            }
        }
    }
    [System.IO.File]::WriteAllLines($FichierContraintes, $LignesContraintes, $Utf8SansBom)

    $SitePackages = Join-Path $DossierPythonEmbarque "Lib\site-packages"
    New-Item -ItemType Directory -Path $SitePackages -Force | Out-Null

    $DossierWheelhouse = Join-Path $DossierBuild "wheelhouse"
    if (Test-Path -LiteralPath $DossierWheelhouse) {
        $ResPip = Executer-Externe {
            & $PythonActif -m pip install `
                --target $SitePackages `
                --platform win_amd64 `
                --only-binary=:all: `
                -c $FichierContraintes `
                --no-index `
                --find-links $DossierWheelhouse `
                --no-warn-script-location `
                --disable-pip-version-check `
                $CheminRoue
        }
        if ($ResPip.Code -ne 0) {
            $ResPip = Executer-Externe {
                & $PythonActif -m pip install `
                    --target $SitePackages `
                    --platform win_amd64 `
                    --only-binary=:all: `
                    -c $FichierContraintes `
                    --find-links $DossierWheelhouse `
                    --no-warn-script-location `
                    --disable-pip-version-check `
                    $CheminRoue
            }
        }
    } else {
        $ResPip = Executer-Externe {
            & $PythonActif -m pip install `
                --target $SitePackages `
                --platform win_amd64 `
                --only-binary=:all: `
                -c $FichierContraintes `
                --no-warn-script-location `
                --disable-pip-version-check `
                $CheminRoue
        }
    }

    if ($ResPip.Code -ne 0) {
        Write-Host $ResPip.Sortie -ForegroundColor Yellow
        if ($ResPip.Sortie -match 'Conflict|Incompatible|Constraint|ResolutionImpossible') {
            Arreter-EnErreur "ECHEC : versions incohérentes avec le modèle"
        }
        Arreter-EnErreur "ERREUR : L'installation pip dans le Python embarqué a échoué."
    }

    # Affichage d'une ligne '+' par paquet installé avec sa version
    $DossiersDistInfo = Get-ChildItem -LiteralPath $SitePackages -Filter "*.dist-info" -Directory | Sort-Object Name
    $PaquetsInstalles = @{}
    foreach ($DistInfo in $DossiersDistInfo) {
        $FichierMeta = Join-Path $DistInfo.FullName "METADATA"
        if (Test-Path -LiteralPath $FichierMeta) {
            $NomInst = $null
            $VerInst = $null
            foreach ($LigneMeta in [System.IO.File]::ReadLines($FichierMeta)) {
                if ($null -eq $NomInst -and $LigneMeta -match '^Name:\s*(.+)$') {
                    $NomInst = $Matches[1].Trim()
                } elseif ($null -eq $VerInst -and $LigneMeta -match '^Version:\s*(.+)$') {
                    $VerInst = $Matches[1].Trim()
                }
                if ($null -ne $NomInst -and $null -ne $VerInst) {
                    break
                }
            }
            if ($NomInst -and $VerInst) {
                Write-Host "  + $NomInst $VerInst" -ForegroundColor Green
                $NomNormInst = ($NomInst.ToLower() -replace '[-_.]', '-')
                $PaquetsInstalles[$NomNormInst] = $VerInst
            }
        }
    }

    # Suppression des lanceurs .exe générés par pip (chemins codés en dur vers le Python du poste)
    $DossierBinPip = Join-Path $SitePackages "bin"
    if (Test-Path -LiteralPath $DossierBinPip) {
        Remove-Item -LiteralPath $DossierBinPip -Recurse -Force
    }
    Get-ChildItem -LiteralPath $SitePackages -Filter "sentiment*.exe" -Recurse -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue

    # Si le paquet sentiment_app n'a pas de __main__.py, on s'assure que -m sentiment_app fonctionne
    $DossierPkgSentiment = Join-Path $SitePackages "sentiment_app"
    $FichierMainPkg = Join-Path $DossierPkgSentiment "__main__.py"
    if ((Test-Path -LiteralPath $DossierPkgSentiment) -and -not (Test-Path -LiteralPath $FichierMainPkg)) {
        $ContenuMain = "import sys`nfrom sentiment_app.cli import main`nif __name__ == '__main__':`n    raise SystemExit(main())`n"
        [System.IO.File]::WriteAllText($FichierMainPkg, $ContenuMain, $Utf8SansBom)
    }

    # Copie du lanceur sentiment.cmd et de LISEZMOI.txt dans build\app
    $SourceCmd = Join-Path $DossierInstallateur "sentiment.cmd"
    $SourceLisezMoi = Join-Path $DossierInstallateur "LISEZMOI.txt"
    $CibleCmd = Join-Path $DossierBuildApp "sentiment.cmd"
    $CibleLisezMoi = Join-Path $DossierBuildApp "LISEZMOI.txt"

    Copy-Item -LiteralPath $SourceCmd -Destination $CibleCmd -Force
    Copy-Item -LiteralPath $SourceLisezMoi -Destination $CibleLisezMoi -Force

    # =========================================================================
    # ÉTAPE 4 : Vérification en conditions réelles via build\app\sentiment.cmd
    # =========================================================================
    Write-Host ""
    Write-Host "=== [4/5] Vérification en conditions réelles ===" -ForegroundColor Cyan

    # 4.a Comparaison des versions installées aux contraintes (notamment scikit-learn, numpy, scipy, joblib)
    foreach ($Entree in $PaquetsInstalles.GetEnumerator()) {
        $NomP = $Entree.Key
        $VerP = $Entree.Value
        if ($DictContraintes.ContainsKey($NomP)) {
            $VerAttendue = $DictContraintes[$NomP]
            if ($VerP -ne $VerAttendue) {
                Arreter-EnErreur "ECHEC : versions incohérentes avec le modèle ($NomP installé=$VerP, attendu=$VerAttendue)"
            }
        }
    }

    # Vérification de la cohérence binaire du modèle .joblib avec scikit-learn et numpy dans le Python embarqué
    $PythonEmbarqueExe = Join-Path $DossierPythonEmbarque "python.exe"
    $ScriptVerifModele = @"
import pathlib, sys, warnings
import joblib, numpy, sklearn
from sklearn.exceptions import InconsistentVersionWarning

warnings.simplefilter('error', InconsistentVersionWarning)
racine = pathlib.Path(r'$SitePackages')
modeles = list(racine.rglob('*.joblib'))
if not modeles:
    sys.exit(3)
for m_path in modeles:
    try:
        obj = joblib.load(m_path)
    except Exception as e:
        print(f'INCOHERENCE: {e}')
        sys.exit(4)
    etat = obj.__getstate__() if hasattr(obj, '__getstate__') else {}
    ver_modele = etat.get('_sklearn_version')
    if ver_modele and ver_modele != sklearn.__version__:
        print(f'INCOHERENCE: modele={ver_modele}, sklearn={sklearn.__version__}')
        sys.exit(4)
print(f'COHERENT: scikit-learn={sklearn.__version__}, numpy={numpy.__version__}')
"@
    $AncienPythonPath = $env:PYTHONPATH
    try {
        # On définit volontairement un PYTHONPATH parasite pour vérifier qu'il est ignoré
        $env:PYTHONPATH = "C:\chemin_inexistant_test_isolation"
        $ResVerifModele = Executer-Externe { & $PythonEmbarqueExe -X utf8 -c $ScriptVerifModele }
    } finally {
        $env:PYTHONPATH = $AncienPythonPath
    }

    if ($ResVerifModele.Code -ne 0 -or $ResVerifModele.Sortie -notmatch '^COHERENT:') {
        Arreter-EnErreur "ECHEC : versions incohérentes avec le modèle ($($ResVerifModele.Sortie))"
    }

    # 4.b Exécution des 4 tests fonctionnels via build\app\sentiment.cmd
    # Test 1 : --version
    $ResVer = Executer-Externe { & $CibleCmd --version }
    if ($ResVer.Code -ne 0 -or $ResVer.Sortie -notmatch [regex]::Escape($AppVersion)) {
        Arreter-EnErreur "ERREUR : Test '--version' échoué (code=$($ResVer.Code), sortie='$($ResVer.Sortie)')."
    }
    Write-Host "  OK  --version : $($ResVer.Sortie)" -ForegroundColor Green

    # Test 2 : phrase positive
    $ResPos = Executer-Externe { & $CibleCmd "Livraison rapide, très satisfait" }
    if ($ResPos.Code -ne 0 -or $ResPos.Sortie -notmatch '^positive\s+\(confiance\s+.+\)$') {
        Arreter-EnErreur "ERREUR : Test phrase positive échoué (code=$($ResPos.Code), sortie='$($ResPos.Sortie)')."
    }
    Write-Host "  OK  phrase positive : $($ResPos.Sortie)" -ForegroundColor Green

    # Test 3 : phrase négative en --json
    $ResNeg = Executer-Externe { & $CibleCmd --json "Colis abîmé, service client injoignable" }
    if ($ResNeg.Code -ne 0 -or $ResNeg.Sortie -notmatch '"label"\s*:\s*"negative"') {
        Arreter-EnErreur "ERREUR : Test phrase négative (--json) échoué (code=$($ResNeg.Code), sortie='$($ResNeg.Sortie)')."
    }
    Write-Host "  OK  phrase négative (--json) : $($ResNeg.Sortie)" -ForegroundColor Green

    # Test 4 : texte vide (doit renvoyer le code 2)
    $ResVide = Executer-Externe { & $CibleCmd " " }
    if ($ResVide.Code -ne 2 -or $ResVide.Sortie -notmatch 'texte vide') {
        Arreter-EnErreur "ERREUR : Test texte vide échoué (attendu code 2 et 'erreur : texte vide', obtenu code=$($ResVide.Code), sortie='$($ResVide.Sortie)')."
    }
    Write-Host "  OK  texte vide (code $($ResVide.Code)) : $($ResVide.Sortie)" -ForegroundColor Green

    # Taille totale de build\app
    $OctetsApp = (Get-ChildItem -LiteralPath $DossierBuildApp -Recurse -File | Measure-Object -Property Length -Sum).Sum
    $TailleMo = [math]::Round($OctetsApp / 1MB, 2)
    Write-Host "  Taille du dossier build\app : $TailleMo Mo"

    # =========================================================================
    # ÉTAPE 5 : Compilation de l'installateur Inno Setup
    # =========================================================================
    Write-Host ""
    Write-Host "=== [5/5] Compilation de l'installateur Windows ===" -ForegroundColor Cyan

    if ($SansCompilation) {
        Write-Host "  Compilation ignorée (-SansCompilation). Le dossier build\app est prêt et validé." -ForegroundColor Yellow
        exit 0
    }

    New-Item -ItemType Directory -Path $DossierOutput -Force | Out-Null
    $FichierIss = Join-Path $DossierInstallateur "sentiment.iss"

    $ResISCC = Executer-Externe { & $CheminISCC "/DAppVersion=$AppVersion" $FichierIss }
    if ($ResISCC.Code -ne 0) {
        Write-Host $ResISCC.Sortie -ForegroundColor Red
        Arreter-EnErreur "ERREUR : La compilation Inno Setup (ISCC.exe) a échoué."
    }

    $FichierSetup = Join-Path $DossierOutput "sentiment-app-$AppVersion-setup.exe"
    if (-not (Test-Path -LiteralPath $FichierSetup -PathType Leaf)) {
        Arreter-EnErreur "ERREUR : L'installateur attendu '$FichierSetup' n'a pas été produit."
    }

    $HashSetup = (Get-FileHash -LiteralPath $FichierSetup -Algorithm SHA256).Hash
    $TailleSetupMo = [math]::Round((Get-Item -LiteralPath $FichierSetup).Length / 1MB, 2)

    Write-Host "  Installateur créé : $FichierSetup ($TailleSetupMo Mo)" -ForegroundColor Green
    Write-Host "  SHA-256           : $HashSetup" -ForegroundColor Green

} catch {
    Arreter-EnErreur "ERREUR : $($_.Exception.Message)"
}
