#!/usr/bin/env python3
"""Re-cut product photos with edge flood-fill (safer than rembg for light foil)."""

from __future__ import annotations

import io
import json
import urllib.request
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SEALED = ROOT / "assets" / "sealed"


def flood_knockout(
    img: Image.Image, threshold: int = 248, chroma_max: int = 18
) -> Image.Image:
    rgba = np.array(img.convert("RGBA"))
    h, w = rgba.shape[:2]
    r, g, b, a = rgba[:, :, 0], rgba[:, :, 1], rgba[:, :, 2], rgba[:, :, 3]
    mn = np.minimum(np.minimum(r, g), b)
    mx = np.maximum(np.maximum(r, g), b)
    studio = ((mx - mn) <= chroma_max) & (mn >= threshold) & (a >= 12)
    studio = studio | (a < 12)
    visited = np.zeros((h, w), dtype=np.uint8)
    q: deque[tuple[int, int]] = deque()

    def push(x: int, y: int) -> None:
        if x < 0 or y < 0 or x >= w or y >= h:
            return
        if visited[y, x]:
            return
        if not studio[y, x]:
            return
        visited[y, x] = 1
        q.append((x, y))

    for x in range(w):
        push(x, 0)
        push(x, h - 1)
    for y in range(h):
        push(0, y)
        push(w - 1, y)

    while q:
        x, y = q.popleft()
        rgba[y, x, 3] = 0
        push(x - 1, y)
        push(x + 1, y)
        push(x, y - 1)
        push(x, y + 1)

    soft = max(0, threshold - 10)
    alpha = rgba[:, :, 3].copy()
    for y in range(h):
        for x in range(w):
            if alpha[y, x] < 250:
                continue
            if (mx[y, x] - mn[y, x]) > chroma_max or mn[y, x] < soft:
                continue
            touch = False
            for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if 0 <= nx < w and 0 <= ny < h and alpha[ny, nx] < 20:
                    touch = True
                    break
            if touch:
                t = (mn[y, x] - soft) / max(1, threshold - soft)
                rgba[y, x, 3] = int(alpha[y, x] * (1 - min(1.0, float(t)) * 0.85))

    out = Image.fromarray(rgba, "RGBA")
    bbox = out.getbbox()
    if bbox:
        l, t, r, b = bbox
        pad = 6
        out = out.crop(
            (max(0, l - pad), max(0, t - pad), min(out.width, r + pad), min(out.height, b + pad))
        )
    return out


def main() -> int:
    # Pokemon ids previously cut with rembg (often over-aggressive on white foil).
    pkm_ids = [
        493975,
        493976,
        501256,
        501257,
        504467,
        543843,
        543846,
        565603,
        565604,
        565606,
        593294,
        649413,
        649421,
    ]
    catalog = json.loads(
        (ROOT / "assets/data/pokemon_sealed.json").read_text(encoding="utf-8-sig")
    )
    by_id = {p["productId"]: p for p in catalog["products"]}
    ok = 0
    for pid in pkm_ids:
        p = by_id.get(pid)
        if not p:
            print("missing catalog", pid)
            continue
        url = p.get("imageUrl") or ""
        name = p.get("name", "")[:48]
        print(f"reflood {pid} {name}")
        req = urllib.request.Request(url, headers={"User-Agent": "VaultrexArtBot/1.0"})
        try:
            data = urllib.request.urlopen(req, timeout=30).read()
        except Exception as e:
            print("  download fail", e)
            continue
        src = Image.open(io.BytesIO(data))
        cut = flood_knockout(src)
        out = SEALED / f"tcg_{pid}.png"
        cut.save(out, "PNG", optimize=True)
        corners = [cut.getpixel((0, 0)), cut.getpixel((cut.width - 1, 0))]
        print(" ", out.name, cut.size, "corners", corners)
        ok += 1
    print("done", ok)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
