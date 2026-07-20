"""Install Pokémon featured pack templates and knock out checkerboard BG."""
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

MAPPING = {
    "poke_common": "pack_common.png",
    "poke_uncommon": "pack_uncommon.png",
    "poke_rare": "pack_rare.png",
    "poke_epic": "pack_epic.png",
    "poke_legendary": "pack_legendary.png",
    "poke_mythic": "pack_mythic.png",
}


def find_src(key: str) -> Path:
    hits = list(SRC_DIR.glob(f"*{key}*.png"))
    if not hits:
        raise FileNotFoundError(key)
    return hits[0]


def is_checker(px, x: int, y: int) -> bool:
    r, g, b, _a = px[x, y]
    chroma = max(r, g, b) - min(r, g, b)
    if chroma > 18:
        return False
    avg = (r + g + b) / 3
    return avg >= 190 or 110 <= avg <= 185


def near_black(px, x: int, y: int) -> bool:
    r, g, b, _a = px[x, y]
    return r <= 24 and g <= 24 and b <= 24


def knock_checker(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()
    visited = [[False] * h for _ in range(w)]
    q: collections.deque[tuple[int, int]] = collections.deque()

    def try_seed(x: int, y: int, pred) -> None:
        if 0 <= x < w and 0 <= y < h and not visited[x][y] and pred(px, x, y):
            visited[x][y] = True
            q.append((x, y))

    for x in range(w):
        try_seed(x, 0, is_checker)
        try_seed(x, h - 1, is_checker)
        try_seed(x, 0, near_black)
        try_seed(x, h - 1, near_black)
    for y in range(h):
        try_seed(0, y, is_checker)
        try_seed(w - 1, y, is_checker)
        try_seed(0, y, near_black)
        try_seed(w - 1, y, near_black)

    while q:
        x, y = q.popleft()
        px[x, y] = (0, 0, 0, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not visited[nx][ny]:
                if is_checker(px, nx, ny) or near_black(px, nx, ny):
                    visited[nx][ny] = True
                    q.append((nx, ny))

    # Soften residual checker fringe next to transparent.
    for x in range(w):
        for y in range(h):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            chroma = max(r, g, b) - min(r, g, b)
            avg = (r + g + b) / 3
            if chroma <= 22 and 100 <= avg <= 255:
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] == 0:
                        px[x, y] = (0, 0, 0, 0)
                        break

    bbox = im.getbbox()
    if bbox:
        pad = 6
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


def main() -> None:
    DEST_DIR.mkdir(parents=True, exist_ok=True)
    for key, dest_name in MAPPING.items():
        src = find_src(key)
        out = knock_checker(Image.open(src))
        dest = DEST_DIR / dest_name
        out.save(dest, "PNG")
        p = out.load()
        ww, hh = out.size
        corners = [
            p[0, 0][3],
            p[ww - 1, 0][3],
            p[0, hh - 1][3],
            p[ww - 1, hh - 1][3],
        ]
        print(f"{dest_name}: {src.name} -> {ww}x{hh} cornerA={corners}")
    print("DONE")


if __name__ == "__main__":
    main()
