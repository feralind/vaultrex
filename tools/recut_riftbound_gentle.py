#!/usr/bin/env python3
"""Re-cut Riftbound sealed arts from CDN with rembg + gentle fringe only."""

from __future__ import annotations

import io
import json
import urllib.request
from pathlib import Path

import numpy as np
from PIL import Image
from rembg import remove

from harden_sealed_alpha import (
    border_distance,
    choke_near_white_touching_clear,
    flood_clear,
    harden_alpha,
    light_gray_fringe,
    near_white_mask,
    prefer_1000,
)

ROOT = Path(__file__).resolve().parents[1]
SEALED = ROOT / "assets" / "sealed"


def gentle(img: Image.Image) -> Image.Image:
    rgba = np.array(img.convert("RGBA"))
    rgba = harden_alpha(rgba)
    h, w = rgba.shape[:2]
    dist = border_distance(h, w)
    fringe = near_white_mask(rgba, floor=235, chroma=18) | light_gray_fringe(rgba)
    rgba[:, :, 3] = np.where(fringe & (dist <= 8), 0, rgba[:, :, 3])
    clear = rgba[:, :, 3] < 12
    seed = clear | near_white_mask(rgba, floor=248, chroma=12)
    rgba = flood_clear(rgba, seed)
    rgba = choke_near_white_touching_clear(rgba, passes=2)
    rgba = harden_alpha(rgba)
    out = Image.fromarray(rgba, "RGBA")
    bb = out.getbbox()
    if bb:
        l, t, r, b = bb
        pad = 4
        out = out.crop(
            (max(0, l - pad), max(0, t - pad), min(out.width, r + pad), min(out.height, b + pad))
        )
    return out


def main() -> int:
    catalog = json.loads(
        (ROOT / "assets/data/sealed_products.json").read_text(encoding="utf-8-sig")
    )
    by = {int(p["productId"]): p for p in catalog["products"]}
    ids = sorted(
        {
            int(p.stem.split("_")[1])
            for p in SEALED.glob("tcg_*.png")
            if int(p.stem.split("_")[1]) in by
        }
    )
    print(f"re-cut riftbound sealed from CDN+rembg: {len(ids)}")
    ok = 0
    for i, pid in enumerate(ids, 1):
        name = (by[pid].get("name") or "")[:40]
        url = prefer_1000(by[pid].get("imageUrl") or "")
        print(f"[{i}/{len(ids)}] {pid} {name}")
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "VaultrexArtBot/1.0"})
            data = urllib.request.urlopen(req, timeout=35).read()
            cut = remove(data)
            out = gentle(Image.open(io.BytesIO(cut)))
            out.save(SEALED / f"tcg_{pid}.png", "PNG", optimize=True)
            print("  ok", out.size)
            ok += 1
        except Exception as e:
            print("  fail", e)
    print("done", ok)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
