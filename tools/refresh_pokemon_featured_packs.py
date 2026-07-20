"""Refresh Pokémon featured packs: careful checker knockout + 500x820."""
from __future__ import annotations

import collections
from pathlib import Path

from PIL import Image

SRC_DIR = Path(
    r"C:\Users\Tom\.cursor\projects\c-Users-Tom-AndroidStudioProjects-cardflip\assets"
)
DEST_DIR = Path(
    r"C:\Users\Tom\AndroidStudioProjects\cardflip\assets\featured_packs\pokemon"
)

# New art batch (id fragment → tier file)
SOURCES = {
    "da55cc0e": "pack_common.png",  # green
    "3773e435": "pack_uncommon.png",  # blue
    "1d0243a6": "pack_rare.png",  # purple
    "cd6dd9a2": "pack_epic.png",  # orange
    "8815d6cd": "pack_legendary.png",  # gold
    "2a8ca1cb": "pack_mythic.png",  # red
}

OUT_W, OUT_H = 500, 820


def find_src(key: str) -> Path:
    hits = list(SRC_DIR.glob(f"*{key}*.png"))
    if not hits:
        raise FileNotFoundError(key)
    return hits[0]


def is_checker_bg(r: int, g: int, b: int, a: int) -> bool:
    """True only for typical transparency-grid cells (gray/white, low chroma)."""
    if a < 8:
        return True
    chroma = max(r, g, b) - min(r, g, b)
    # Keep colored pack pixels (green/blue/red/etc.) — never treat as bg.
    if chroma > 14:
        return False
    avg = (r + g + b) / 3.0
    # Classic checker: light gray (~204) or mid gray (~128) or near-white.
    if avg >= 118:
        return True
    # Near-black backdrop sometimes used instead of checker.
    if avg <= 22:
        return True
    return False


def knock_checker_safe(im: Image.Image) -> Image.Image:
    """Flood-fill ONLY from edges so interior pack art is never eaten."""
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    visited = [[False] * h for _ in range(w)]
    q: collections.deque[tuple[int, int]] = collections.deque()

    def seed(x: int, y: int) -> None:
        if not (0 <= x < w and 0 <= y < h) or visited[x][y]:
            return
        r, g, b, a = px[x, y]
        if is_checker_bg(r, g, b, a):
            visited[x][y] = True
            q.append((x, y))

    for x in range(w):
        seed(x, 0)
        seed(x, h - 1)
    for y in range(h):
        seed(0, y)
        seed(w - 1, y)

    while q:
        x, y = q.popleft()
        px[x, y] = (0, 0, 0, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not visited[nx][ny]:
                r, g, b, a = px[nx, ny]
                if is_checker_bg(r, g, b, a):
                    visited[nx][ny] = True
                    q.append((nx, ny))

    # One-pixel soft fringe: only low-chroma gray next to transparent.
    # Do NOT clear saturated color (pack body / serrations / rays).
    for x in range(w):
        for y in range(h):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            chroma = max(r, g, b) - min(r, g, b)
            avg = (r + g + b) / 3.0
            if chroma > 12 or avg < 130:
                continue
            touch = False
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] == 0:
                    touch = True
                    break
            if touch:
                # Fade rather than hard-delete if slightly tinted.
                px[x, y] = (0, 0, 0, 0)

    bbox = im.getbbox()
    if bbox:
        pad = 4
        l, t, r, b = bbox
        im = im.crop(
            (
                max(0, l - pad),
                max(0, t - pad),
                min(w, r + pad),
                min(h, b + pad),
            )
        )
    return im


def fit_canvas(im: Image.Image, tw: int, th: int) -> Image.Image:
    """Scale pack to fit inside tw×th, centered, transparent pad — no stretch."""
    im = im.convert("RGBA")
    w, h = im.size
    scale = min(tw / w, th / h)
    nw = max(1, int(round(w * scale)))
    nh = max(1, int(round(h * scale)))
    resized = im.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    ox = (tw - nw) // 2
    oy = (th - nh) // 2
    canvas.paste(resized, (ox, oy), resized)
    return canvas


def main() -> None:
    DEST_DIR.mkdir(parents=True, exist_ok=True)
    for key, dest_name in SOURCES.items():
        src = find_src(key)
        cut = knock_checker_safe(Image.open(src))
        out = fit_canvas(cut, OUT_W, OUT_H)
        dest = DEST_DIR / dest_name
        out.save(dest, "PNG", optimize=True)
        px = out.load()
        corners = [
            px[0, 0][3],
            px[OUT_W - 1, 0][3],
            px[0, OUT_H - 1][3],
            px[OUT_W - 1, OUT_H - 1][3],
        ]
        # Sample center should be opaque pack art.
        mid = px[OUT_W // 2, OUT_H // 2]
        print(
            f"{dest_name}: {src.name[-40:]} "
            f"cut={cut.size} out={out.size} cornersA={corners} mid={mid}"
        )
    print("DONE")


if __name__ == "__main__":
    main()
