$ErrorActionPreference = 'Stop'
$stage = 'initializing'
$logDir = Join-Path $env:LOCALAPPDATA 'AI Workshop'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$logPath = Join-Path $logDir 'setup.log'
try { Start-Transcript -Path $logPath -Append -ErrorAction Stop | Out-Null }
catch { Write-Warning "Could not start setup transcript: $_" }
try {
$source = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest = Join-Path $env:USERPROFILE 'ai-workshop'
Write-Host 'AI Workshop — a local-first workspace for AI-assisted projects (Windows setup)'

if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Path $dest | Out-Null
    Copy-Item -Path (Join-Path $source '*') -Destination $dest -Recurse -Force
    Write-Host "Copied workshop to $dest"
} elseif ([IO.Path]::GetFullPath($source).TrimEnd('\') -ne [IO.Path]::GetFullPath($dest).TrimEnd('\')) {
    Write-Host "Existing workshop preserved at $dest. Using it without overwriting files."
}

$codexDir = Join-Path $env:USERPROFILE '.codex'
$codexInstructions = Join-Path $codexDir 'AGENTS.md'
if (-not (Test-Path $codexInstructions)) {
    New-Item -ItemType Directory -Path $codexDir -Force | Out-Null
    Copy-Item (Join-Path $dest 'universal-custom-instructions.md') $codexInstructions
    Write-Host 'Added the short Codex entry instructions.'
}

$opencodeInstructions = Join-Path $env:USERPROFILE '.config\opencode\AGENTS.md'
if (-not (Test-Path $opencodeInstructions)) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $opencodeInstructions) -Force | Out-Null
    Copy-Item (Join-Path $dest 'universal-custom-instructions.md') $opencodeInstructions
    Write-Host 'Added OpenCode user instructions.'
}
$copilotInstructions = Join-Path $env:USERPROFILE '.copilot\copilot-instructions.md'
if (-not (Test-Path $copilotInstructions)) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $copilotInstructions) -Force | Out-Null
    Copy-Item (Join-Path $dest 'universal-custom-instructions.md') $copilotInstructions
    Write-Host 'Added GitHub Copilot CLI user instructions.'
}

$stage = 'checking bundled Ollama'
if (-not (Test-Path (Join-Path $dest 'runtime\ollama\entrypoint.txt'))) {
    throw 'This package is missing its bundled Ollama helper.'
}

$stage = 'installing Python runtime'
$validPython = $false
if (Get-Command py -ErrorAction SilentlyContinue) {
    & py -3 -c 'import sys; assert sys.version_info >= (3, 11)' *> $null
    $validPython = ($LASTEXITCODE -eq 0)
}
if (-not $validPython -and (Get-Command python -ErrorAction SilentlyContinue)) {
    & python -c 'import sys; assert sys.version_info >= (3, 11)' *> $null
    $validPython = ($LASTEXITCODE -eq 0)
}
$uvExe = Join-Path $env:USERPROFILE '.local\bin\uv.exe'
if (-not $validPython -and -not (Test-Path $uvExe)) {
    Write-Host 'Installing the uv Python runtime from its official installer...'
    $uvInstall = Join-Path $env:TEMP 'ai-workshop-uv-install.ps1'
    Invoke-WebRequest -Uri 'https://astral.sh/uv/install.ps1' -OutFile $uvInstall
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $uvInstall
    if ($LASTEXITCODE -ne 0) { throw 'Python runtime installation failed.' }
}
if (-not $validPython -and -not (Test-Path $uvExe)) {
    throw 'Python 3.11+ or uv is required, but the uv runtime was not found after installation.'
}
if (-not $validPython) {
    Write-Host 'Installing Python 3.11 through uv...'
    & $uvExe python install 3.11
    if ($LASTEXITCODE -ne 0) { throw 'Python 3.11 installation failed.' }
}
$stage = 'setting up optional desktop window'
$webView2Id = '{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
$webView2Keys = @(
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\$webView2Id",
    "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\$webView2Id",
    "HKCU:\Software\Microsoft\EdgeUpdate\Clients\$webView2Id"
)
$webView2Found = $false
foreach ($key in $webView2Keys) {
    $version = (Get-ItemProperty -Path $key -Name pv -ErrorAction SilentlyContinue).pv
    if ($version -and $version -ne '0.0.0.0') { $webView2Found = $true; break }
}
try {
    if (-not $webView2Found) {
        Write-Host 'Installing Microsoft WebView2 Runtime for the desktop window...'
        $webView2Setup = Join-Path $env:TEMP 'MicrosoftEdgeWebView2Setup.exe'
        Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/p/?linkid=2124703' -OutFile $webView2Setup
        $process = Start-Process -FilePath $webView2Setup -ArgumentList '/silent', '/install' -Wait -PassThru
        if ($process.ExitCode -ne 0) { throw "WebView2 Runtime setup failed with exit code $($process.ExitCode)." }
    }
    & (Join-Path $dest 'workshop.cmd') desktop-setup
    if ($LASTEXITCODE -ne 0) { throw 'Desktop window dependency setup failed.' }
} catch {
    Write-Warning "Desktop window setup could not complete: $_. The launcher can use the browser fallback."
}

Write-Host "Workshop ready at $dest. Open AI Workshop to prepare local models."
} catch {
    $message = "AI Workshop setup failed during $stage`: $($_.Exception.Message)"
    Write-Error $message -ErrorAction Continue
    Write-Host "Setup log: $logPath"
    exit 1
} finally {
    try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch {}
}
