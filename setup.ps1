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
        $dockerService = Get-Service -Name "com.docker.service" -ErrorAction SilentlyContinue
        if ($dockerService -and $dockerService.Status -eq 'Running') {
            Write-Log -message "Restarting Docker to apply changes."
            Stop-Service -Name "com.docker.service" -Force
            Start-Service -Name "com.docker.service"
            Write-Log -message "Docker service resumed."
        } else {
            throw "Docker service isn't running."
        }
    } catch {
        Write-Log -message $_.Exception.Message -type "ERROR"
        exit 1
    }
}

##### End of Primary Functions. #####

##### Start of Secondary Functions. #####

# Verify PowerShell execution policy.
function Check-ExecutionPolicy {
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
function Check-Administrator {
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
function Check-WindowsVersion {
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
function Check-Docker {
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
function Check-DockerCompose {
    try {
        $dockerComposeVersionOutput = docker-compose --version 2>$null
        if (-not $dockerComposeVersionOutput) {
            throw "Docker Compose is not installed or not in PATH."
        } else {
            $dockerComposeVersion = $dockerComposeVersionOutput -replace 'docker-compose version ([^,]+),.*','$1'
            Write-Log -message "Docker Compose version $dockerComposeVersion found."

            $minDockerComposeVersion = [Version]"1.25.0"
            if ([Version]$dockerComposeVersion -lt $minDockerComposeVersion) {
                throw "Docker Compose version $dockerComposeVersion is below the required version $minDockerComposeVersion. Please update Docker Compose."
            }
        }
    } catch {
        Write-Log -message $_.Exception.Message -type "ERROR"
        exit 1
    }
}

# Ensure correct WSL 2 configuration.
function Configure-WSL {
    try {
        if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
            $installWSL = Get-UserInput "WSL (Windows Subsystem for Linux) isn't installed. Do you want to install WSL? (y/n)"
            if ($installWSL -eq "y") {
                Write-Log -message "Please wait while WSL is installed."
                wsl --install
                Write-Log -message "WSL has been installed."
                $reboot = Get-UserInput "A reboot may be required to complete the WSL installation. Do you want to reboot now? (y/n)"
                if ($reboot -eq "y") {
                    $resumeFile = "$env:USERPROFILE\resume_script.flag"
                    New-Item -Path $resumeFile -ItemType File -Force
                    Restart-Computer
                    exit
                } else {
                    Write-Log -message "Please reboot your computer later to complete the WSL installation."
                    exit
                }
            } else {
                throw "WSL installation skipped. Note: Docker may default to WSL on Windows."
            }
        } else {
            Write-Log -message "WSL is already installed."
            Write-Log -message "Updating WSL to the latest version..."
            wsl --update
        }

        # Ensure default WSL 2.
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

        # Ensure default Ubuntu.
        $distributions = wsl --list --quiet
        if ($distributions.Count -eq 0 -or [string]::IsNullOrEmpty($distributions)) {
            Write-Log -message "No WSL distributions are installed. Installing Ubuntu..."
            wsl --install -d Ubuntu
            Write-Log -message "Ubuntu has been installed."

            Write-Host "Please complete the initial Ubuntu setup in the new window."
            Read-Host "Press Enter when you have completed the Ubuntu setup."
        } else {
            Write-Log -message "WSL distributions installed: $distributions"
            $defaultDistributionLine = (wsl --status | Select-String 'Default Distribution:')
            if ($defaultDistributionLine) {
                $defaultDistribution = $defaultDistributionLine.ToString().Split(':')[1].Trim()
            } else {
                $defaultDistribution = ''
            }

            if (-not $defaultDistribution) {
                $firstDistribution = $distributions[0]
                wsl --set-default $firstDistribution
                Write-Log -message "Default distribution set to $firstDistribution"
                $defaultDistribution = $firstDistribution
            } else {
                Write-Log -message "Default distribution is '$defaultDistribution'."
            }

            # Ensure WSL initialization.
            Write-Log -message "Starting the default distribution to ensure it's initialized."
            Start-Process -FilePath "wsl.exe" -ArgumentList "~" -NoNewWindow -Wait
            Write-Host "If any initial setup is required in the WSL distribution, please complete it now."
            Read-Host "Press Enter when you have completed any setup in the WSL distribution."
        }
    } catch {
        Write-Log -message $_.Exception.Message -type "ERROR"
        exit 1
    }
}

# Ensure correct Docker configuration.
function Configure-Docker {
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
    $startDockerCompose = Get-UserInput "Do you want to start the application now with 'docker-compose up --build'? Note: If your internet speed is slow, select 'n' and build independently. (y/n)"
    if ($startDockerCompose -eq "y") {
        Write-Log -message "Starting Docker Compose. Note: This might take a while."
        try {
            docker-compose up --build
        } catch {
            Write-Log -message "Docker Compose failed to start." -type "ERROR"
        }
    } else {
        Write-Log -message "Setup complete. You can start the application later with 'docker-compose up --build', or build it locally to run later with 'docker-compose build'."
    }
}

##### End of Secondary Functions. #####

##### Start of Primary Script. #####

$resumeFile = "$env:USERPROFILE\resume_script.flag"
if (Test-Path -Path $resumeFile) {
    Remove-Item -Path $resumeFile -Force
    Write-Log -message "Resuming script after reboot."
    Configure-WSL
} else {
    Check-ExecutionPolicy
    Check-Administrator
    Check-WindowsVersion
    Check-Docker
    Check-DockerCompose
    Configure-WSL
    Configure-Docker
    Start-DockerCompose
}

##### End of Primary Script. #####