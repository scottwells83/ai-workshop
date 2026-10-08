#define SourcePath GetEnv("AI_WORKSHOP_STAGE")
#if SourcePath == ""
  #error AI_WORKSHOP_STAGE must point to the staged public payload.
#endif

[Setup]
AppId={{B5D0A949-4BC7-4B57-B651-EF7B6A965DA1}
AppName=AI Workshop
AppVersion=1.0
AppPublisher=AI Workshop
DefaultDirName={%USERPROFILE}\ai-workshop
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputBaseFilename=AI-Workshop-Windows-Setup
Compression=lzma2
SolidCompression=yes
Uninstallable=no
CreateUninstallRegKey=no
WizardStyle=modern

[Files]
Source: "{#SourcePath}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs onlyifdoesntexist

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
  SetupScript: String;
begin
  if CurStep = ssPostInstall then
  begin
    SetupScript := ExpandConstant('{app}\install-windows.ps1');
    if not Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
      '-NoProfile -ExecutionPolicy Bypass -File "' + SetupScript + '"',
      '', SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode) then
      RaiseException('Could not launch AI Workshop dependency setup.');
    if ResultCode <> 0 then
      RaiseException('AI Workshop dependency setup failed with exit code ' + IntToStr(ResultCode) + '. Rerun Install AI Workshop.cmd after resolving the reported error.');
  end;
end;
