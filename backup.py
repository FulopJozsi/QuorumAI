#!/usr/bin/env python3
"""QuorumAI backup / restore, stdlib only, Python 3.8+

Backup includes: .env + data/  (data/ alone misses the API keys)

Cache directories (model weights, browser binaries, package caches) are stored
as empty placeholder directories, their contents are rebuilt automatically on
first start, saving ~8 GB per backup.

Usage:
    python3 backup.py                              # interactive
    python3 backup.py backup [output.tgz]          # create backup
    python3 backup.py restore <file.tgz> [dir]     # restore

Linux / macOS: run with sudo to preserve file ownership and permissions.
               sudo is required to read data/postgres/ (owned by container user).
Windows:       run normally (no root concept, tarfile handles everything).
"""
from __future__ import annotations

import os
import platform
import sys
import tarfile
from datetime import datetime
from pathlib import Path

# ── helpers ───────────────────────────────────────────────────────────────────

SYSTEM = platform.system()

# Directories whose *contents* are skipped during backup (model weights, browser
# binaries, package caches).  The directory entry itself IS written so that bind
# mounts work immediately after a restore.  Contents are rebuilt on first start.
CACHE_DIRS: set[str] = {
    "data/omnivoice/models",       # TTS/AI model weights, re-downloaded on startup
    "data/wyoming",                # Wyoming Whisper HuggingFace cache
    "data/whisper",                # orchestrator Whisper model cache
    "data/playwright/browsers",    # Playwright browser binaries (playwright install)
    "data/playwright/tmp",         # Playwright temp files
    "data/piper",                  # Piper TTS voices, re-downloaded by container
    "data/mcp-manager/npm_cache",  # npm package cache
    "data/mcp-manager/uv-python",  # uv Python cache
}


def _make_cache_filter(cache_dirs: set[str]):
    """Return a tarfile add-filter that skips cache dir contents but keeps the dirs."""
    def _filter(tarinfo: tarfile.TarInfo) -> "tarfile.TarInfo | None":
        name = tarinfo.name
        for cache in cache_dirs:
            if name.startswith(cache + "/"):
                return None  # skip anything inside the cache dir
        return tarinfo
    return _filter


def _is_root() -> bool:
    if SYSTEM == "Windows":
        try:
            import ctypes
            return ctypes.windll.shell32.IsUserAnAdmin() != 0  # type: ignore[attr-defined]
        except Exception:
            return False
    return os.geteuid() == 0  # type: ignore[attr-defined]


def _warn_not_root() -> None:
    if SYSTEM == "Windows":
        return
    if not _is_root():
        print(
            "\n  FIGYELEM: Nem root jogosultsággal fut. A data/ könyvtárban lévő\n"
            "  fájlok tulajdonosa és jogosultságai nem feltétlenül kerülnek\n"
            "  mentésre / helyreállításra helyesen.\n"
            "  Ajánlott: sudo python3 backup.py\n"
        )


def _script_dir() -> Path:
    return Path(__file__).resolve().parent


def _find_install_dir() -> Path:
    """Return the QuorumAI install dir (contains .env and/or data/)."""
    for candidate in (_script_dir(), Path.cwd()):
        if (candidate / ".env").exists() or (candidate / "data").is_dir():
            return candidate
    return _script_dir()


def ask(prompt: str, default: str = "") -> str:
    display = f"  {prompt} [{default}]: " if default else f"  {prompt}: "
    try:
        val = input(display).strip()
    except (EOFError, KeyboardInterrupt):
        print()
        sys.exit(0)
    return val if val else default


# ── backup ────────────────────────────────────────────────────────────────────

def do_backup(install_dir: Path, output_file: Path | None = None) -> None:
    _warn_not_root()

    env_file = install_dir / ".env"
    data_dir = install_dir / "data"

    if not env_file.exists() and not data_dir.is_dir():
        print(f"\n  HIBA: Sem .env, sem data/ nem található itt: {install_dir}")
        sys.exit(1)

    if output_file is None:
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_file = install_dir / f"quorumai_backup_{ts}.tgz"

    print(f"\n  Backup létrehozása: {output_file}")

    included: list[str] = []
    skipped: list[str] = []
    cache_filter = _make_cache_filter(CACHE_DIRS)

    with tarfile.open(output_file, "w:gz") as tar:
        if env_file.exists():
            tar.add(env_file, arcname=".env")
            included.append(".env")
        else:
            skipped.append(".env (nem található)")

        if data_dir.is_dir():
            tar.add(data_dir, arcname="data", filter=cache_filter)
            included.append("data/")
        else:
            skipped.append("data/ (nem található)")

    size_mb = output_file.stat().st_size / (1024 * 1024)
    print(f"  Bementve:   {', '.join(included)}")
    if skipped:
        print(f"  Kihagyva:   {', '.join(skipped)}")
    present_caches = [c for c in sorted(CACHE_DIRS) if (install_dir / c).exists()]
    if present_caches:
        print(f"  Cache (csak mappa, tartalom nélkül):")
        for c in present_caches:
            print(f"    {c}/")
    print(f"  Méret:      {size_mb:.1f} MB")
    print(f"  Fájl:       {output_file.resolve()}")
    print("  Kész.\n")


# ── restore ───────────────────────────────────────────────────────────────────

def do_restore(backup_file: Path, target_dir: Path | None = None) -> None:
    _warn_not_root()

    if not backup_file.exists():
        print(f"\n  HIBA: A backup fájl nem található: {backup_file}")
        sys.exit(1)

    if not tarfile.is_tarfile(backup_file):
        print(f"\n  HIBA: Nem érvényes tar.gz fájl: {backup_file}")
        sys.exit(1)

    if target_dir is None:
        target_dir = _find_install_dir()

    print(f"\n  Visszaállítás innen: {backup_file.resolve()}")
    print(f"  Célkönyvtár:         {target_dir.resolve()}")

    with tarfile.open(backup_file, "r:gz") as tar:
        members = tar.getnames()

    has_env  = ".env" in members
    has_data = any(m == "data" or m.startswith("data/") for m in members)
    contents = []
    if has_env:
        contents.append(".env")
    if has_data:
        contents.append("data/")
    print(f"  Tartalom:            {', '.join(contents) or '(üres)'}")

    existing = []
    if has_env  and (target_dir / ".env").exists():
        existing.append(".env")
    if has_data and (target_dir / "data").is_dir():
        existing.append("data/")

    if existing:
        print(f"\n  FIGYELEM: A következők felülíródnak: {', '.join(existing)}")
        confirm = ask("Folytatod? (igen/nem)", "nem")
        if confirm.lower() not in ("igen", "i", "yes", "y"):
            print("  Megszakítva.\n")
            sys.exit(0)

    target_dir.mkdir(parents=True, exist_ok=True)

    with tarfile.open(backup_file, "r:gz") as tar:
        if sys.version_info >= (3, 12):
            tar.extractall(target_dir, filter="data")
        else:
            tar.extractall(target_dir)

    print(f"  Visszaállítva ide: {target_dir.resolve()}")
    if has_env:
        print("  .env visszaállítva")
    if has_data:
        print("  data/ visszaállítva")
    print("  Kész.\n")
    print("  Következő lépés: indítsd újra a konténereket.")
    print("  Pl.: docker compose up -d\n")


# ── interactive ───────────────────────────────────────────────────────────────

def interactive() -> None:
    print("\n─── QuorumAI Backup / Restore ───\n")
    _warn_not_root()
    install_dir = _find_install_dir()
    print(f"  Telepítési mappa: {install_dir.resolve()}")

    env_ok   = (install_dir / ".env").exists()
    data_ok  = (install_dir / "data").is_dir()
    print(f"  .env:             {'✓' if env_ok  else '✗ nem található'}")
    print(f"  data/:            {'✓' if data_ok else '✗ nem található'}")

    print("\n  1) Backup készítése")
    print("  2) Visszaállítás (restore)")
    print("  3) Kilépés")

    choice = ask("\nVálasztás", "1")
    print()

    if choice == "1":
        out_raw = ask("Kimeneti fájl neve (Enter = automatikus időbélyeg)", "")
        output_file = Path(out_raw) if out_raw else None
        do_backup(install_dir, output_file)

    elif choice == "2":
        f_raw = ask("Backup fájl elérési útja")
        if not f_raw:
            print("  Nincs megadva fájl.\n")
            sys.exit(1)
        d_raw = ask(f"Célkönyvtár (Enter = {install_dir})", "")
        target = Path(d_raw) if d_raw else install_dir
        do_restore(Path(f_raw), target)

    else:
        sys.exit(0)


# ── main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    args = sys.argv[1:]

    if not args:
        interactive()
        return

    cmd = args[0].lower()

    if cmd == "backup":
        install_dir = _find_install_dir()
        output = Path(args[1]) if len(args) > 1 else None
        do_backup(install_dir, output)

    elif cmd == "restore":
        if len(args) < 2:
            print("Használat: python3 backup.py restore <file.tgz> [célkönyvtár]")
            sys.exit(1)
        backup_file = Path(args[1])
        target = Path(args[2]) if len(args) > 2 else None
        do_restore(backup_file, target)

    else:
        print(f"Ismeretlen parancs: {cmd}")
        print("Használat: python3 backup.py [backup|restore] ...")
        sys.exit(1)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nMegszakítva.")
        sys.exit(0)
