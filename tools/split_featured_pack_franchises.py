#!/usr/bin/env python3
"""Split featured-pack art by franchise.

Pokémon  → assets/featured_packs/pokemon/  (Bindora template, rarity tints)
Riftbound → assets/featured_packs/riftbound/ (same foil body + orange swirl + RIP PACK)
"""

from __future__ import annotations

import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

# Reuse template knockout / colorize from sibling module.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from gen_featured_packs_from_template import (  # noqa: E402
    TIERS,
    fit_canvas,
    find_template,
    knockout_background,
    recolor_foil,
)

ROOT = Path(__file__).resolve().parents[1]
OUT_ROOT = ROOT / "assets" / "featured_packs"
LOGO = ROOT / "assets" / "logos" / "riftbound.png"
TARGET_W, TARGET_H = 832, 1248


def _font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    candidates = [
        "arialbd.ttf" if bold else "arial.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/seguiemj.ttf",
    ]
    for name in candidates:
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def _paste_swirl(pack: Image.Image, logo: Image.Image) -> Image.Image:
    """Composite orange swirl over the center mark area."""
    out = pack.copy()
    mark_h = int(pack.height * 0.42)
    logo = logo.convert("RGBA")
    bbox = logo.getbbox()
    if bbox:
        logo = logo.crop(bbox)
    scale = mark_h / logo.height
    nw, nh = max(1, int(logo.width * scale)), max(1, int(logo.height * scale))
    logo = logo.resize((nw, nh), Image.Resampling.LANCZOS)
    ox = (pack.width - nw) // 2
    oy = int(pack.height * 0.36) - nh // 2
    out.alpha_composite(logo, (ox, oy))
    return out


def _stamp_rip_pack(pack: Image.Image) -> Image.Image:
    """Cover Bindora wordmark region and draw POWERED BY / RIP PACK."""
    out = pack.copy()
    arr = np.asarray(out)
    h, w = arr.shape[:2]
    # Wider wipe covering POWERED BY + BINDORA.
    y0, y1 = int(h * 0.76), int(h * 0.94)
    x0, x1 = int(w * 0.36), int(w * 0.94)
    region = arr[y0:y1, x0:x1]
    opaque = region[..., 3] > 200
    if opaque.any():
        mean = region[opaque][..., :3].mean(axis=0).astype(np.uint8)
    else:
        mean = np.array([180, 120, 40], dtype=np.uint8)
    wipe = Image.new("RGBA", (x1 - x0, y1 - y0), (*mean.tolist(), 255))
    out.paste(wipe, (x0, y0))

    draw = ImageDraw.Draw(out)
    font_sm = _font(20, bold=False)
    font_md = _font(34, bold=True)
    tx = int(w * 0.42)
    ty = int(h * 0.805)
    draw.text((tx, ty), "POWERED BY", fill=(25, 20, 15, 235), font=font_sm)
    draw.text((tx, ty + 24), "RIP PACK", fill=(15, 10, 8, 255), font=font_md)
    return out


def _cover_pokeball(pack: Image.Image) -> Image.Image:
    """Soft-fill the black poké-ball outline before placing the swirl."""
    out = pack.copy()
    arr = np.asarray(out).copy()
    h, w = arr.shape[:2]
    cy, cx = int(h * 0.36), w // 2
    yy, xx = np.ogrid[:h, :w]
    dist = np.sqrt((yy - cy) ** 2 + (xx - cx) ** 2)
    r = int(min(w, h) * 0.28)
    mask = (dist <= r) & (arr[..., 3] > 20)
    # Also kill near-black ink strokes in a slightly larger disk.
    ink = mask & (arr[..., 0] < 55) & (arr[..., 1] < 55) & (arr[..., 2] < 55)
    ring = (dist > r * 0.9) & (dist < r * 1.35) & (arr[..., 3] > 200)
    if ring.any():
        mean = arr[ring][..., :3].mean(axis=0)
    else:
        mean = np.array([200, 140, 60], dtype=np.float32)
    fill_mask = mask | ink
    for c in range(3):
        channel = arr[..., c].astype(np.float32)
        channel[fill_mask] = mean[c]
        arr[..., c] = np.clip(channel, 0, 255).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def build_franchise(franchise: str) -> None:
    src = find_template()
    print("template:", src)
    cut = knockout_background(Image.open(src))
    logo = Image.open(LOGO) if LOGO.exists() else None

    out_dir = OUT_ROOT / franchise
    out_dir.mkdir(parents=True, exist_ok=True)

    for name, palette in TIERS.items():
        tinted = recolor_foil(cut, palette)
        final = fit_canvas(tinted)
        if franchise == "riftbound":
            final = _cover_pokeball(final)
            if logo is not None:
                final = _paste_swirl(final, logo)
            final = _stamp_rip_pack(final)
        path = out_dir / f"pack_{name}.png"
        final.save(path, "PNG", optimize=True)
        print(f"  {franchise}/{path.name} {final.size} corner={final.getpixel((0,0))}")


def migrate_flat_to_pokemon() -> None:
    """If flat pack_*.png still exist at root, move them into pokemon/."""
    pokemon = OUT_ROOT / "pokemon"
    pokemon.mkdir(parents=True, exist_ok=True)
    for p in OUT_ROOT.glob("pack_*.png"):
        dest = pokemon / p.name
        if not dest.exists():
            shutil.move(str(p), str(dest))
            print("moved", p.name, "-> pokemon/")
        else:
            p.unlink()
            print("removed stale", p.name)


def main() -> int:
    migrate_flat_to_pokemon()
    only = None
    if len(sys.argv) > 1:
        only = sys.argv[1].strip().lower()
    if only in (None, "all", "pokemon"):
        build_franchise("pokemon")
    if only in (None, "all", "riftbound"):
        build_franchise("riftbound")
    print("done")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
