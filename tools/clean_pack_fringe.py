#!/usr/bin/env python3
"""Clean white/black fringe on already-cut TCGPlayer pack PNGs."""

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

PKM_IDS = [
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


def is_fringe_color(r: int, g: int, b: int, a: int) -> bool:
    if a < 12:
        return True
    mn, mx = min(r, g, b), max(r, g, b)
    chroma = mx - mn
    # Near-white junk left by storefront cutouts.
    if chroma <= 28 and mn >= 210:
        return True
    # Speckle black/gray fringe next to transparency.
    if chroma <= 20 and mx <= 40 and a < 240:
        return True
    return False


def clean_fringe(img: Image.Image, passes: int = 3) -> Image.Image:
    rgba = np.array(img.convert("RGBA"), dtype=np.uint8)
    h, w = rgba.shape[:2]

    # Seed flood from borders for fringe colors.
    studio = np.zeros((h, w), dtype=bool)
    for y in range(h):
        for x in range(w):
            r, g, b, a = map(int, rgba[y, x])
            studio[y, x] = is_fringe_color(r, g, b, a)

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

    # Extra edge choke: peel near-white pixels that touch transparency.
    for _ in range(passes):
        alpha = rgba[:, :, 3].copy()
        kill = []
        for y in range(h):
            for x in range(w):
                if alpha[y, x] < 20:
                    continue
                r, g, b, a = map(int, rgba[y, x])
                mn, mx = min(r, g, b), max(r, g, b)
                if not (mx - mn <= 30 and mn >= 200):
                    continue
                touch = False
                for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                    if 0 <= nx < w and 0 <= ny < h and alpha[ny, nx] < 20:
                        touch = True
                        break
                if touch or x < 2 or y < 2 or x >= w - 2 or y >= h - 2:
                    kill.append((x, y))
        for x, y in kill:
            rgba[y, x, 3] = 0

    out = Image.fromarray(rgba, "RGBA")
    bbox = out.getbbox()
    if bbox:
        l, t, r, b = bbox
        pad = 4
        out = out.crop(
            (max(0, l - pad), max(0, t - pad), min(out.width, r + pad), min(out.height, b + pad))
        )
    return out


def main() -> int:
    catalog = json.loads(
        (ROOT / "assets/data/pokemon_sealed.json").read_text(encoding="utf-8-sig")
    )
    by_id = {p["productId"]: p for p in catalog["products"]}
    for pid in PKM_IDS:
        p = by_id.get(pid)
        if not p:
            continue
        url = p.get("imageUrl") or ""
        print(f"clean {pid} {p.get('name','')[:48]}")
        req = urllib.request.Request(url, headers={"User-Agent": "VaultrexArtBot/1.0"})
        try:
            data = urllib.request.urlopen(req, timeout=30).read()
        except Exception as e:
            print("  fail", e)
            continue
        src = Image.open(io.BytesIO(data))
        cut = clean_fringe(src)
        out = SEALED / f"tcg_{pid}.png"
        cut.save(out, "PNG", optimize=True)
        corners = [cut.getpixel((0, 0)), cut.getpixel((cut.width - 1, 0))]
        print(" ", out.name, cut.size, corners)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
