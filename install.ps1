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
