#Requires -Version 5.0
$ErrorActionPreference = "Stop"

# ── Helpers ───────────────────────────────────────────────────────────────────

function Write-Step-OK($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green  }
function Write-Step-Fail($msg) { Write-Host "  [X]  $msg" -ForegroundColor Red    }
function Write-Step-Info($msg) { Write-Host "  [i]  $msg" -ForegroundColor Yellow }

function Test-Admin {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object System.Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-Command($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

# ── Header ────────────────────────────────────────────────────────────────────

Clear-Host
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║           QuorumAI  Telepítő             ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Admin)) {
    Write-Step-Info "Nem futtatod adminisztrátorként."
    Write-Step-Info "Ha winget-tel kell telepíteni Pythont vagy Dockert, indítsd újra"
    Write-Step-Info "admin jogosultságokkal (jobb klikk → Futtatás rendszergazdaként)."
    Write-Host ""
}

# ── Python3 ───────────────────────────────────────────────────────────────────

Write-Host "  Python3 ellenőrzés..." -ForegroundColor White

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
    Write-Step-OK "Python megtalálva: $( & $pythonCmd --version 2>&1 )"
} else {
    Write-Step-Info "Python3 nem található, telepítés..."
    Write-Host ""

    if (Test-Command "winget") {
        try {
            winget install -e --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements
            Write-Host ""
            Write-Step-OK "Python telepítve. Frissítsd a PATH-t (zárd be és nyisd meg újra a terminált)."
            $pythonCmd = "python"
        } catch {
            Write-Step-Fail "winget telepítés sikertelen: $_"
            Write-Step-Info "Töltsd le manuálisan: https://www.python.org/downloads/"
            Read-Host "  Telepítés után nyomj Entert a folytatáshoz"
            $pythonCmd = "python"
        }
    } else {
        Write-Step-Info "winget nem elérhető."
        Write-Step-Info "Töltsd le manuálisan: https://www.python.org/downloads/"
        Write-Step-Info "Telepítésnél pipáld be: 'Add Python to PATH'"
        Write-Host ""
        Read-Host "  Telepítés után nyomj Entert a folytatáshoz"
        $pythonCmd = "python"
    }
}

Write-Host ""

# ── Hardveres virtualizáció ─────────────────────────────────────────────────────

Write-Host "  Hardveres virtualizáció ellenőrzés..." -ForegroundColor White

$virtEnabled = $null          # $true / $false / $null (bizonytalan)
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
    # Ha már fut hypervisor (Hyper-V/WSL2), a firmware-flag maszkolódhat, de a
    # virtualizáció bizonyítottan működik.
    Write-Step-OK "Virtualizáció aktív (hypervisor fut)."
} elseif ($virtEnabled -eq $true) {
    Write-Step-OK "Hardveres virtualizáció engedélyezve."
} elseif ($virtEnabled -eq $false) {
    Write-Step-Fail "A hardveres virtualizáció KI van kapcsolva a BIOS/UEFI-ben."
    Write-Host ""
    Write-Step-Info "A Docker Desktop (WSL2/Hyper-V) virtualizációt igényel. Bekapcsolás:"
    Write-Step-Info "  1. Indítsd újra a gépet, és lépj be a BIOS/UEFI-be (boot közben:"
    Write-Step-Info "     Del / F2 / F10 / Esc — gyártófüggő, a gyártó logójánál kiírja)."
    Write-Step-Info "  2. Keresd: Intel → 'Intel Virtualization Technology' / 'VT-x',"
    Write-Step-Info "     AMD → 'SVM Mode' / 'AMD-V' (gyakran: Advanced / CPU Configuration)."
    Write-Step-Info "  3. Állítsd 'Enabled'-re, mentsd (általában F10), és indíts újra."
    Write-Step-Info "  4. Utána futtasd újra ezt a telepítőt."
    Write-Host ""
    Write-Step-Info "(Ha biztos vagy benne, hogy be van kapcsolva és a detektálás téved,"
    Write-Step-Info " a folytatás nem tiltott — de a Docker enélkül nem indul el.)"
    Read-Host "  Nyomj Entert a folytatáshoz (vagy kapcsold be a BIOS-ban, és futtasd újra)"
} else {
    Write-Step-Info "A virtualizáció állapota nem megállapítható — folytatás."
    Write-Step-Info "Ha a Docker később virtualizációs hibát ad, kapcsold be a BIOS/UEFI-ben"
    Write-Step-Info "(Intel VT-x / AMD SVM)."
}

Write-Host ""

# ── Docker backend (WSL2 / Hyper-V / Docker VMM) ─────────────────────────────────

Write-Host "  Docker backend ellenőrzés..." -ForegroundColor White

function Get-FeatureEnabled($name) {
    try {
        $f = Get-WindowsOptionalFeature -Online -FeatureName $name -ErrorAction SilentlyContinue
        return ($f -and $f.State -eq "Enabled")
    } catch { return $false }
}

# WSL2 elérhető-e (a legmegbízhatóbb backend, Home kiadáson is).
$wslOk = $false
if (Test-Command "wsl") {
    try { & wsl --status 2>&1 | Out-Null; if ($LASTEXITCODE -eq 0) { $wslOk = $true } } catch { }
}

if ($wslOk) {
    Write-Step-OK "WSL2 elérhető — a Docker Desktop ezt tudja használni."
} else {
    # Gyakori buktató: a Hyper-V 'engedélyezettnek' látszik, de a Docker Desktop
    # (WSL2 / Docker VMM backend) mégsem indul, mert hiányzik a VirtualMachinePlatform
    # / HypervisorPlatform, vagy a hypervisor nem indul boot-kor. Ezeket biztosítjuk.
    if (-not (Test-Admin)) {
        Write-Step-Fail "A Docker backend előkészítéséhez ADMIN jog kell."
        Write-Step-Info "Indítsd újra a telepítőt rendszergazdaként (jobb klikk → Futtatás rendszergazdaként)."
        Read-Host "  Nyomj Entert a kilépéshez"
        exit 1
    }

    $needReboot = $false

    # 1) Virtual Machine Platform (WSL2 + Docker VMM)
    if (Get-FeatureEnabled "VirtualMachinePlatform") {
        Write-Step-OK "VirtualMachinePlatform már engedélyezve."
    } else {
        Write-Step-Info "VirtualMachinePlatform engedélyezése..."
        try { Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -ErrorAction Stop | Out-Null; $needReboot = $true; Write-Step-OK "VirtualMachinePlatform bekapcsolva." }
        catch { Write-Step-Fail "VirtualMachinePlatform: $_" }
    }

    # 2) Windows Hypervisor Platform (Docker VMM backend)
    if (Get-FeatureEnabled "HypervisorPlatform") {
        Write-Step-OK "HypervisorPlatform már engedélyezve."
    } else {
        Write-Step-Info "HypervisorPlatform engedélyezése (Docker VMM)..."
        try { Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -NoRestart -ErrorAction Stop | Out-Null; $needReboot = $true; Write-Step-OK "HypervisorPlatform bekapcsolva." }
        catch { Write-Step-Fail "HypervisorPlatform: $_" }
    }

    # 3) A hypervisor induljon el boot-kor (hypervisorlaunchtype = Auto)
    $hlt = (& bcdedit /enum 2>$null | Select-String -Pattern "hypervisorlaunchtype")
    if ($hlt -and ($hlt -match "Auto")) {
        Write-Step-OK "hypervisorlaunchtype már Auto."
    } else {
        Write-Step-Info "hypervisorlaunchtype = Auto (a hypervisor boot-kor induljon)..."
        try { & bcdedit /set hypervisorlaunchtype auto | Out-Null; $needReboot = $true; Write-Step-OK "hypervisorlaunchtype = Auto beállítva." }
        catch { Write-Step-Fail "bcdedit hypervisorlaunchtype: $_" }
    }

    # 4) WSL2 telepítése, ha a 'wsl' parancs sincs
    if (-not (Test-Command "wsl")) {
        Write-Step-Info "WSL2 telepítése (wsl --install)..."
        try { wsl --install | Out-Null; $needReboot = $true; Write-Step-OK "WSL2 telepítés elindítva." }
        catch {
            Write-Step-Fail "wsl --install sikertelen: $_"
            Write-Step-Info "Kézzel: dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart"
            Write-Step-Info "kernel: https://aka.ms/wsl2kernel , majd: wsl --set-default-version 2"
        }
    }

    if ($needReboot) {
        Write-Host ""
        Write-Step-Info "FONTOS: a beállítások ÚJRAINDÍTÁST igényelnek."
        Write-Step-Info "Indítsd újra a gépet, majd futtasd ÚJRA ezt a telepítőt — innen folytatódik."
        Read-Host "  Nyomj Entert a kilépéshez (és indítsd újra a gépet)"
        exit 0
    }
}

Write-Host ""

# ── Docker ────────────────────────────────────────────────────────────────────

Write-Host "  Docker ellenőrzés..." -ForegroundColor White

$dockerOk = $false
try {
    $dver = & docker --version 2>&1
    if ($dver -match "Docker version") {
        Write-Step-OK "Docker megtalálva: $dver"
        $dockerOk = $true
    }
} catch { }

if (-not $dockerOk) {
    Write-Step-Info "Docker Desktop nem található, telepítés..."
    Write-Host ""

    if (Test-Command "winget") {
        try {
            winget install -e --id Docker.DockerDesktop --accept-package-agreements --accept-source-agreements
            Write-Host ""
            Write-Step-OK "Docker Desktop telepítve."
        } catch {
            Write-Step-Fail "winget telepítés sikertelen: $_"
            Write-Step-Info "Töltsd le manuálisan:"
            Write-Step-Info "https://docs.docker.com/desktop/setup/install/windows-install/"
            Read-Host "  Telepítés után nyomj Entert a folytatáshoz"
        }
    } else {
        Write-Step-Info "winget nem elérhető."
        Write-Step-Info "Töltsd le manuálisan:"
        Write-Step-Info "https://docs.docker.com/desktop/setup/install/windows-install/"
        Write-Host ""
        Read-Host "  Telepítés után nyomj Entert a folytatáshoz"
    }

    Write-Host ""
    Write-Step-Info "Indítsd el a Docker Desktop alkalmazást, és várd meg amíg elindul."
    Read-Host "  Ha a Docker fut (tálca ikon zöld), nyomj Entert a folytatáshoz"
    Write-Host ""
}

# ── Docker memória + licenc figyelmeztetés ────────────────────────────────────

Write-Host "  ⚠  FONTOS! Docker memória és a licenc" -ForegroundColor Yellow
Write-Step-Info "A QuorumAI licenc a Docker Desktop / WSL2 virtuális gépéhez kötődik,"
Write-Step-Info "és az azonosítás része a VM memória-beállítása is."
Write-Host ""
Write-Step-Info "Állítsd be MOST a végleges értéket (ajánlott: legalább 8 GB):"
Write-Step-Info "  • WSL2 backend (alapértelmezett): %UserProfile%\.wslconfig fájlban:"
Write-Step-Info "        [wsl2]"
Write-Step-Info "        memory=8GB"
Write-Step-Info "    majd futtasd: wsl --shutdown  és indítsd újra a Docker Desktopot."
Write-Step-Info "  • Hyper-V backend: Docker Desktop → Settings → Resources → Memory"
Write-Host ""
Write-Step-Info "Ha a telepítés után átméretezed a memóriát, megváltozik a"
Write-Step-Info "hardver-ujjlenyomat, a licenc érvénytelenné válik, és a supporttól"
Write-Step-Info "kell új gép-hozzárendelést kérned: https://license.quorumai.eu"
Write-Host ""
Read-Host "  Nyomj Entert, ha a memória végleges értékre van állítva"
Write-Host ""

# ── install.py letöltése és futtatása ─────────────────────────────────────────

Write-Host "  QuorumAI telepítő letöltése..." -ForegroundColor White

$url = "https://raw.githubusercontent.com/FulopJozsi/QuorumAI/main/install.py"
$tmp = Join-Path $env:TEMP "quorum_install.py"

try {
    Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
    Write-Step-OK "Letöltve: $tmp"
} catch {
    Write-Step-Fail "Letöltés sikertelen: $_"
    Write-Step-Info "Ellenőrizd az internetkapcsolatot, vagy futtasd manuálisan:"
    Write-Step-Info "  python install.py"
    Read-Host "  Nyomj Entert a kilépéshez"
    exit 1
}

Write-Host ""
Write-Host "  QuorumAI telepítő indítása..." -ForegroundColor Cyan
Write-Host ""

try {
    & $pythonCmd $tmp
} catch {
    Write-Step-Fail "Telepítő futtatása sikertelen: $_"
    Write-Step-Info "Próbáld manuálisan: python $tmp"
    Read-Host "  Nyomj Entert a kilépéshez"
    exit 1
}
