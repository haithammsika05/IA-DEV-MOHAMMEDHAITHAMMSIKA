; =============================================================================
; Script Inno Setup 6 pour Sentiment App
; Crée un installateur autonome (sans droits administrateur) embarquant
; Python (embeddable package), la roue sentiment_app, ses dépendances et le modèle.
; =============================================================================

#ifndef AppVersion
  #ifdef MyAppVersion
    #define AppVersion MyAppVersion
  #else
    #define AppVersion "0.1.0"
  #endif
#endif

#define MyAppName "Sentiment App"
#define MyAppPublisher "A. Larhlimi"
#define MyAppExeName "sentiment.cmd"

[Setup]
; Identifiant unique fixe (GUID) : permet aux mises à jour (ex. 1.0.1 sur 1.0.0)
; de remplacer proprement la version précédente au même endroit.
AppId={{8F4E2A91-6C3B-4D87-9A15-7E2B5C0D1F43}
AppName={#MyAppName}
AppVersion={#AppVersion}
AppVerName={#MyAppName} {#AppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Programs\sentiment-app
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
; Installation pour l'utilisateur courant uniquement, sans élévation UAC
PrivilegesRequired=lowest
OutputDir=Output
OutputBaseFilename=sentiment-app-{#AppVersion}-setup
; Compression maximale et architecture 64 bits
Compression=lzma2/ultra
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Notifie l'explorateur Windows de la mise à jour du PATH utilisateur
ChangesEnvironment=yes
UninstallDisplayName={#MyAppName}
WizardStyle=modern

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
; Case cochée par défaut (aucun flag "unchecked")
Name: "addtopath"; Description: "Ajouter le dossier d'installation au PATH de l'utilisateur"; GroupDescription: "Intégration au terminal :"

[Files]
Source: "build\app\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "LISEZMOI.txt"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Analyser un avis"; Filename: "{cmd}"; Parameters: "/k """"{app}\{#MyAppExeName}"" --help"""; WorkingDir: "{app}"; Comment: "Ouvre un terminal et affiche l'aide de la commande sentiment"
Name: "{group}\Désinstaller"; Filename: "{uninstallexe}"; Comment: "Désinstaller {#MyAppName}"

[Code]
const
  CleEnvironnement = 'Environment';

function NormaliserChemin(const Chemin: string): string;
begin
  Result := Lowercase(RemoveBackslashUnlessRoot(Trim(Chemin)));
end;

function ContientEntreePath(const PathActuel, DossierCible: string): Boolean;
var
  Reste, Element, CibleNorm: string;
  PosPointVirgule: Integer;
begin
  Result := False;
  CibleNorm := NormaliserChemin(DossierCible);
  Reste := PathActuel;
  while Length(Reste) > 0 do
  begin
    PosPointVirgule := Pos(';', Reste);
    if PosPointVirgule > 0 then
    begin
      Element := Copy(Reste, 1, PosPointVirgule - 1);
      Delete(Reste, 1, PosPointVirgule);
    end
    else
    begin
      Element := Reste;
      Reste := '';
    end;
    if NormaliserChemin(Element) = CibleNorm then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

procedure AjouterAuPathUtilisateur(const DossierCible: string);
var
  PathActuel, NouveauPath: string;
begin
  if not RegQueryStringValue(HKEY_CURRENT_USER, CleEnvironnement, 'Path', PathActuel) then
    PathActuel := '';

  if ContientEntreePath(PathActuel, DossierCible) then
    Exit;

  if (Length(PathActuel) > 0) and (PathActuel[Length(PathActuel)] <> ';') then
    NouveauPath := PathActuel + ';' + DossierCible
  else
    NouveauPath := PathActuel + DossierCible;

  RegWriteExpandStringValue(HKEY_CURRENT_USER, CleEnvironnement, 'Path', NouveauPath);
end;

procedure RetirerDuPathUtilisateur(const DossierCible: string);
var
  PathActuel, Reste, Element, NouveauPath, CibleNorm: string;
  PosPointVirgule: Integer;
begin
  if not RegQueryStringValue(HKEY_CURRENT_USER, CleEnvironnement, 'Path', PathActuel) then
    Exit;

  CibleNorm := NormaliserChemin(DossierCible);
  NouveauPath := '';
  Reste := PathActuel;

  while Length(Reste) > 0 do
  begin
    PosPointVirgule := Pos(';', Reste);
    if PosPointVirgule > 0 then
    begin
      Element := Copy(Reste, 1, PosPointVirgule - 1);
      Delete(Reste, 1, PosPointVirgule);
    end
    else
    begin
      Element := Reste;
      Reste := '';
    end;

    if (Trim(Element) <> '') and (NormaliserChemin(Element) <> CibleNorm) then
    begin
      if Length(NouveauPath) > 0 then
        NouveauPath := NouveauPath + ';' + Element
      else
        NouveauPath := Element;
    end;
  end;

  RegWriteExpandStringValue(HKEY_CURRENT_USER, CleEnvironnement, 'Path', NouveauPath);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssPostInstall) and WizardIsTaskSelected('addtopath') then
    AjouterAuPathUtilisateur(ExpandConstant('{app}'));
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    RetirerDuPathUtilisateur(ExpandConstant('{app}'));
end;
