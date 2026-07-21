#!/usr/bin/env python3
"""Generate navy/gold One Piece featured pack PNGs by tinting Pokémon packs."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "featured_packs" / "pokemon"
OUT = ROOT / "assets" / "featured_packs" / "onepiece"

# Navy / gold accent shifts per tier (multiply RGB).
TINTS = {
    "common": (0.35, 0.45, 0.75),
    "uncommon": (0.30, 0.50, 0.85),
    "rare": (0.55, 0.45, 0.25),  # warmer gold
    "epic": (0.25, 0.35, 0.70),
    "legendary": (0.45, 0.35, 0.20),
    "mythic": (0.55, 0.42, 0.18),
}


def tint(im: Image.Image, mul: tuple[float, float, float]) -> Image.Image:
    rgba = im.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            # Preserve near-white highlights, push body toward navy/gold.
            lum = (r + g + b) / 3
            if lum > 220:
                continue
            nr = min(255, int(r * mul[0] + 40 * (1 if mul[0] > 0.5 else 0)))
            ng = min(255, int(g * mul[1] + 30 * (1 if mul[1] > 0.4 else 0)))
            nb = min(255, int(b * mul[2] + 50 * (1 if mul[2] > 0.6 else 0)))
            # Gold fleck on brighter midtones for rare+
            if mul[0] > 0.5 and 80 < lum < 200:
                nr = min(255, int(nr * 0.7 + 180 * 0.3))
                ng = min(255, int(ng * 0.7 + 150 * 0.3))
                nb = min(255, int(nb * 0.7 + 40 * 0.3))
            px[x, y] = (nr, ng, nb, a)
    return rgba


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    for tier, mul in TINTS.items():
        src = SRC / f"pack_{tier}.png"
        if not src.exists():
            print(f"missing {src}")
            continue
        out = OUT / f"pack_{tier}.png"
        tint(Image.open(src), mul).save(out)
        print(f"wrote {out.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
