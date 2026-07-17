#!/usr/bin/env python3
"""Build featured-pack PNGs from a single Grok pack template.

- Knock out checkerboard / studio background
- Recolor foil body per rarity via luminance colorize (Rare Candy–style)
- Preserve near-black logos/text
- Fit to existing featured pack canvas (832x1248)
"""

from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "featured_packs"
TARGET_W, TARGET_H = 832, 1248

# Rare Candy–style foil palettes (shadow → mid → highlight), aligned with
# FeaturedPackTier.bloomColors in lib/data/featured_packs.dart.
TIERS: dict[str, dict[str, tuple[int, int, int]]] = {
    "common": {
        "shadow": (12, 70, 32),
        "mid": (22, 163, 74),  # #16A34A
        "hi": (134, 239, 172),  # #86EFAC
    },
    "uncommon": {
        "shadow": (8, 60, 72),
        "mid": (14, 116, 144),  # #0E7490
        "hi": (103, 232, 249),  # #67E8F9
    },
    "rare": {
        "shadow": (120, 60, 10),
        "mid": (249, 115, 22),  # #F97316
        "hi": (253, 230, 138),  # #FDE68A
    },
    "epic": {
        "shadow": (50, 16, 90),
        "mid": (124, 58, 237),  # #7C3AED
        "hi": (233, 213, 255),  # #E9D5FF
    },
    "legendary": {
        "shadow": (70, 12, 18),
        "mid": (185, 28, 40),  # deep crimson
        "hi": (212, 175, 55),  # #D4AF37 gold highlight
    },
    "mythic": {
        "shadow": (70, 20, 90),
        "mid": (192, 132, 252),  # #C084FC
        "hi": (103, 232, 249),  # cyan prism highlight
    },
}


def _is_checker_or_gray(r: np.ndarray, g: np.ndarray, b: np.ndarray) -> np.ndarray:
    mx = np.maximum(np.maximum(r, g), b)
    mn = np.minimum(np.minimum(r, g), b)
    chroma = mx - mn
    mean = (r.astype(np.float32) + g + b) / 3.0
    return (chroma < 22) & (mean > 165) & (mean < 252)


def knockout_background(rgb: Image.Image) -> Image.Image:
    arr = np.asarray(rgb.convert("RGB"), dtype=np.uint8)
    h, w, _ = arr.shape
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]
    bg = _is_checker_or_gray(r, g, b)

    visited = np.zeros((h, w), dtype=bool)
    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        for y in (0, h - 1):
            if bg[y, x]:
                visited[y, x] = True
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if bg[y, x] and not visited[y, x]:
                visited[y, x] = True
                q.append((x, y))

    while q:
        x, y = q.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and not visited[ny, nx] and bg[ny, nx]:
                visited[ny, nx] = True
                q.append((nx, ny))

    kill = visited.copy()
    for _ in range(3):
        pad = np.pad(kill, 1, constant_values=False)
        neigh = (
            pad[0:-2, 1:-1]
            | pad[2:, 1:-1]
            | pad[1:-1, 0:-2]
            | pad[1:-1, 2:]
        )
        kill = kill | (neigh & bg)

    alpha = np.where(kill, 0, 255).astype(np.uint8)
    # Extra pass: any leftover near-gray with low chroma → transparent.
    fringe = _is_checker_or_gray(r, g, b) & (alpha > 0)
    alpha = np.where(fringe, 0, alpha)
    return Image.fromarray(np.dstack([r, g, b, alpha]), "RGBA")


def _lerp(a: np.ndarray, b: np.ndarray, t: np.ndarray) -> np.ndarray:
    t3 = t[..., None]
    return a * (1.0 - t3) + b * t3


def recolor_foil(rgba: Image.Image, palette: dict[str, tuple[int, int, int]]) -> Image.Image:
    """Map foil luminance onto rarity palette; keep black ink logos/text."""
    arr = np.asarray(rgba, dtype=np.uint8)
    rgb = arr[..., :3].astype(np.float32)
    a = arr[..., 3]

    luma = (
        0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]
    )
    # Near-black ink (Poké Ball outline, POWERED BY / BINDORA).
    is_ink = (luma < 48) & (a > 20)
    foil = (a > 20) & (~is_ink)

    shadow = np.array(palette["shadow"], dtype=np.float32)
    mid = np.array(palette["mid"], dtype=np.float32)
    hi = np.array(palette["hi"], dtype=np.float32)

    # Normalize luma on foil body.
    foil_luma = luma[foil]
    lo = float(np.percentile(foil_luma, 5))
    hi_l = float(np.percentile(foil_luma, 95))
    span = max(1.0, hi_l - lo)
    t = np.clip((luma - lo) / span, 0.0, 1.0)

    # Two-segment gradient: shadow→mid (0–0.55), mid→hi (0.55–1).
    out = rgb.copy()
    t_foil = t[foil]
    low = t_foil <= 0.55
    high = ~low
    t_low = np.clip(t_foil[low] / 0.55, 0.0, 1.0)
    t_high = np.clip((t_foil[high] - 0.55) / 0.45, 0.0, 1.0)

    colored = np.zeros((foil_luma.shape[0], 3), dtype=np.float32)
    colored[low] = _lerp(
        np.broadcast_to(shadow, (t_low.shape[0], 3)),
        np.broadcast_to(mid, (t_low.shape[0], 3)),
        t_low,
    )
    colored[high] = _lerp(
        np.broadcast_to(mid, (t_high.shape[0], 3)),
        np.broadcast_to(hi, (t_high.shape[0], 3)),
        t_high,
    )

    # Keep a hint of original foil variation (crinkle / iridescence).
    orig = rgb[foil]
    mix = 0.88
    blended = colored * mix + orig * (1.0 - mix)

    # Mythic / rare: add mild secondary tint from original chroma bands.
    name_hint = palette.get("_name", "")
    if name_hint in {"mythic", "rare", "epic"}:
        # Boost highlights toward secondary hi color already in palette.
        pass

    out_rgb = arr[..., :3].copy()
    out_rgb[foil] = np.clip(blended, 0, 255).astype(np.uint8)
    # Ink stays original black.
    out_rgb[is_ink] = arr[..., :3][is_ink]

    return Image.fromarray(np.dstack([out_rgb, a]), "RGBA")


def fit_canvas(im: Image.Image, tw: int = TARGET_W, th: int = TARGET_H) -> Image.Image:
    im = im.convert("RGBA")
    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)

    max_w, max_h = int(tw * 0.92), int(th * 0.96)
    scale = min(max_w / im.width, max_h / im.height)
    nw, nh = max(1, int(im.width * scale)), max(1, int(im.height * scale))
    im = im.resize((nw, nh), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    canvas.paste(im, ((tw - nw) // 2, (th - nh) // 2), im)
    return canvas


def find_template() -> Path:
    assets = Path(
        r"C:\Users\Tom\.cursor\projects\c-Users-Tom-AndroidStudioProjects-cardflip\assets"
    )
    candidates = list(assets.glob("**/*grok-image-*85803dd2c275.png"))
    if not candidates:
        candidates = list((ROOT / "tools").rglob("*featured*template*.png"))
    if not candidates:
        raise SystemExit("Template image not found")
    return max(candidates, key=lambda p: p.stat().st_mtime)


def main() -> int:
    src = find_template()
    print("template:", src)

    cut = knockout_background(Image.open(src))
    OUT.mkdir(parents=True, exist_ok=True)

    for name, palette in TIERS.items():
        tinted = recolor_foil(cut, palette)
        final = fit_canvas(tinted)
        out_path = OUT / f"pack_{name}.png"
        final.save(out_path, "PNG", optimize=True)

        # Quick mean RGB of foil for sanity.
        a = np.asarray(final)
        rgb = a[..., :3].astype(np.float32)
        alpha = a[..., 3]
        luma = 0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]
        m = (alpha > 200) & (luma > 50) & (luma < 240)
        mean = rgb[m].mean(axis=0) if m.any() else (0, 0, 0)
        print(
            f"  wrote {out_path.name} {final.size} "
            f"meanRGB=({mean[0]:.0f},{mean[1]:.0f},{mean[2]:.0f}) "
            f"corner={final.getpixel((0, 0))}"
        )
    print("done")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
