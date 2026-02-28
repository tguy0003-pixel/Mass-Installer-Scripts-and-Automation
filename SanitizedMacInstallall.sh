# --- ENTERPRISE DEPLOYMENT CONFIGURATION ---
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$LocalInstallers = "$ScriptPath\Installers"
$EnterpriseSuiteNetworkPath = "\\YOUR.SERVER.IP\SoftwareShare\EnterpriseSuite\Windows_64\setup.exe"

Clear-Host
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "       STARTING AUTOMATED ENDPOINT STAGING             " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "INSTRUCTIONS:"
Write-Host "1. Standard packages will execute silently."
Write-Host "2. Exception packages will pause execution."
Write-Host "   -> Complete the exception installer on-screen."
Write-Host "   -> Press ENTER in this console to resume sequence."
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "Scanning local payload directory..."
Start-Sleep -Seconds 3

# --- PHASE 1: LOCAL PAYLOAD DEPLOYMENT ---
$Items = Get-ChildItem -Path $LocalInstallers | Sort-Object Name

ForEach ($Item in $Items) {
    
    # --- BLOCK A: EXCEPTION HANDLING (Interactive / Complex Installers) ---
    # Handled explicitly to prevent pipeline hangs on undocumented GUI prompts.
    
    # Example 1: Accessibility Tools (Often auto-launch speech engines during install)
    If ($Item.Name -like "*AccessibilityTool*") {
        Write-Host "`n[ACTION REQUIRED] Installing Accessibility Suite..." -ForegroundColor Red
        Write-Host "   -> IF ENGINE LAUNCHES: Right-click the system tray icon and Exit to release the lock."
        
        # Launch WITHOUT -Wait to prevent permanent script hang
        Start-Process $Item.FullName
        Read-Host "   -> Press ENTER here once installation is verified closed"
        Continue
    }

    # Example 2: Massive Enterprise Suites (Requires manual EULA/License Server input)
    If ($Item.Name -like "*GIS_Suite*") {
        Write-Host "`n[ACTION REQUIRED] Installing Enterprise GIS Suite..." -ForegroundColor Red
        Start-Process $Item.FullName
        Read-Host "   -> Press ENTER here once the suite installation finishes"
        Continue
    }

    # Example 3: Nested Installers (Executables buried inside unzipped container folders)
    If ($Item.Name -like "*DataAnalytics*") {
        if ($Item.PSIsContainer) {
            $SetupFile = Get-ChildItem -Path $Item.FullName -Filter "setup.exe" -Recurse -Depth 2 | Select-Object -First 1
            if ($SetupFile) {
                Write-Host "`n[ACTION REQUIRED] Installing Data Analytics Package..." -ForegroundColor Red
                Start-Process $SetupFile.FullName
                Read-Host "   -> Press ENTER here once the package finishes"
            }
        }
        Continue
    }
    
    # --- BLOCK B: STANDARD AUTOMATION (Silent Execution) ---
    
    # Exception: Legacy Apps requiring specific InnoSetup flags (e.g., /SP-)
    If ($Item.Name -like "*LegacyMediaApp*") {
        Write-Host "Installing Legacy Media Application (Silent)..." -ForegroundColor Yellow
        Start-Process $Item.FullName -ArgumentList "/VERYSILENT /NORESTART /SP-" -Wait
        Continue
    }

    # Standard MSI Packages
    If ($Item.Extension -eq ".msi") {
        Write-Host "Installing MSI Payload: $($Item.Name)..." -ForegroundColor Yellow
        Start-Process "msiexec.exe" -ArgumentList "/i `"$($Item.FullName)`" /qn /norestart" -Wait
    }
    # Standard EXE Packages
    ElseIf ($Item.Extension -eq ".exe") {
        Write-Host "Installing EXE Payload: $($Item.Name)..." -ForegroundColor Yellow
        Start-Process $Item.FullName -ArgumentList "/S" -Wait
    }
}

# --- PHASE 2: NETWORK PAYLOAD DELIVERY ---
Write-Host "`n--- PHASE 2: Network Suite Installation ---" -ForegroundColor Magenta
if (Test-Path $EnterpriseSuiteNetworkPath) {
    Write-Host "   [+] Target server resolved. Executing remote payload (This may take several minutes)..."
    Start-Process -FilePath $EnterpriseSuiteNetworkPath -ArgumentList "--silent" -Wait
    Write-Host "   [+] Remote installation complete." -ForegroundColor Green
} Else {
    Write-Host "   [!] Target server unreachable. Skipping remote payload." -ForegroundColor Red
}

# --- PHASE 3: WORKSPACE CONFIGURATION ---
Write-Host "`n--- PHASE 3: Forcing Public Desktop Shortcuts ---" -ForegroundColor Cyan
Function Create-Shortcut {
    param ([string]$ExePath, [string]$Name)
    if (Test-Path $ExePath) {
        $WshShell = New-Object -comObject WScript.Shell
        $LnkPath = "C:\Users\Public\Desktop\$Name.lnk"
        $Shortcut = $WshShell.CreateShortcut($LnkPath)
        $Shortcut.TargetPath = $ExePath
        $Shortcut.Save()
        Write-Host "   [+] Shortcut Created: $Name" -ForegroundColor Green
    }
}

# Enforce shortcuts for frequently buried executables
Create-Shortcut "C:\Program Files\MediaSuite\bin\MediaApp.exe" "Media Studio"
Create-Shortcut "C:\Program Files (x86)\EnterpriseSuite\Core\Launcher.exe" "Enterprise Suite Hub"

# --- PHASE 4: VALIDATION ---
Clear-Host
Write-Host "=======================================================" -ForegroundColor Red
Write-Host "           DEPLOYMENT SEQUENCE COMPLETE                " -ForegroundColor Red
Write-Host "=======================================================" -ForegroundColor Red
Write-Host "Press Enter to exit..."
Read-Host