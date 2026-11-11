#Requires -Version 5.0
$ErrorActionPreference = "Stop"

# -- Helpers -------------------------------------------------------------------

function Write-Step-OK($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green  }
function Write-Step-Fail($msg) { Write-Host "  [X]  $msg" -ForegroundColor Red    }
function Write-Step-Info($msg) { Write-Host "  [i]  $msg" -ForegroundColor Yellow }

# Phase 97: Hungarian when the Windows culture is Hungarian, English otherwise.
# (PowerShell names are case-insensitive: the flag must not share a name with M's parameters)
$QuorumHu = ((Get-Culture).TwoLetterISOLanguageName -eq "hu") -or ((Get-UICulture).TwoLetterISOLanguageName -eq "hu")
function M($huText, $enText) { if ($QuorumHu) { return $huText } else { return $enText } }

# An existing install (update run): the license fingerprint is already bound and
# the Docker Desktop resources are set, so those Enter-gated reminders are skipped.
$installDir = if ($env:QUORUM_INSTALL_DIR) { $env:QUORUM_INSTALL_DIR } else { Join-Path $HOME "quorum" }
$isUpdate = Test-Path (Join-Path $installDir ".env")

function Test-Admin {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object System.Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-Command($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

# -- Header --------------------------------------------------------------------

Clear-Host
Write-Host ""
Write-Host "  +==========================================+" -ForegroundColor Cyan
Write-Host ("  |" + (M "           QuorumAI  telepito             " "           QuorumAI  installer            ") + "|") -ForegroundColor Cyan
Write-Host "  +==========================================+" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Admin)) {
    Write-Step-Info (M "Nem futtatod adminisztrátorként." "You are not running as Administrator.")
    Write-Step-Info (M "Ha winget-tel kell telepíteni Pythont vagy Dockert, indítsd újra" "If Python or Docker has to be installed with winget, restart")
    Write-Step-Info (M "admin jogosultságokkal (jobb klikk, Futtatás rendszergazdaként)." "with admin rights (right click, Run as administrator).")
    Write-Host ""
}

# -- Python3 -------------------------------------------------------------------

Write-Host (M "  Python3 ellenőrzés..." "  Checking Python3...") -ForegroundColor White

$pythonCmd = $null
foreach ($cmd in @("python3", "python")) {
    try {
        $ver = & $cmd --version 2>&1
        if ($ver -match "Python 3") {
            $pythonCmd = $cmd
            break
        }
    } catch { }
}

if ($pythonCmd) {
    Write-Step-OK ((M "Python megtalálva: " "Python found: ") + $( & $pythonCmd --version 2>&1 ))
} else {
    Write-Step-Info (M "Python3 nem található, telepítés..." "Python3 not found, installing...")
    Write-Host ""

    if (Test-Command "winget") {
        try {
            winget install -e --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements
            Write-Host ""
            Write-Step-OK (M "Python telepítve. Frissítsd a PATH-t (zárd be és nyisd meg újra a terminált)." "Python installed. Refresh PATH (close and reopen the terminal).")
            $pythonCmd = "python"
        } catch {
            Write-Step-Fail ((M "winget telepítés sikertelen: " "winget install failed: ") + $_)
            Write-Step-Info (M "Töltsd le manuálisan: https://www.python.org/downloads/" "Download it manually: https://www.python.org/downloads/")
            Read-Host (M "  Telepítés után nyomj Entert a folytatáshoz" "  Press Enter after installing to continue")
            $pythonCmd = "python"
        }
    } else {
        Write-Step-Info (M "winget nem elérhető." "winget is not available.")
        Write-Step-Info (M "Töltsd le manuálisan: https://www.python.org/downloads/" "Download it manually: https://www.python.org/downloads/")
        Write-Step-Info (M "Telepítésnél pipáld be: 'Add Python to PATH'" "During setup tick: 'Add Python to PATH'")
        Write-Host ""
        Read-Host (M "  Telepítés után nyomj Entert a folytatáshoz" "  Press Enter after installing to continue")
        $pythonCmd = "python"
    }
}

Write-Host ""

# -- Hardware virtualization --------------------------------------------------

Write-Host (M "  Hardveres virtualizáció ellenőrzés..." "  Checking hardware virtualization...") -ForegroundColor White

$virtEnabled = $null          # $true / $false / $null (unknown)
$hypervisorPresent = $false
try {
    $ci = Get-ComputerInfo -Property "HyperVRequirementVirtualizationFirmwareEnabled","HyperVisorPresent" -ErrorAction SilentlyContinue
    if ($ci) {
        $hypervisorPresent = [bool]$ci.HyperVisorPresent
        if ($null -ne $ci.HyperVRequirementVirtualizationFirmwareEnabled) {
            $virtEnabled = [bool]$ci.HyperVRequirementVirtualizationFirmwareEnabled
        }
    }
} catch { }
if ($null -eq $virtEnabled) {
    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cpu -and $null -ne $cpu.VirtualizationFirmwareEnabled) {
            $virtEnabled = [bool]$cpu.VirtualizationFirmwareEnabled
        }
    } catch { }
}

if ($hypervisorPresent) {
    # A running hypervisor (Hyper-V/WSL2) can mask the firmware flag, but
    # virtualization demonstrably works.
    Write-Step-OK (M "Virtualizáció aktív (hypervisor fut)." "Virtualization active (a hypervisor is running).")
} elseif ($virtEnabled -eq $true) {
    Write-Step-OK (M "Hardveres virtualizáció engedélyezve." "Hardware virtualization enabled.")
} elseif ($virtEnabled -eq $false) {
    Write-Step-Fail (M "A hardveres virtualizáció KI van kapcsolva a BIOS/UEFI-ben." "Hardware virtualization is DISABLED in the BIOS/UEFI.")
    Write-Host ""
    if ($QuorumHu) {
        Write-Step-Info "A Docker Desktop (WSL2/Hyper-V) virtualizációt igényel. Bekapcsolás:"
        Write-Step-Info "  1. Indítsd újra a gépet, és lépj be a BIOS/UEFI-be (boot közben:"
        Write-Step-Info "     Del / F2 / F10 / Esc, gyártófüggő, a gyártó logójánál kiírja)."
        Write-Step-Info "  2. Keresd: Intel: 'Intel Virtualization Technology' / 'VT-x',"
        Write-Step-Info "     AMD: 'SVM Mode' / 'AMD-V' (gyakran: Advanced / CPU Configuration)."
        Write-Step-Info "  3. Állítsd 'Enabled'-re, mentsd (általában F10), és indíts újra."
        Write-Step-Info "  4. Utána futtasd újra ezt a telepítőt."
        Write-Host ""
        Write-Step-Info "(Ha biztos vagy benne, hogy be van kapcsolva és a detektálás téved,"
        Write-Step-Info " a folytatás nem tiltott, de a Docker enélkül nem indul el.)"
    } else {
        Write-Step-Info "Docker Desktop (WSL2/Hyper-V) needs virtualization. To enable it:"
        Write-Step-Info "  1. Restart and enter the BIOS/UEFI (during boot: Del / F2 / F10 / Esc,"
        Write-Step-Info "     depends on the vendor, shown at the vendor logo)."
        Write-Step-Info "  2. Look for Intel: 'Intel Virtualization Technology' / 'VT-x',"
        Write-Step-Info "     AMD: 'SVM Mode' / 'AMD-V' (often under Advanced / CPU Configuration)."
        Write-Step-Info "  3. Set it to 'Enabled', save (usually F10) and restart."
        Write-Step-Info "  4. Then run this installer again."
        Write-Host ""
        Write-Step-Info "(If you are sure it is enabled and the detection is wrong, you may"
        Write-Step-Info " continue, but Docker will not start without it.)"
    }
    Read-Host (M "  Nyomj Entert a folytatáshoz (vagy kapcsold be a BIOS-ban, és futtasd újra)" "  Press Enter to continue (or enable it in the BIOS and run again)")
} else {
    Write-Step-Info (M "A virtualizáció állapota nem megállapítható, folytatás." "The virtualization state could not be determined, continuing.")
    Write-Step-Info (M "Ha a Docker később virtualizációs hibát ad, kapcsold be a BIOS/UEFI-ben" "If Docker later reports a virtualization error, enable it in the BIOS/UEFI")
    Write-Step-Info "(Intel VT-x / AMD SVM)."
}

Write-Host ""

# -- Docker backend (WSL2 / Hyper-V / Docker VMM) ---------------------------------

Write-Host (M "  Docker backend ellenőrzés..." "  Checking the Docker backend...") -ForegroundColor White

function Get-FeatureEnabled($name) {
    try {
        $f = Get-WindowsOptionalFeature -Online -FeatureName $name -ErrorAction SilentlyContinue
        return ($f -and $f.State -eq "Enabled")
    } catch { return $false }
}

# Is WSL2 available (the most reliable backend, also on Home editions)?
$wslOk = $false
if (Test-Command "wsl") {
    try { & wsl --status 2>&1 | Out-Null; if ($LASTEXITCODE -eq 0) { $wslOk = $true } } catch { }
}

if ($wslOk) {
    Write-Step-OK (M "WSL2 elérhető, a Docker Desktop ezt tudja használni." "WSL2 is available, Docker Desktop can use it.")
} else {
    # Common pitfall: Hyper-V looks "enabled", yet Docker Desktop (WSL2 / Docker
    # VMM backend) does not start: VirtualMachinePlatform / HypervisorPlatform is
    # missing, or the hypervisor does not launch at boot. These are ensured here.
    if (-not (Test-Admin)) {
        Write-Step-Fail (M "A Docker backend előkészítéséhez ADMIN jog kell." "Preparing the Docker backend needs ADMIN rights.")
        Write-Step-Info (M "Indítsd újra a telepítőt rendszergazdaként (jobb klikk, Futtatás rendszergazdaként)." "Restart the installer as administrator (right click, Run as administrator).")
        Read-Host (M "  Nyomj Entert a kilépéshez" "  Press Enter to exit")
        exit 1
    }

    $needReboot = $false

    # 1) Virtual Machine Platform (WSL2 + Docker VMM)
    if (Get-FeatureEnabled "VirtualMachinePlatform") {
        Write-Step-OK (M "VirtualMachinePlatform már engedélyezve." "VirtualMachinePlatform already enabled.")
    } else {
        Write-Step-Info (M "VirtualMachinePlatform engedélyezése..." "Enabling VirtualMachinePlatform...")
        try { Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -ErrorAction Stop | Out-Null; $needReboot = $true; Write-Step-OK (M "VirtualMachinePlatform bekapcsolva." "VirtualMachinePlatform enabled.") }
        catch { Write-Step-Fail "VirtualMachinePlatform: $_" }
    }

    # 2) Windows Hypervisor Platform (Docker VMM backend)
    if (Get-FeatureEnabled "HypervisorPlatform") {
        Write-Step-OK (M "HypervisorPlatform már engedélyezve." "HypervisorPlatform already enabled.")
    } else {
        Write-Step-Info (M "HypervisorPlatform engedélyezése (Docker VMM)..." "Enabling HypervisorPlatform (Docker VMM)...")
        try { Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -NoRestart -ErrorAction Stop | Out-Null; $needReboot = $true; Write-Step-OK (M "HypervisorPlatform bekapcsolva." "HypervisorPlatform enabled.") }
        catch { Write-Step-Fail "HypervisorPlatform: $_" }
    }

    # 3) The hypervisor must launch at boot (hypervisorlaunchtype = Auto)
    $hlt = (& bcdedit /enum 2>$null | Select-String -Pattern "hypervisorlaunchtype")
    if ($hlt -and ($hlt -match "Auto")) {
        Write-Step-OK (M "hypervisorlaunchtype már Auto." "hypervisorlaunchtype is already Auto.")
    } else {
        Write-Step-Info (M "hypervisorlaunchtype = Auto (a hypervisor boot-kor induljon)..." "hypervisorlaunchtype = Auto (launch the hypervisor at boot)...")
        try { & bcdedit /set hypervisorlaunchtype auto | Out-Null; $needReboot = $true; Write-Step-OK (M "hypervisorlaunchtype = Auto beállítva." "hypervisorlaunchtype = Auto set.") }
        catch { Write-Step-Fail "bcdedit hypervisorlaunchtype: $_" }
    }

    # 4) Install WSL2 when even the 'wsl' command is missing
    if (-not (Test-Command "wsl")) {
        Write-Step-Info (M "WSL2 telepítése (wsl --install)..." "Installing WSL2 (wsl --install)...")
        try { wsl --install | Out-Null; $needReboot = $true; Write-Step-OK (M "WSL2 telepítés elindítva." "WSL2 installation started.") }
        catch {
            Write-Step-Fail ((M "wsl --install sikertelen: " "wsl --install failed: ") + $_)
            Write-Step-Info ((M "Kézzel: " "Manually: ") + "dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart")
            Write-Step-Info ((M "kernel: https://aka.ms/wsl2kernel , majd: " "kernel: https://aka.ms/wsl2kernel , then: ") + "wsl --set-default-version 2")
        }
    }

    if ($needReboot) {
        Write-Host ""
        Write-Step-Info (M "FONTOS: a beállítások ÚJRAINDÍTÁST igényelnek." "IMPORTANT: these settings need a RESTART.")
        Write-Step-Info (M "Indítsd újra a gépet, majd futtasd ÚJRA ezt a telepítőt, innen folytatódik." "Restart the computer, then run this installer AGAIN, it continues from here.")
        Read-Host (M "  Nyomj Entert a kilépéshez (és indítsd újra a gépet)" "  Press Enter to exit (and restart the computer)")
        exit 0
    }
}

Write-Host ""

# -- Docker --------------------------------------------------------------------

Write-Host (M "  Docker ellenőrzés..." "  Checking Docker...") -ForegroundColor White

$dockerOk = $false
try {
    $dver = & docker --version 2>&1
    if ($dver -match "Docker version") {
        Write-Step-OK ((M "Docker megtalálva: " "Docker found: ") + $dver)
        $dockerOk = $true
    }
} catch { }

if (-not $dockerOk) {
    Write-Step-Info (M "Docker Desktop nem található, telepítés..." "Docker Desktop not found, installing...")
    Write-Host ""

    if (Test-Command "winget") {
        try {
            winget install -e --id Docker.DockerDesktop --accept-package-agreements --accept-source-agreements
            Write-Host ""
            Write-Step-OK (M "Docker Desktop telepítve." "Docker Desktop installed.")
        } catch {
            Write-Step-Fail ((M "winget telepítés sikertelen: " "winget install failed: ") + $_)
            Write-Step-Info (M "Töltsd le manuálisan:" "Download it manually:")
            Write-Step-Info "https://docs.docker.com/desktop/setup/install/windows-install/"
            Read-Host (M "  Telepítés után nyomj Entert a folytatáshoz" "  Press Enter after installing to continue")
        }
    } else {
        Write-Step-Info (M "winget nem elérhető." "winget is not available.")
        Write-Step-Info (M "Töltsd le manuálisan:" "Download it manually:")
        Write-Step-Info "https://docs.docker.com/desktop/setup/install/windows-install/"
        Write-Host ""
        Read-Host (M "  Telepítés után nyomj Entert a folytatáshoz" "  Press Enter after installing to continue")
    }

    Write-Host ""
    Write-Step-Info (M "Indítsd el a Docker Desktop alkalmazást, és várd meg amíg elindul." "Start the Docker Desktop app and wait until it is running.")
    Read-Host (M "  Ha a Docker fut (tálca ikon zöld), nyomj Entert a folytatáshoz" "  When Docker is running (green tray icon), press Enter to continue")
    Write-Host ""
}

# -- Docker memory and license, Docker Desktop resources (first install only) --

if (-not $isUpdate) {
    Write-Host (M "  ! FONTOS! Docker memória és a licenc" "  ! IMPORTANT: Docker memory and the license") -ForegroundColor Yellow
    if ($QuorumHu) {
        Write-Step-Info "A QuorumAI licenc a Docker Desktop / WSL2 virtuális gépéhez kötődik,"
        Write-Step-Info "és az azonosítás része a VM memória-beállítása is."
        Write-Host ""
        Write-Step-Info "Állítsd be MOST a végleges értéket (ajánlott: legalább 8 GB):"
        Write-Step-Info "  - WSL2 backend (alapértelmezett): %UserProfile%\.wslconfig fájlban:"
        Write-Step-Info "        [wsl2]"
        Write-Step-Info "        memory=8GB"
        Write-Step-Info "    majd futtasd: wsl --shutdown  és indítsd újra a Docker Desktopot."
        Write-Step-Info "  - Hyper-V backend: Docker Desktop > Settings > Resources > Memory"
        Write-Host ""
        Write-Step-Info "Ha a telepítés után átméretezed a memóriát, megváltozik a"
        Write-Step-Info "hardver-ujjlenyomat, a licenc érvénytelenné válik, és a supporttól"
        Write-Step-Info "kell új gép-hozzárendelést kérned: https://license.quorumai.eu"
    } else {
        Write-Step-Info "The QuorumAI license is bound to the Docker Desktop / WSL2 virtual machine,"
        Write-Step-Info "and its memory setting is part of the fingerprint."
        Write-Host ""
        Write-Step-Info "Set the final value NOW (recommended: at least 8 GB):"
        Write-Step-Info "  - WSL2 backend (default): in %UserProfile%\.wslconfig:"
        Write-Step-Info "        [wsl2]"
        Write-Step-Info "        memory=8GB"
        Write-Step-Info "    then run: wsl --shutdown  and restart Docker Desktop."
        Write-Step-Info "  - Hyper-V backend: Docker Desktop > Settings > Resources > Memory"
        Write-Host ""
        Write-Step-Info "If you resize the memory after installing, the hardware fingerprint"
        Write-Step-Info "changes, the license becomes invalid, and support has to re-assign"
        Write-Step-Info "it to the new machine: https://license.quorumai.eu"
    }
    Write-Host ""
    Read-Host (M "  Nyomj Entert, ha a memória végleges értékre van állítva" "  Press Enter once the memory is set to its final value")
    Write-Host ""

    Write-Host (M "  Docker Desktop beállítások (Settings > Resources)" "  Docker Desktop settings (Settings > Resources)") -ForegroundColor White
    if ($QuorumHu) {
        Write-Step-Info "Állítsd be MOST, mielőtt a konténerek elindulnak:"
        Write-Step-Info "  - Lemez-limit (Disk usage limit): legalább 28 GB."
        Write-Step-Info "      Settings > Resources > Disk usage limit"
        Write-Step-Info "      (a modell- és image-helyigény miatt; WSL2-n a virtuális lemez eddig nőhet)."
        Write-Step-Info "  - Fájlmegosztás (File sharing): oszd meg a telepítési mappát."
        Write-Step-Info "      Settings > Resources > File sharing > 'Virtual file shares' >"
        Write-Step-Info "      add hozzá azt a mappát, ahová a projekt települ (a data/ bind-mountokhoz)."
    } else {
        Write-Step-Info "Set these NOW, before the containers start:"
        Write-Step-Info "  - Disk usage limit: at least 28 GB."
        Write-Step-Info "      Settings > Resources > Disk usage limit"
        Write-Step-Info "      (models and images; on WSL2 the virtual disk can grow up to this)."
        Write-Step-Info "  - File sharing: share the install folder."
        Write-Step-Info "      Settings > Resources > File sharing > 'Virtual file shares' >"
        Write-Step-Info "      add the folder the project is installed into (for the data/ bind mounts)."
    }
    Write-Host ""
    Read-Host (M "  Nyomj Entert, ha a lemez-limit és a fájlmegosztás beállítva" "  Press Enter once the disk limit and file sharing are set")
    Write-Host ""

    Write-Host (M "  NVIDIA GPU-gyorsítás (opcionális)" "  NVIDIA GPU acceleration (optional)") -ForegroundColor White
    Write-Step-Info (M "Csak akkor kell, ha helyi LLM-et (pl. Ollama) GPU-n futtatnál konténerben." "Only needed to run a local LLM (e.g. Ollama) on the GPU in a container.")
    Write-Step-Info (M "GPU Dockerben CSAK WSL2 backenddel működik (Hyper-V-vel nem)." "GPU in Docker works ONLY with the WSL2 backend (not with Hyper-V).")
    Write-Step-Info (M "Szükséges: friss NVIDIA driver + nvidia-container-toolkit a WSL2 disztróban." "Needed: a recent NVIDIA driver + nvidia-container-toolkit in the WSL2 distro.")
    Write-Step-Info (M "CUDA / driver letöltés: https://developer.nvidia.com/cuda-downloads" "CUDA / driver download: https://developer.nvidia.com/cuda-downloads")
    Write-Host ""
}

# -- Is Docker Desktop running (engine reachable before the download)? --------

Write-Host (M "  Docker Desktop futásának ellenőrzése..." "  Checking that Docker Desktop is running...") -ForegroundColor White
$engineOk = $false
for ($i = 0; $i -lt 40; $i++) {
    try {
        & docker info 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { $engineOk = $true; break }
    } catch { }
    if ($i -eq 0) {
        Write-Step-Info (M "A Docker motor még nem elérhető: indítsd el a Docker Desktop appot," "The Docker engine is not reachable yet: start the Docker Desktop app")
        Write-Step-Info (M "és várd meg, amíg a tálca-ikon zöld (ez eltarthat egy percig)..." "and wait until the tray icon is green (this can take a minute)...")
    }
    Start-Sleep -Seconds 3
}
if ($engineOk) {
    Write-Step-OK (M "Docker Desktop fut (a motor elérhető)." "Docker Desktop is running (the engine is reachable).")
} else {
    Write-Step-Fail (M "A Docker motor nem érhető el (docker info sikertelen)." "The Docker engine is not reachable (docker info failed).")
    Write-Step-Info (M "Indítsd el a Docker Desktopot, várd meg amíg elindul, majd nyomj Entert." "Start Docker Desktop, wait until it is up, then press Enter.")
    Read-Host (M "  Nyomj Entert a folytatáshoz" "  Press Enter to continue")
}
Write-Host ""

# -- Download and run install.py ----------------------------------------------

Write-Host (M "  QuorumAI telepítő letöltése..." "  Downloading the QuorumAI installer...") -ForegroundColor White

$url = "https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.py"
$tmp = Join-Path $env:TEMP "quorum_install.py"

try {
    Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
    Write-Step-OK ((M "Letöltve: " "Downloaded: ") + $tmp)
} catch {
    Write-Step-Fail ((M "Letöltés sikertelen: " "Download failed: ") + $_)
    Write-Step-Info (M "Ellenőrizd az internetkapcsolatot, vagy futtasd manuálisan:" "Check the internet connection, or run it manually:")
    Write-Step-Info "  python install.py"
    Read-Host (M "  Nyomj Entert a kilépéshez" "  Press Enter to exit")
    exit 1
}

Write-Host ""
Write-Host (M "  QuorumAI telepítő indítása..." "  Starting the QuorumAI installer...") -ForegroundColor Cyan
Write-Host ""

try {
    & $pythonCmd $tmp
} catch {
    Write-Step-Fail ((M "Telepítő futtatása sikertelen: " "Running the installer failed: ") + $_)
    Write-Step-Info ((M "Próbáld manuálisan: python " "Try it manually: python ") + $tmp)
    Read-Host (M "  Nyomj Entert a kilépéshez" "  Press Enter to exit")
    exit 1
}
