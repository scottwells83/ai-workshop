$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$stage = Join-Path $env:TEMP 'ai-workshop-windows-stage'
$output = Join-Path $root 'dist\windows'

$python = Get-Command py -ErrorAction SilentlyContinue
if ($python) { & py -3 (Join-Path $PSScriptRoot 'stage.py') $stage }
else {
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) { throw 'Python 3 is required to build the installer.' }
    & python (Join-Path $PSScriptRoot 'stage.py') $stage
}
if ($LASTEXITCODE -ne 0) { throw 'Payload staging failed.' }

$iscc = Get-Command ISCC.exe -ErrorAction SilentlyContinue
if (-not $iscc) {
    $candidate = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'
    if (Test-Path $candidate) { $iscc = @{ Source = $candidate } }
}
if (-not $iscc) { throw 'Inno Setup 6 command-line compiler (ISCC.exe) is required.' }
New-Item -ItemType Directory -Path $output -Force | Out-Null
$env:AI_WORKSHOP_STAGE = $stage
& $iscc.Source "/O$output" (Join-Path $PSScriptRoot 'AIWorkshop.iss')
if ($LASTEXITCODE -ne 0) { throw 'Inno Setup compilation failed.' }
Write-Host (Join-Path $output 'AI-Workshop-Windows-Setup.exe')
