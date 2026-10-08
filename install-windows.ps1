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

$stage = 'installing Ollama'
$ollama = Get-Command ollama -ErrorAction SilentlyContinue
if (-not $ollama) {
    $candidate = Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama.exe'
    if (Test-Path $candidate) { $ollama = @{ Source = $candidate } }
}
if (-not $ollama) {
    Write-Host 'Installing Ollama from its official installer...'
    $script = Join-Path $env:TEMP 'ai-workshop-ollama-install.ps1'
    Invoke-WebRequest -Uri 'https://ollama.com/install.ps1' -OutFile $script
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script
    if ($LASTEXITCODE -ne 0) { throw 'Ollama installer failed.' }
}
$ollama = Get-Command ollama -ErrorAction SilentlyContinue
if (-not $ollama) {
    $candidate = Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama.exe'
    if (Test-Path $candidate) { $ollama = @{ Source = $candidate } }
}
if (-not $ollama) { throw 'Ollama command unavailable after installation.' }

$ram = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
if ($ram -ge 25769803776) {
    [Environment]::SetEnvironmentVariable('OLLAMA_NUM_PARALLEL', '2', 'User')
    $env:OLLAMA_NUM_PARALLEL = '2'
    Write-Host 'Configured up to two Ollama requests per model after Ollama restarts.'
}

try { Start-Process -FilePath $ollama.Source -ArgumentList 'serve' -WindowStyle Hidden -ErrorAction SilentlyContinue | Out-Null } catch {}
for ($i = 0; $i -lt 30; $i++) {
    try {
        Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 2 | Out-Null
        break
    } catch { Start-Sleep -Seconds 2 }
}
try { Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 2 | Out-Null }
catch { throw 'Ollama did not start. Start the Ollama app and rerun this installer.' }

function Test-OllamaBaseModel([string]$name) {
    $output = Join-Path $env:TEMP "ai-workshop-ollama-show-$PID.out"
    $errors = Join-Path $env:TEMP "ai-workshop-ollama-show-$PID.err"
    try {
        $process = Start-Process -FilePath $ollama.Source -ArgumentList @('show', $name, '--modelfile') `
            -Wait -PassThru -NoNewWindow -RedirectStandardOutput $output -RedirectStandardError $errors
        if ($process.ExitCode -eq 0) { return $true }
        if (Test-Path $errors) { Get-Content $errors | ForEach-Object { Write-Host $_ } }
        return $false
    } finally {
        Remove-Item $output, $errors -Force -ErrorAction SilentlyContinue
    }
}

$baseModels = @('llama3.2:3b', 'llama3.1:8b')
foreach ($base in $baseModels) {
    $stage = "checking Ollama base model $base"
    if (-not (Test-OllamaBaseModel $base)) {
        Write-Host "Base model $base is missing or incomplete. Downloading its required layers..."
        $stage = "repairing Ollama base model $base"
        & $ollama.Source pull $base
        if ($LASTEXITCODE -ne 0) { throw "Could not download base model $base. Check network access and free disk space." }
        if (-not (Test-OllamaBaseModel $base)) { throw "Base model $base is still unreadable after download. Preserve the Ollama model files and share the setup log for diagnosis." }
    }
}

$stage = 'creating required Ollama models'
$models = @(
    @('local-worker', 'Modelfile'),
    @('local-drafter', 'Modelfile.drafter'),
    @('chief-of-staff', 'agents\Modelfile.chief-of-staff'),
    @('watcher', 'agents\Modelfile.watcher'),
    @('sweeper', 'agents\Modelfile.sweeper'),
    @('archivist', 'agents\Modelfile.archivist'),
    @('usage-analyst', 'agents\Modelfile.usage-analyst')
)
foreach ($item in $models) {
    $stage = "creating Ollama model $($item[0])"
    & $ollama.Source create $item[0] -f (Join-Path $dest $item[1])
    if ($LASTEXITCODE -ne 0) { throw "Model creation failed: $($item[0])" }
}
$installedNames = @((Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 5).models | ForEach-Object { $_.name })
if (($installedNames -contains 'qwen3:32b') -and (Test-OllamaBaseModel 'qwen3:32b')) {
    & $ollama.Source create local-reviewer -f (Join-Path $dest 'agents\Modelfile.reviewer')
    if ($LASTEXITCODE -ne 0) { Write-Warning 'Optional local-reviewer model creation failed; required models remain available.' }
} else {
    Write-Host 'Skipping optional local-reviewer because qwen3:32b is absent or unreadable.'
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
$stage = 'running Workshop doctor'
& (Join-Path $dest 'workshop.cmd') doctor
if ($LASTEXITCODE -ne 0) { throw 'Workshop doctor check failed.' }

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

$stage = 'setting up optional Open WebUI'
$env:PATH = "$env:ProgramFiles\Docker\Docker\resources\bin;$env:PATH"
$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Host 'Installing Docker Desktop to host Open WebUI...'
        & winget install --id Docker.DockerDesktop --exact
        if ($LASTEXITCODE -ne 0) { Write-Warning 'Docker Desktop installation needs attention.' }
        $env:PATH = "$env:ProgramFiles\Docker\Docker\resources\bin;$env:PATH"
        $docker = Get-Command docker -ErrorAction SilentlyContinue
    }
}
if ($docker) {
    $dockerApp = Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'
    if (Test-Path $dockerApp) { Start-Process -FilePath $dockerApp -ErrorAction SilentlyContinue | Out-Null }
    for ($i = 0; $i -lt 30; $i++) {
        & docker info *> $null
        if ($LASTEXITCODE -eq 0) { break }
        Start-Sleep -Seconds 2
    }
    & docker info *> $null
    if ($LASTEXITCODE -eq 0) {
        & docker container inspect ai-workshop-webui *> $null
        $own = ($LASTEXITCODE -eq 0)
        & docker container inspect open-webui *> $null
        $existing = ($LASTEXITCODE -eq 0)
        if ($own) {
            & docker start ai-workshop-webui *> $null
            if ($LASTEXITCODE -ne 0) { Write-Warning 'Could not start the existing ai-workshop-webui container.' }
        } elseif ($existing) {
            & docker start open-webui *> $null
            if ($LASTEXITCODE -ne 0) { Write-Warning 'Could not start the existing open-webui container.' }
        } else {
            & docker run -d --name ai-workshop-webui --restart unless-stopped `
                -p '127.0.0.1:3000:8080' `
                -e 'OLLAMA_BASE_URL=http://host.docker.internal:11434' `
                -v 'ai-workshop-webui:/app/backend/data' `
                'ghcr.io/open-webui/open-webui:main'
            if ($LASTEXITCODE -ne 0) { Write-Warning 'Open WebUI setup needs attention.' }
        }
        Write-Host 'Open WebUI: check http://localhost:3000 after startup.'
    } else { Write-Warning 'Start Docker Desktop, accept its terms, and rerun setup for Open WebUI.' }
} else { Write-Warning 'Open WebUI is optional for the runner. Install Docker Desktop from docker.com and rerun setup to add it.' }
Write-Host "Workshop ready at $dest"
} catch {
    $message = "AI Workshop setup failed during $stage`: $($_.Exception.Message)"
    Write-Error $message -ErrorAction Continue
    Write-Host "Setup log: $logPath"
    exit 1
} finally {
    try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch {}
}
