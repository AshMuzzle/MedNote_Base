# Ensure PWD and define logging.
$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Set-Location -Path $scriptDirectory
$logFile = Join-Path -Path $scriptDirectory -ChildPath "app\source\logs\ps-log.txt"

##### Start of Primary Functions. #####

# Prompt user for input.
function Get-UserInput {
    param(
        [string]$message
    )
    while ($true) {
        $response = Read-Host $message
        if ($response -match '^[YyNn]$') {
            return $response.ToLower()
        } else {
            Write-Log -message "Invalid input. Please enter 'y' or 'n'." -type "WARNING"
        }
    }
}

# Initialize logging.
function Write-Log {
    param(
        [string]$message,
        [string]$type = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp [$type] $message"

    # Verify log directory.
    $logDirectory = Split-Path -Path $logFile -Parent
    if (-not (Test-Path -Path $logDirectory)) {
        New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
    }

    Write-Output $entry
    Add-Content -Path $logFile -Value $entry
}

# Restart Docker service.
function Restart-Docker {
    try {
        # TODO: Set dynamic installation path.
        # Default Docker installation path.
        $dockerDesktopPath = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"

        # Check for Docker's status.
        $dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
        if ($dockerProcess) {
            Write-Log -message "Restarting Docker Desktop to apply changes."
            Stop-Process -Id $dockerProcess.Id -Force
            Start-Process -FilePath $dockerDesktopPath -NoNewWindow
            Write-Log -message "Docker Desktop has been restarted."
        } else {
            Write-Log -message "Docker Desktop is not running. Starting Docker Desktop."
            Start-Process -FilePath $dockerDesktopPath -NoNewWindow
            Write-Log -message "Docker Desktop has been started."
        }

        # Wait for Docker's startup.
        $maxAttempts = 15
        $attempt = 0
        while ($attempt -lt $maxAttempts) {
            $attempt++
            try {
                docker info >$null 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Log -message "Docker Desktop is now ready."
                    break
                }
            } catch {
                # Continue.
            }
            Start-Sleep -Seconds 2
        }
        if ($attempt -eq $maxAttempts) {
            Write-Log -message "Docker Desktop didn't become ready in time." -type "ERROR"
            exit 1
        }
    } catch {
        Write-Log -message $_.Exception.Message -type "ERROR"
        exit 1
    }
}


##### End of Primary Functions. #####

##### Start of Secondary Functions. #####

# Verify PowerShell execution policy.
function Test-ExecutionPolicy {
    try {
        $currentPolicy = Get-ExecutionPolicy -Scope Process
        $acceptablePolicies = @('RemoteSigned', 'Unrestricted', 'Bypass')
        if ($acceptablePolicies -notcontains $currentPolicy) {
            $changePolicy = Get-UserInput "Your current execution policy is '$currentPolicy', which prevents this script from working properly. Do you want to temporarily change the execution policy? (y/n)"
            if ($changePolicy -eq "y") {
                Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
                Write-Log -message "Execution policy changed to 'Bypass' temporarily."
            } else {
                Write-Log -message "Execution policy remains '$currentPolicy'." -type "WARNING"
                exit 1
            }
        } else {
            Write-Log -message "Execution policy is '$currentPolicy', which is acceptable."
        }
    } catch {
        Write-Log -message "Failed to check or set execution policy: $($_.Exception.Message)" -type "ERROR"
        exit 1
    }
}

# Verify Administrator privileges.
function Test-Administrator {
    try {
        if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw "This script must be run as an administrator."
        } else {
            Write-Log -message "Administrator privileges confirmed."
        }
    } catch {
        Write-Log -message $_.Exception.Message -type "ERROR"
        exit 1
    }
}

# Verify Windows version.
function Test-WindowsVersion {
    try {
        $buildNumber = [Environment]::OSVersion.Version.Build
        $minBuildNumber = 19041 # Windows 10 version 2004 or higher
        if ($buildNumber -lt $minBuildNumber) {
            throw "Your Windows build number ($buildNumber) does not support WSL 2."
        } else {
            Write-Log -message "Windows build number $buildNumber supports WSL 2."
        }
    } catch {
        Write-Log -message $_.Exception.Message -type "ERROR"
        exit 1
    }
}

# Verify Docker installation.
function Test-Docker {
    try {
        $dockerVersionOutput = docker --version 2>$null
        if (-not $dockerVersionOutput) {
            throw "Docker isn't installed. Please install Docker Desktop."
        } else {
            $dockerVersion = $dockerVersionOutput -replace 'Docker version ([^,]+),.*','$1'
            Write-Log -message "Docker version $dockerVersion found."
            
            $minDockerVersion = [Version]"19.03.0"
            if ([Version]$dockerVersion -lt $minDockerVersion) {
                throw "Docker version $dockerVersion is below the required version $minDockerVersion. Please update Docker."
            }
        }
    } catch {
        Write-Log -message $_.Exception.Message -type "ERROR"
        exit 1
    }
}

# Verify Docker Compose installation.
function Test-DockerCompose {
    try {
        $dockerComposeVersionOutput = docker-compose --version 2>$null
        if (-not $dockerComposeVersionOutput) {
            throw "Docker Compose is not installed or not in PATH."
        } else {
            # Extract the version number using regex
            if ($dockerComposeVersionOutput -match 'version\s+v?([\d\.]+)') {
                $versionNumber = $Matches[1]
                Write-Log -message "Docker Compose version $versionNumber found." -includeStep $true
            } else {
                throw "Unable to parse Docker Compose version from output: $dockerComposeVersionOutput"
            }

            $minDockerComposeVersion = [Version]"1.25.0"
            if ([Version]$versionNumber -lt $minDockerComposeVersion) {
                throw "Docker Compose version $versionNumber is below the required version $minDockerComposeVersion. Please update Docker Compose."
            }
        }
    } catch {
        Write-Log -message $_.Exception.Message -type "ERROR" -includeStep $true
        exit 1
    }
}

# Ensure correct WSL configuration.
function Set-WSL {
    try {
        # Check for WSL.
        if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
            Write-Log -message "WSL is not installed. Installing WSL..."
            wsl --install
            Write-Log -message "WSL has been installed. A reboot may be required."
        } else {
            Write-Log -message "WSL is already installed."
            Write-Log -message "Updating WSL to the latest version..."
            wsl --update
        }

        # Check default WSL version.
        $wslStatus = wsl --status 2>$null
        if ($wslStatus) {
            $defaultVersionLine = $wslStatus | Select-String 'Default Version:'
            if ($defaultVersionLine) {
                $defaultVersion = $defaultVersionLine.ToString().Split(':')[1].Trim()
                if ($defaultVersion -ne '2') {
                    $setWsl2 = Get-UserInput "Default WSL version isn't set to WSL 2. Do you want to set the default WSL version to WSL 2? (y/n)"
                    if ($setWsl2 -eq "y") {
                        wsl --set-default-version 2
                        Write-Log -message "Set the default WSL version to WSL 2."
                    } else {
                        throw "WSL default version remains unchanged. Note: Docker may require WSL 2 for full compatibility."
                    }
                } else {
                    Write-Log -message "Default WSL version is already set to WSL 2."
                }
            } else {
                Write-Log -message "Unable to determine default WSL version."
            }
        } else {
            Write-Log -message "Unable to get WSL status."
        }

        # Check for Ubuntu.
        $distributions = wsl --list --quiet | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
        $ubuntuInstalled = $distributions -contains 'Ubuntu'

        if (-not $ubuntuInstalled) {
            Write-Log -message "Ubuntu is not installed."
            $installUbuntu = Get-UserInput "Ubuntu is not installed. Do you want to install Ubuntu? (y/n)"
            if ($installUbuntu -eq "y") {
                Write-Host "Please complete the initial Ubuntu setup in the new shell, then type 'exit'."
                Write-Log -message "Installing Ubuntu..."
                wsl --install -d Ubuntu
                Write-Log -message "Ubuntu has been installed."
                Read-Host "Press Enter when you have completed the Ubuntu setup."
            } else {
                Write-Log -message "Ubuntu installation skipped. Exiting." -type "ERROR"
                exit 1
            }
        } else {
            Write-Log -message "Ubuntu is already installed."
        }

        # Check default WSL distribution.
        Write-Log -message "Setting 'Ubuntu' as the default distribution."
        $setDefaultResult = wsl --set-default Ubuntu 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Log -message "Failed to set 'Ubuntu' as default distribution: $setDefaultResult" -type "ERROR"
            throw "Failed to set 'Ubuntu' as default distribution."
        } else {
            Write-Log -message "'Ubuntu' has been set as the default distribution."
        }

        # Verify Ubuntu installation.
        Write-Log -message "Starting 'Ubuntu' to ensure it's initialized."
        Write-Log -message "If any initial setup is required in Ubuntu, please complete it now."
        Start-Process -FilePath "wsl.exe" -ArgumentList "-d", "Ubuntu", "exit" -NoNewWindow -Wait
    } catch {
        Write-Log -message $_.Exception.Message -type "ERROR"
        exit 1
    }
}

# Ensure correct Docker configuration.
function Set-Docker {
    try {
        $daemonPath = "$env:USERPROFILE\.docker\daemon.json"

        # Check for existing configuration.
        if (Test-Path -Path $daemonPath) {
            $overwrite = Get-UserInput "Docker daemon configuration file already exists. Do you want to overwrite it? (y/n)"
            if ($overwrite -ne "y") {
                Write-Log -message "Skipping daemon update. Note: Docker may require explicit configuration to utilize GPUs."
            } else {
                Copy-Item -Path ".\daemon.json" -Destination $daemonPath -Force
                Write-Log -message "Updated existing Docker daemon configuration file."
                Restart-Docker
            }
        } else {
            Copy-Item -Path ".\daemon.json" -Destination $daemonPath -Force
            Write-Log -message "Added new Docker daemon configuration file."
            Restart-Docker
        }
    } catch {
        Write-Log -message $_.Exception.Message -type "ERROR"
        exit 1
    }
}

# Prompt user for Docker Compose.
function Start-DockerCompose {
    $startDockerCompose = Get-UserInput "Do you want to start the application now with 'docker-compose up --build'? Note: If your internet speed is slow, select 'n' and build it independently before starting. (y/n)"
    if ($startDockerCompose -eq "y") {
        Write-Log -message "Starting Docker Compose. Note: This might take a while."
        try {
            docker-compose up --build
        } catch {
            Write-Log -message "Docker Compose failed to start." -type "ERROR"
        }
    } else {
        Write-Log -message "Setup complete."
        Write-Host "For future reference, your options are:You can rebuild and start the application later with 'docker-compose up --build', or just build it locally to start later with 'docker-compose build'."
    }
}

##### End of Secondary Functions. #####

##### Start of Primary Script. #####

$resumeFile = "$env:USERPROFILE\resume_script.flag"
if (Test-Path -Path $resumeFile) {
    Remove-Item -Path $resumeFile -Force
    Write-Log -message "Resuming script after reboot."
    Set-WSL
} else {
    Test-ExecutionPolicy
    Test-Administrator
    Test-WindowsVersion
    Test-Docker
    Test-DockerCompose
    Set-WSL
    Set-Docker
    Start-DockerCompose
}

##### End of Primary Script. #####