# Check for Docker.
$dockerService = Get-Service -Name "com.docker.service" -ErrorAction SilentlyContinue
if (-not $dockerService) {
    Write-Output "Docker isn't installed. Please install Docker Desktop."
    exit 1
}

# Check for Docker Compose.
if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Output "Docker Compose is not installed or not in PATH."
    exit 1
}

# Check for WSL.
if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
    $installWSL = Read-Host "WSL (Windows Subsystem for Linux) isn't installed. Do you want to install WSL? (y/n)"
    if ($installWSL -eq "y") {
        Write-Output "Please wait while WSL is installed."
        wsl --install
        Write-Output "WSL has been installed."
        exit
    } else {
        Write-Output "WSL installation skipped. Note: Docker may default to WSL on Windows."
        exit
    }
}

# Check for WSL 2.
$wslDefaultVersion = wsl --list --verbose | Select-String -Pattern "WSL version:.*" | ForEach-Object { $_.Matches[0].Groups[1].Value -match "\d+"; $matches[0] }
if ($wslDefaultVersion -ne 2) {
    $setWsl2 = Read-Host "Default WSL version isn't set to WSL 2. Do you want to set the default WSL version to WSL 2? (y/n)"
    if ($setWsl2 -eq "y") {
        wsl --set-default-version 2
        Write-Output "Setting the default WSL version to WSL 2."
    } else {
        Write-Output "WSL default version remains unchanged. Note: Docker may require WSL 2 for full compatibility."
        return
    }
} else {
    Write-Output "Default WSL version is already set to WSL 2."
}

# Define default daemon path.
$daemonPath = "$env:USERPROFILE\.docker\daemon.json"

# Check for preexisting daemon configuration.
if (Test-Path -Path $daemonPath) {
    $overwrite = Read-Host "Docker daemon configuration file already exists. Do you want to overwrite it? (y/n)"
    if ($overwrite -ne "y") {
        Write-Output "Skipping daemon update. Note: Docker may require explicit configuration to utilize GPUs."
    } else {
        Move-Item -Path ".\daemon.json" -Destination $daemonPath -Force
        Write-Output "Updated existing Docker daemon configuration file."
        Restart-Docker
    }
} else {
    Move-Item -Path ".\daemon.json" -Destination $daemonPath -Force
    Write-Output "Added new Docker daemon configuration file."
    Restart-Docker
}

# Check for auto-build preference.
$startDockerCompose = Read-Host "Do you want to start the application now with 'docker-compose up --build'? (y/n)"
if ($startDockerCompose -eq "y") {
    Write-Output "Starting Docker Compose. Note: This might take a while."
    docker-compose up --build
} else {
    Write-Output "Setup complete. You can start the application later with 'docker-compose up --build', or build it locally to run later with 'docker-compose build'."
}

# Functions.

# Restarts Docker.
function Restart-Docker {
    if ($dockerService.Status -eq 'Running') {
        Write-Output "Restarting Docker to apply changes."
        Stop-Service -Name "com.docker.service"
        Start-Service -Name "com.docker.service"
        Write-Output "Docker service resumed."
    } else {
        Write-Output "Docker service isn't running."
        exit 1
    }
}
