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
# Main script logic
function Main() {
    try {
        Write-Host "Do you want to manage a current installed distribution or install a new one?"
        Write-Host "1. Manage current installed distribution"
        Write-Host "2. Install new distribution"
        Write-Host "3. Show installed Distros info"
        Write-Host "4. EXIT"
        $choice = Read-Host "Enter your choice (1/2/3/4)"
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
