$ErrorActionPreference = 'Stop'
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

if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
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
    & $ollama.Source create $item[0] -f (Join-Path $dest $item[1])
    if ($LASTEXITCODE -ne 0) { throw "Model creation failed: $($item[0])" }
}

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
& (Join-Path $dest 'workshop.cmd') doctor
if ($LASTEXITCODE -ne 0) { throw 'Workshop doctor check failed.' }

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
