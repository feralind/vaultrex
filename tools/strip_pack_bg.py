"""Remove checkerboard / flat background outside a booster pack silhouette."""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image


def is_checker(r: int, g: int, b: int) -> bool:
    # Gray/white checker cells typically near-equal RGB, mid-to-high luminance.
    mx, mn = max(r, g, b), min(r, g, b)
    if mx - mn > 28:
        return False  # chromatic (pack blues)
    # white cell ~230-255, gray cell ~170-200
    avg = (r + g + b) / 3
    return avg >= 150


def flood_mask(im: Image.Image) -> Image.Image:
    """Flood-fill from edges through checker-like pixels → alpha mask."""
    w, h = im.size
    px = im.load()
    visited = [[False] * w for _ in range(h)]
    stack: list[tuple[int, int]] = []

    def try_push(x: int, y: int) -> None:
        if x < 0 or y < 0 or x >= w or y >= h or visited[y][x]:
            return
        r, g, b, a = px[x, y]
        if a < 8:
            visited[y][x] = True
            stack.append((x, y))
            return
        if is_checker(r, g, b):
            visited[y][x] = True
            stack.append((x, y))

    for x in range(w):
        try_push(x, 0)
        try_push(x, h - 1)
    for y in range(h):
        try_push(0, y)
        try_push(w - 1, y)

    while stack:
        x, y = stack.pop()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            try_push(nx, ny)

    out = Image.new("RGBA", (w, h))
    opx = out.load()
    for y in range(h):
        for x in range(w):
            if visited[y][x]:
                opx[x, y] = (0, 0, 0, 0)
            else:
                opx[x, y] = px[x, y]
    return out


def tight_crop(im: Image.Image, pad: int = 4) -> Image.Image:
    bbox = im.getbbox()
    if not bbox:
        return im
    l, t, r, b = bbox
    l = max(0, l - pad)
    t = max(0, t - pad)
    r = min(im.width, r + pad)
    b = min(im.height, b + pad)
    return im.crop((l, t, r, b))


def main() -> int:
    src = Path(sys.argv[1])
    dst = Path(sys.argv[2])
    im = Image.open(src).convert("RGBA")
    cleaned = flood_mask(im)
    cleaned = tight_crop(cleaned, pad=6)
    dst.parent.mkdir(parents=True, exist_ok=True)
    cleaned.save(dst, optimize=True)
    print(f"wrote {dst} size={cleaned.size}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
