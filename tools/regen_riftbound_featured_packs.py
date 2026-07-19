#!/usr/bin/env python3
"""Rebuild Riftbound featured packs WITHOUT the orange selection swirl.

Starts from Pokémon rarity foils, hard-wipes the center mark disk, stamps the
classic blue Riftbound wordmark + POWERED BY / RIP PACK.

Orange swirl (assets/logos/riftbound.png) stays on franchise selection only.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
POKE = ROOT / "assets" / "featured_packs" / "pokemon"
OUT = ROOT / "assets" / "featured_packs" / "riftbound"
WORDMARK = ROOT / "assets" / "logos" / "riftbound_wordmark.png"
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


def cover_center(pack: Image.Image, r_frac: float = 0.48) -> Image.Image:
    """Hard-fill the center mark disk so Poké Ball art is fully gone."""
    arr = np.asarray(pack.convert("RGBA")).copy()
    h, w = arr.shape[:2]
    cy, cx = int(h * 0.36), w // 2
    yy, xx = np.ogrid[:h, :w]
    dist = np.sqrt((yy - cy) ** 2 + (xx - cx) ** 2)
    r = int(min(w, h) * r_frac)
    ring = (
        (dist > r * 1.05)
        & (dist < r * 1.35)
        & (arr[..., 3] > 200)
        & (((arr[..., 0].astype(np.int16) + arr[..., 1] + arr[..., 2]) / 3) > 80)
    )
    mean = (
        arr[ring][..., :3].mean(axis=0)
        if ring.any()
        else np.array([200, 140, 60], dtype=np.float32)
    )
    disk = dist <= r
    for c in range(3):
        ch = arr[..., c].astype(np.float32)
        ch[disk & (arr[..., 3] > 10)] = mean[c]
        arr[..., c] = np.clip(ch, 0, 255).astype(np.uint8)
    return Image.fromarray(arr, "RGBA")


def wipe_rect(
    pack: Image.Image, y0f: float, y1f: float, x0f: float, x1f: float
) -> Image.Image:
    arr = np.asarray(pack.convert("RGBA"))
    h, w = arr.shape[:2]
    y0, y1 = int(h * y0f), int(h * y1f)
    x0, x1 = int(w * x0f), int(w * x1f)
    region = arr[y0:y1, x0:x1]
    opaque = region[..., 3] > 200
    if not opaque.any():
        return pack
    mean = region[opaque][..., :3].mean(axis=0).astype(np.uint8)
    out = pack.copy()
    wipe = Image.new("RGBA", (x1 - x0, y1 - y0), (*mean.tolist(), 255))
    out.paste(wipe, (x0, y0))
    return out


def paste_wordmark(pack: Image.Image, logo: Image.Image) -> Image.Image:
    out = pack.copy()
    logo = logo.convert("RGBA")
    bbox = logo.getbbox()
    if bbox:
        logo = logo.crop(bbox)
    mark_w = int(pack.width * 0.72)
    scale = mark_w / max(1, logo.width)
    nw, nh = max(1, int(logo.width * scale)), max(1, int(logo.height * scale))
    max_h = int(pack.height * 0.17)
    if nh > max_h:
        s2 = max_h / nh
        nw, nh = max(1, int(nw * s2)), max_h
    logo = logo.resize((nw, nh), Image.Resampling.LANCZOS)
    ox = (pack.width - nw) // 2
    oy = int(pack.height * 0.34) - nh // 2
    out.alpha_composite(logo, (ox, oy))
    return out


def stamp_rip_pack(pack: Image.Image) -> Image.Image:
    out = wipe_rect(pack, 0.76, 0.94, 0.02, 0.98)
    draw = ImageDraw.Draw(out)
    w, h = out.size
    tx, ty = int(w * 0.42), int(h * 0.805)
    draw.text((tx, ty), "POWERED BY", fill=(25, 20, 15, 235), font=_font(20))
    draw.text((tx, ty + 24), "RIP PACK", fill=(15, 10, 8, 255), font=_font(34, bold=True))
    return out


def main() -> int:
    if not (POKE / "pack_common.png").exists():
        print("missing pokemon rarity packs", file=sys.stderr)
        return 1
    if not WORDMARK.exists():
        print("missing", WORDMARK, file=sys.stderr)
        return 1

    OUT.mkdir(parents=True, exist_ok=True)
    logo = Image.open(WORDMARK)

    for tier in TIERS:
        src = Image.open(POKE / f"pack_{tier}.png").convert("RGBA")
        pack = cover_center(src)
        pack = paste_wordmark(pack, logo)
        pack = stamp_rip_pack(pack)
        dest = OUT / f"pack_{tier}.png"
        pack.save(dest, "PNG", optimize=True)
        print("wrote", dest.relative_to(ROOT))

    print("done — orange swirl left on selection logo only")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
