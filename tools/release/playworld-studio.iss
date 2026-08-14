#ifndef PackageDir
  #error PackageDir must point at the validated PlayWorld Studio package directory.
#endif
#ifndef OutputDir
  #define OutputDir "."
#endif
#define AppName "PlayWorld Studio"
#define AppVersion "0.2.0"
#define Publisher "PlayWorld Studio"
#define SetupBase "PlayWorld-Studio-0.2.0-Windows-x64-Setup"

[Setup]
AppId={{C169D5CE-4EE4-4D59-93CD-F52D59018010}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#Publisher}
DefaultDirName={autopf}\PlayWorld Studio
DefaultGroupName=PlayWorld Studio
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename={#SetupBase}
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
WizardStyle=modern
UninstallDisplayName=PlayWorld Studio {#AppVersion}
Uninstallable=yes
CloseApplications=yes
RestartApplications=no
VersionInfoVersion=0.2.0.0
VersionInfoProductName=PlayWorld Studio
VersionInfoProductVersion=0.2.0
VersionInfoCompany=PlayWorld Studio
VersionInfoDescription=PlayWorld Studio installer

[Files]
Source: "{#PackageDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\PlayWorld Studio"; Filename: "{app}\PlayWorld Studio.exe"
Name: "{userdesktop}\PlayWorld Studio"; Filename: "{app}\PlayWorld Studio.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[UninstallDelete]
Type: files; Name: "{app}\install_mode.txt"

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    SaveStringToFile(ExpandConstant('{app}\install_mode.txt'), 'installed' + #13#10, False);
end;

[Messages]
FinishedHeadingLabel=PlayWorld Studio 0.2.0 is installed
FinishedLabel=Your worlds, Asset Library catalog, preferences, checkpoints, and recovery data live in your user-data folder and are not removed by update or uninstall.
