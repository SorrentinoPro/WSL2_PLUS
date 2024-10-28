#--------------------------------
# Run scripts in order
function RunSequentialScripts {
    try {
        #--------------------------------
        if (-not (Test-Admin)) { RestartAsAdmin }
        #--------------------------------
        Write-Output " _ _ _  ___  _         ___  _    _ _  ___ "
        Write-Output "| | | |/ __>| |       | . \| |  | | |/ __>"
        Write-Output "| | | |\__ \| |_  ___ |  _/| |_ | ' |\__ \"
        Write-Output "|__/_/ <___/|___||___||_|  |___ |___'<___/"
        Write-Output "__________________________________________________"
        Write-Output "=====\ by Francesco Sorrentino /=================="
        Write-Output "=====\ https://Sorrentino.pro /==================="
        # Write-Output "Admin: $(Test-Admin) | location: $(Get-Location)"
        Write-Output "__________________________________________________"
        Write-Output " "
        #--------------------------------
        # Globals variables
        $wslPath = "$env:SystemRoot\System32\wsl.exe"
        $basePath = "C:\WSL"
        $exportPath = "$basePath\Exports"
        $instancesPath = "$basePath\Instances"
        #--------------------------------
        WSLCheck
        StablizePaths
        Main

        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Write-Error "ERROR: $_"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit
    }
}

#--------------------------------
# Function to check if the script is running as Administrator
function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function RestartAsAdmin {
    $scriptPath = $PSCommandPath
    if ($scriptPath) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs -WindowStyle Normal
        [System.Environment]::Exit(0)
    }
    else {
        Write-Host "Unable to determine script path. Please run the script from a file."
    }
}

#--------------------------------
# Check internet connection
function NetStatus {
    param(
        [bool]$called = $false
    )
    
    $InternetConnection = ping -n 1 -w 1000 www.microsoft.com >$null
    if ($LASTEXITCODE -ne 0) {
        if (!$called) {
            return $false
        }
    }
    else {
        # Write-Host "Internet connection stable."
        return $true
    }
}

#--------------------------------
# Persist Check to internet connection
function PersistNetStatus {
    param(
        [bool]$called = $false
    )
    
    if (NetStatus) {
        Write-Host "Internet connection stable. Gathering information from the network..."
    }
    else {
        if (!$called) {
            Write-Output "No internet connection detected."
            Write-Output "You need internet to grab the latest (selected option) information."
            Write-Output "Press ( CTRL+C ) to exit or wait until  internet connection is detected to continue."
        }
        Start-Sleep -Seconds 2
        CheckInternetConnection -called $true
    }
    
}

#--------------------------------
# check if wsl is installed and if not, install it
function WSLCheck {
    if (-not (Test-Path $wslPath)) {
        Write-Warning "WSL not installed. Installing WSL..."

        # Download WSL installer from Microsoft
        $wslInstallerUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
        $wslInstallerPath = "$env:TEMP\wsl_update_x64.msi"
        Invoke-WebRequest -Uri $wslInstallerUrl -OutFile $wslInstallerPath

        # Install WSL
        Start-Process msiexec.exe -Wait -ArgumentList "/I $wslInstallerPath /quiet"

        # Enable WSL feature
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

        # Enable Virtual Machine Platform
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

        # Set WSL 2 as default
        wsl --set-default-version 2

        # Clean up installer
        Remove-Item $wslInstallerPath

        Write-Output "WSL installation completed. Please restart your computer to finish the setup."
    }  
    else {
        Write-Output "WSL already installed."
    }
}

#--------------------------------
# Show Info installed distos
function ShowInfo {
    $distributions = ListInstalledWSLDistros
    Write-Host "Installed Distros Info:"
    for ($i = 0; $i -lt $distributions.Count; $i++) {
        $distroPath = GetWSLDistroPath -DistroName $distributions[$i]
        $distroPath = $distroPath.Replace("\\?\", "")
        Write-Output "$($i + 1)_)--------------------------------------"
        Write-Output "Name: $($distributions[$i])"
        Write-Output "Location: $distroPath"
        
    }
}

#--------------------------------
# Check if the folders exist, if not, create them
function StablizePaths {
    if (-not (Test-Path $exportPath)) {
        Write-Output "Attempting to create directory: $exportPath"
        [System.IO.Directory]::CreateDirectory($exportPath)
        Write-Output "Successfully created directory: $exportPath"
    }
    if (-not (Test-Path $instancesPath)) {
        Write-Output "Attempting to create directory: $instancesPath"
        [System.IO.Directory]::CreateDirectory($instancesPath)
        Write-Output "Successfully created directory: $instancesPath"
    }
}

#--------------------------------
# Function to list installed WSL distributions
function ListInstalledWSLDistros {
    try {
        $output = & $wslPath -l -v
        $distributions = $output | 
        Select-Object -Skip 1 | 
        Where-Object { $_ -ne "" } | 
        ForEach-Object { 
            $line = $_.Trim().Replace("*", "") 
            $trim = $line.Substring(1).Trim()
            $split = $trim.Substring(1).Trim()
            $name = $split.Split(" ", 3)[0]
            $name 
        }
        return $distributions
    }
    catch {
        Write-Error "An error occurred while listing WSL distributions: $_"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit
    }
}

#--------------------------------
# Function to get and select an installed WSL distributions
function GetFromInstalledWSLDistros {
    try {
        $distributions = ListInstalledWSLDistros
        Write-Host "Choose Distribution:"
        for ($i = 0; $i -lt $distributions.Count; $i++) {
            Write-Host "$($i + 1).$($distributions[$i])"
        }
        Write-Host " "
        
        $selection = Read-Host "Enter the number of the distribution you want to Manage"
        $index = [int]$selection - 1
        
        if ($index -ge 0 -and $index -lt $distributions.Count) {
            return $distributions[$index]
        }
        else {
            Write-Error "Invalid selection. Please run the script again and choose a valid option."
            exit
        }
    }
    catch {
        Write-Error "An error occurred while listing WSL distributions: $_"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit
    }
}

#--------------------------------
# Function to list and select all available WSL distributions
function ListAllWSLDistros {
    try {
        PersistNetStatus
        $output = & $wslPath -l -o
        $distributions = $output | 
        Select-Object -Skip 3 | 
        Where-Object { $_ -ne "NAME" -and $_ -ne "" } | 
        ForEach-Object { 
            $split = $_.Substring(1).Trim()
            $name = $split.Split(" ", 2)[0]
            $name 
        }
        $distributions = $distributions | Select-Object -Skip 1

        Write-Host "Installed Distributions:"
        for ($i = 0; $i -lt $distributions.Count; $i++) {
            Write-Host "$($i + 1).$($distributions[$i])"
        }
        Write-Host " "
        return $distributions 
    }
    catch {
        Write-Error "An error occurred while listing WSL distributions: $_"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit
    }
}

#--------------------------------
# Function to get and select an available WSL distribution
function GetFromAllWSLDistros {
    try {
        $distributions = ListAllWSLDistros
        $selection = Read-Host "Enter the number of the distribution you want to install"
        $index = [int]$selection - 1
        
        if ($index -ge 0 -and $index -lt $distributions.Count) {
            return $distributions[$index]
        }
        else {
            Write-Error "Invalid selection. Please run the script again and choose a valid option."
            exit
        }

    }
    catch {
        Write-Error "An error occurred while listing WSL distributions: $_"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit
    }
}

#--------------------------------
# Function to get distribution path
function GetWSLDistroPath {
    param (
        [string]$DistroName
    )
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss"
    $distros = Get-ChildItem -Path $registryPath

    foreach ($distro in $distros) {
        $distroInfo = Get-ItemProperty -Path $distro.PSPath
        if ($distroInfo.DistributionName -eq $DistroName) {
            return $distroInfo.BasePath
        }
    }
    return $null
}

#--------------------------------
# Custom Distron Name Function
function SetCustomDistroName {
    $distroFileTar = Join-Path -Path $exportPath -ChildPath "$selectedDistro.tar"
    Write-Output "Distro file: [$distroFileTar]"
    if (-not (Test-Path $distroFileTar)) {
        Write-Output "[$selectedDistro.tar] in ($exportPath) does not exists."
        Write-Output "Exporting copy $selectedDistro ..."
        # Execute the wsl export command and wait for it to complete
        Start-Process -FilePath $wslPath -ArgumentList "--export", "$selectedDistro", "$distroFileTar" -NoNewWindow -Wait
        Write-Output "Exported!"
    }
    else {
        Write-warning "[$selectedDistro.tar] in ($exportPath) already exists."
    }

    
    $instancePath = Join-Path -Path $instancesPath -ChildPath $selectedDistro
    Write-Output "Instance path: [$instancePath]"
    if (-not (Test-Path $instancePath)) {
        Write-Output "Attempting to create directory: $instancePath"
        [System.IO.Directory]::CreateDirectory($instancePath)
        Write-Output "Successfully created directory: $instancePath"
    }

    $customName = Read-Host "Enter a custom name for your WSL instance"
    $customDistroPath = Join-Path -Path $instancePath -ChildPath $customName
    
    if (-not (Test-Path $customDistroPath)) {
        Start-Process -FilePath $wslPath -ArgumentList "--import", "$customName", "$customDistroPath", "$distroFileTar" -NoNewWindow -Wait
        Write-Output "Installed! Setting root-only login ..."
        Start-Process -FilePath $wslPath -ArgumentList "-d", $customName, "-u", "root", "passwd", "-d", "root" -NoNewWindow -Wait
        Write-Output "Root-only login set!"
        Write-Output "WSL instance '$customName' has been created successfully."
        Write-Output "You can start it using: wsl -d $customName"
        Write-Output "PRESS any KEY to exit! ;)"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    else {
        Write-Output "WSL instance '$customName' already exists."
        SetCustomDistroName
    }
}

#--------------------------------
# CHECK_SET_FIX_AUDIO_GUI
function  CHECK_SET_FIX_AUDIO_GUI {
    # Check if Chocolatey is installed
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey is not installed. Installing Chocolatey now..."

        # Set execution policy to allow script execution
        Set-ExecutionPolicy Bypass -Scope Process -Force

        # Download and install Chocolatey
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

        Write-Host "Chocolatey has been installed successfully."
    }

    # Install dependencies
    $packages = @("pulseaudio", "vcxsrv")

    foreach ($package in $packages) {
        if (-not (choco list --local-only | Select-String $package)) {
            Write-Host "$package is not installed. Installing..."
            choco install $package -y
        }
        else {
            Write-Host "$package is already installed."
        }
    }

    # Define paths
    $PATools = "C:\ProgramData\chocolatey\lib\pulseaudio\tools"
    # pulse config
    $PAConfigDir = "$PATools\etc\pulse"
    # bin
    $PABin = "$PATools\bin"

    # executable
    $PAexe = "$PABin\pulseaudio.exe"
    $VCexe = "C:\Program Files\VcXsrv\vcxsrv.exe"

    #--------------------------------------------------------------
    # Config.pa file
    $PAconfig_Pa = "$PAConfigDir\default.pa"
    $PAconfig_PaContent = @"
# Windows WSL2 Configuration
load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1;172.16.0.0/12
load-module module-esound-protocol-tcp auth-ip-acl=127.0.0.1;172.16.0.0/12
load-module module-waveout sink_name=output source_name=input record=0
#load-module module-waveout ##
"@

    # Check if the file exists
    if (Test-Path $PAconfig_Pa) {
        # Read the existing content of the file
        $fileContent = Get-Content $PAconfig_Pa

        # Remove the specific line
        $updatedContent = $fileContent | Where-Object { $_ -ne "load-module module-waveout sink_name=output source_name=input" }

        # Write the updated content back to the file
        $updatedContent | Set-Content $PAconfig_Pa

        # Append the new content
        Add-Content -Path $PAconfig_Pa -Value $PAconfig_PaContent

        Write-Host "Updated $PAconfig_Pa successfully."
    }
    else {
        Write-Host "The file $PAconfig_Pa does not exist."
    }
    #--------------------------------------------------------------
    # pulse daemon config
    # Define the path to the configuration file
    $PADeamon_Conf = "$PAConfigDir\daemon.conf"

    # Define the content to be added
    $PADeamon_ConfContent = @"
# Windows WSL2 Configuration
exit-idle-time=-1
"@

    # Check if the file exists
    if (Test-Path $PADeamon_Conf) {
        # Read the existing content of the file
        $fileContent = Get-Content $PADeamon_Conf

        # Remove the specific line and prepare to insert the new content
        $updatedContent = @()
        $inserted = $false

        foreach ($line in $fileContent) {
            # Add the current line to the updated content
            $updatedContent += $line
        
            # Check if the current line is the one we want to modify
            if ($line -eq "; exit-idle-time = 20" -and -not $inserted) {
                # Append the new content after the specified line
                $updatedContent += $PADeamon_ConfContent
                $inserted = $true
            }
        }

        # Write the updated content back to the file
        $updatedContent | Set-Content $PADeamon_Conf

        Write-Host "Updated $PADeamon_Conf successfully."
    }
    else {
        Write-Host "The file $PADeamon_Conf does not exist."
    }
    #--------------------------------------------------------------
    # Function to update firewall rules for the PulseAudio process
    function Update-FirewallRule {
        param (
            [string]$processName,
            [string]$processPath
        )

        # Check if the process is running
        $process = Get-Process -Name $processName -ErrorAction SilentlyContinue

        if ($process) {
            Write-Host "$processName process is running."

            # Check if firewall rules exist for the process path
            $firewallRules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*$processName*" }

            if ($firewallRules) {
                # Check if the rules allow both Public and Private
                $publicRule = $firewallRules | Where-Object { $_.Profile -eq 'Public' }
                $privateRule = $firewallRules | Where-Object { $_.Profile -eq 'Private' }

                if (-not $publicRule) {
                    Write-Host "Adding firewall rule to allow $processName on Public network."
                    New-NetFirewallRule -DisplayName "$processName - Public Access" -Direction Inbound -Action Allow -Protocol TCP -Program $processPath -Profile Public
                }
                else {
                    Write-Host "$processName already has Public network access."
                }

                if (-not $privateRule) {
                    Write-Host "Adding firewall rule to allow $processName on Private network."
                    New-NetFirewallRule -DisplayName "$processName - Private Access" -Direction Inbound -Action Allow -Protocol TCP -Program $processPath -Profile Private
                }
                else {
                    Write-Host "$processName already has Private network access."
                }
            }
            else {
                Write-Host "No firewall rules found for $processName. Creating rules for both Public and Private."
                New-NetFirewallRule -DisplayName "$processName - Public Access" -Direction Inbound -Action Allow -Protocol TCP -Program $processPath -Profile Public
                New-NetFirewallRule -DisplayName "$processName - Private Access" -Direction Inbound -Action Allow -Protocol TCP -Program $processPath -Profile Private
            }
        }
        else {
            Write-Host "$processName process is not running."
        }
    }

    Write-Host "#--------------------------------------------------------------"
    foreach ($package in $packages) {
        # Define the task name and paths
        $taskName = "$package.WSL2"
        $description = "Task to run $package for WSL2 automatically."

        #---------------------------------------------
        #> SPECIFIC ACTIONS
        if ($package -eq "pulseaudio") {
            # Define the action to start PulseAudio
            $TaskPath = "powershell.exe"
            $Argument = "-NoProfile -WindowStyle Hidden -command $PAexe"
        }
        elseif ($package -eq "vcxsrv") {
            # Define the action to start vcxsrv   
            $TaskPath = $VCexe
            $Argument = ':0 -multiwindow -clipboard -wgl -ac'
        }
        #---------------------------------------------

        $action = New-ScheduledTaskAction -Execute $TaskPath -Argument $Argument
        # Define the trigger to start at logon
        $trigger = New-ScheduledTaskTrigger -AtLogon

        # Check if the task already exists
        if (Get-ScheduledTask | Where-Object { $_.TaskName -eq $taskName }) {
            Write-Host "The task $taskName already exists. Skipping creation."
        }
        else {
            # Register the scheduled task
            Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Description $description -RunLevel Highest

            Write-Host "$taskName has been created and set to start at logon."
        }

        # Update firewall rules for the PulseAudio process
        Update-FirewallRule -processName $taskName -processPath $TaskPath
        Write-Host "$taskName process setup completed."
    
        # Start the scheduled task immediately
        Write-Host "Starting the scheduled task..."
        Start-ScheduledTask -TaskName $taskName

        # Optionally check if the task is running
        $task = Get-ScheduledTask | Where-Object { $_.TaskName -eq $taskName }

        if ($task) {
            $taskState = $task.State
            if ($taskState -eq 'Running') {
                Write-Host "$taskName is running in the background."
            }
            else {
                Write-Host "$taskName is not running. Current state: $taskState"
            }
        }
        else {
            Write-Host "$taskName does not exist."
        }
        Write-Host "#--------------------------------------------------------------"

    }

}

#--------------------------------
# Main script logic
function Main() {
    try {
        Write-Host "Do you want to manage a current installed distribution or install a new one?"
        Write-Host "1. Manage current installed distribution"
        Write-Host "2. Install new distribution"
        Write-Host "3. Show installed Distros info"
        Write-Host "4. CHECK/SET/FIX > AUDIO & GUI"
        Write-Host "5. EXIT"
        $choice = Read-Host "Enter your choice (1/2/3/4/5)"
        Write-Host " "

        if ($choice -eq 1) {
            $selectedDistro = GetFromInstalledWSLDistros
            $cleanedString = $selectedDistro -replace '[^\p{L}\p{N}._\-?!]', ''
            $cleanedString = $cleanedString.Trim()
            $selectedDistro = $cleanedString
            Write-Host " "
            Write-Host "Choose an option for [$selectedDistro]:"
            Write-Host "1. Delete distribution"
            Write-Host "2. Clone  distribution"
            Write-Host "3. Main menu"
            Write-Host "4. EXIT"

            while ($true) {
                $choice2 = Read-Host "Enter your choice (1/2/3/4)"
                if ($choice2 -eq 1) {
                    Write-Host "Deleting WSL distribution: $selectedDistro"
                    Start-Process -FilePath $wslPath -ArgumentList "--unregister", $selectedDistro -NoNewWindow -Wait
                    Write-Host "WSL distribution $selectedDistro has been deleted successfully."
                    Write-Output "__________________________________________________"
                    Write-Output " "
                    Main
                } 
                elseif ($choice2 -eq 2) {
                    SetCustomDistroName
                    Write-Host "WSL distribution $selectedDistro has been cloned successfully ...."
                    Write-Output "__________________________________________________"
                    Write-Output " "
                    Main
                }
                elseif ($choice2 -eq 3) {
                    Main
                }
                elseif ($choice2 -eq 4) {
                    exit
                }
                else {
                    Write-Warning "Invalid selection. Please input a valid number"
                }
            }
        }
        elseif ($choice -eq 2) {
            $selectedDistro = GetFromAllWSLDistros
            $cleanedString = $selectedDistro -replace '[^\p{L}\p{N}._\-?!]', ''
            $cleanedString = $cleanedString.Trim()
            $selectedDistro = $cleanedString

            Start-Process -FilePath $wslPath -ArgumentList "--install", "-d", $selectedDistro -wait
            Write-Output "Installed! Setting root-only login ..."
            Start-Process -FilePath $wslPath -ArgumentList "-d", $selectedDistro, "-u", "root", "passwd", "-d", "root" -NoNewWindow -Wait
            Write-Output "Root-only login set!"

            SetCustomDistroName
            Write-Output "__________________________________________________"
            Write-Output " "
            Main
        }
        elseif ($choice -eq 3) {
            ShowInfo
            Write-Output "__________________________________________________"
            Write-Output " "
            Main
        }
        elseif ($choice -eq 4) {
            CHECK_SET_FIX_AUDIO_GUI
            Main
        }
        elseif ($choice -eq 5) {
            exit
        }
        else {
            Write-Warning "Invalid selection. Please choose a valid option."
            Main
        }
    }
    catch {
        Write-Error "An error occurred: $_"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit
    }
}
#--------------------------------
RunSequentialScripts
