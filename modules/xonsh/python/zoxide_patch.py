#!/usr/bin/env python3
"""
Rewrite xontrib-zoxide cache path so it falls back to ~/.cache when the store
location is not writable. This runs during the postPatch phase.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: zoxide_patch.py <path-to-zoxide.py>")

    target_path = Path(sys.argv[1])
    if not target_path.exists():
        raise SystemExit(f"xontrib-zoxide patch: {target_path} does not exist")

    text = target_path.read_text()
    original = (
        "  else:\n"
        "    z_cache_path\t= Path(os.path.dirname(__file__)).parent / _cache_name\n"
        "  sys.path.append(str(z_cache_path.parent))\n"
    )

    if original not in text:
        # Already patched or upstream changed – be tolerant.
        return

    replacement = (
        "  else:\n"
        "    z_cache_path = Path(os.path.dirname(__file__)).parent / _cache_name\n"
        "    if not z_cache_path.parent.exists() or not os.access(z_cache_path.parent, os.W_OK):\n"
        "      z_cache_path = Path.home() / \".cache\" / \"xontrib-zoxide\" / _cache_name\n"
        "      z_cache_path.parent.mkdir(exist_ok=True, parents=True)\n"
        "  sys.path.append(str(z_cache_path.parent))\n"
    )

    target_path.write_text(text.replace(original, replacement, 1))


if __name__ == "__main__":
    main()
