#!/usr/bin/env python3
"""Generate sample PNG fixtures from base64 text files.
Run this in tests/fixtures when binary files are not stored in VCS.
"""
from pathlib import Path
import base64

ROOT = Path(__file__).resolve().parent
for stem in ["sample_texture", "sample_uv_guide"]:
    b64_path = ROOT / f"{stem}.png.base64"
    out_path = ROOT / f"{stem}.png"
    data = base64.b64decode(b64_path.read_text().strip())
    out_path.write_bytes(data)
    print(f"wrote {out_path}")
