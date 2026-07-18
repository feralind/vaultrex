#!/usr/bin/env python3
"""Refresh franchise featured-pack art from Pokémon Bindora rarity set.

- Pokémon: already Bindora template + rarity tints (leave as-is)
- MTG: same foil + rarity, Poké Ball covered, MTG mark centered
- Riftbound: same foil + rarity, swirl + RIP PACK (cleaner Poké Ball cover)
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "featured_packs"
LOGO_RB = ROOT / "assets" / "logos" / "riftbound.png"
TIERS = ["common", "uncommon", "rare", "epic", "legendary", "mythic"]


def _font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    for name in (
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
        "arialbd.ttf" if bold else "arial.ttf",
    ):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def cover_center_mark(pack: Image.Image, radius_frac: float = 0.30) -> Image.Image:
    """Fill the central black mark disk with surrounding foil color."""
    arr = np.asarray(pack.convert("RGBA")).copy()
    h, w = arr.shape[:2]
    cy, cx = int(h * 0.36), w // 2
    yy, xx = np.ogrid[:h, :w]
    dist = np.sqrt((yy - cy) ** 2 + (xx - cx) ** 2)
    r = int(min(w, h) * radius_frac)
    disk = dist <= r
    ring = (dist > r * 0.92) & (dist < r * 1.25) & (arr[..., 3] > 200)
    if ring.any():
        mean = arr[ring][..., :3].mean(axis=0)
    else:
        mean = np.array([180, 120, 50], dtype=np.float32)
    # Kill near-black ink inside / near the disk.
    ink = disk & (arr[..., 0] < 60) & (arr[..., 1] < 60) & (arr[..., 2] < 60) & (
        arr[..., 3] > 20
    )
    fill = disk | ink
    for c in range(3):
        ch = arr[..., c].astype(np.float32)
        ch[fill] = mean[c]
        arr[..., c] = np.clip(ch, 0, 255).astype(np.uint8)
    # Soften any leftover dark fringe.
    fringe = (dist <= r * 1.05) & (arr[..., 0] < 80) & (arr[..., 1] < 80) & (
        arr[..., 2] < 80
    ) & (arr[..., 3] > 20)
    for c in range(3):
        ch = arr[..., c].astype(np.float32)
        ch[fringe] = mean[c]
        arr[..., c] = np.clip(ch, 0, 255).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def paste_logo(pack: Image.Image, logo: Image.Image, height_frac: float = 0.38) -> Image.Image:
    out = pack.copy()
    logo = logo.convert("RGBA")
    bbox = logo.getbbox()
    if bbox:
        logo = logo.crop(bbox)
    mark_h = int(pack.height * height_frac)
    scale = mark_h / max(1, logo.height)
    # Cap width so wide banners don't overflow.
    max_w = int(pack.width * 0.62)
    nw, nh = max(1, int(logo.width * scale)), max(1, int(logo.height * scale))
    if nw > max_w:
        s2 = max_w / nw
        nw, nh = max_w, max(1, int(nh * s2))
    logo = logo.resize((nw, nh), Image.Resampling.LANCZOS)
    ox = (pack.width - nw) // 2
    oy = int(pack.height * 0.36) - nh // 2
    out.alpha_composite(logo, (ox, oy))
    return out


def paste_mtg_mark(pack: Image.Image) -> Image.Image:
    """Simple centered planeswalker-style diamond + MTG letters."""
    out = pack.copy()
    draw = ImageDraw.Draw(out)
    w, h = out.size
    cx, cy = w // 2, int(h * 0.36)
    s = int(min(w, h) * 0.16)
    diamond = [
        (cx, cy - s),
        (cx + int(s * 0.72), cy),
        (cx, cy + s),
        (cx - int(s * 0.72), cy),
    ]
    draw.polygon(diamond, fill=(15, 12, 10, 255))
    # Inner cut for foil peek.
    s2 = int(s * 0.45)
    inner = [
        (cx, cy - s2),
        (cx + int(s2 * 0.72), cy),
        (cx, cy + s2),
        (cx - int(s2 * 0.72), cy),
    ]
    # Sample foil under center for inner fill.
    px = out.getpixel((cx, cy - s - 8))
    fill = (px[0], px[1], px[2], 255) if px[3] > 200 else (220, 160, 60, 255)
    draw.polygon(inner, fill=fill)
    font = _font(max(22, w // 18), bold=True)
    text = "MTG"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text(
        (cx - tw // 2, cy + s + 8),
        text,
        fill=(20, 16, 12, 255),
        font=font,
    )
    return out


def stamp_rip_pack(pack: Image.Image) -> Image.Image:
    out = pack.copy()
    arr = np.asarray(out)
    h, w = arr.shape[:2]
    y0, y1 = int(h * 0.76), int(h * 0.94)
    x0, x1 = int(w * 0.36), int(w * 0.94)
    region = arr[y0:y1, x0:x1]
    opaque = region[..., 3] > 200
    mean = (
        region[opaque][..., :3].mean(axis=0).astype(np.uint8)
        if opaque.any()
        else np.array([180, 120, 40], dtype=np.uint8)
    )
    wipe = Image.new("RGBA", (x1 - x0, y1 - y0), (*mean.tolist(), 255))
    out.paste(wipe, (x0, y0))
    draw = ImageDraw.Draw(out)
    tx, ty = int(w * 0.42), int(h * 0.805)
    draw.text((tx, ty), "POWERED BY", fill=(25, 20, 15, 235), font=_font(20))
    draw.text((tx, ty + 24), "RIP PACK", fill=(15, 10, 8, 255), font=_font(34, bold=True))
    return out


def main() -> int:
    pokemon = OUT / "pokemon"
    if not (pokemon / "pack_common.png").exists():
        print("missing pokemon rarity packs", file=sys.stderr)
        return 1

    mtg_dir = OUT / "mtg"
    rb_dir = OUT / "riftbound"
    mtg_dir.mkdir(parents=True, exist_ok=True)
    rb_dir.mkdir(parents=True, exist_ok=True)
    rb_logo = Image.open(LOGO_RB) if LOGO_RB.exists() else None

    for tier in TIERS:
        src = Image.open(pokemon / f"pack_{tier}.png").convert("RGBA")

        # MTG
        mtg = cover_center_mark(src)
        mtg = paste_mtg_mark(mtg)
        mtg_path = mtg_dir / f"pack_{tier}.png"
        mtg.save(mtg_path, "PNG", optimize=True)
        print("wrote", mtg_path.relative_to(ROOT))

        # Riftbound
        rb = cover_center_mark(src, radius_frac=0.32)
        if rb_logo is not None:
            rb = paste_logo(rb, rb_logo, height_frac=0.40)
        rb = stamp_rip_pack(rb)
        rb_path = rb_dir / f"pack_{tier}.png"
        rb.save(rb_path, "PNG", optimize=True)
        print("wrote", rb_path.relative_to(ROOT))

    print("done — pokemon Bindora rarity set unchanged")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
