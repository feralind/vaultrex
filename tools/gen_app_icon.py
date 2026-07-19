#!/usr/bin/env python3
"""Generate Vaultrex app icon: black rounded square + bold white B."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT_LOGO = ROOT / "assets" / "logos" / "app_icon.png"
ANDROID = ROOT / "android" / "app" / "src" / "main" / "res"

# Android launcher densities
MIPMAPS = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in (
        "C:/Windows/Fonts/arialbd.ttf",
        "C:/Windows/Fonts/segoeuib.ttf",
        "C:/Windows/Fonts/calibrib.ttf",
        "arialbd.ttf",
    ):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def make_icon(size: int) -> Image.Image:
    """Black fill, rounded border, centered bold B."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Rounded square with slight inset so adaptive icons don't clip.
    pad = max(1, size // 32)
    radius = int(size * 0.22)
    box = [pad, pad, size - pad - 1, size - pad - 1]

    # Fill
    draw.rounded_rectangle(box, radius=radius, fill=(8, 8, 10, 255))
    # Clean light border ring
    border = max(1, size // 28)
    draw.rounded_rectangle(
        box,
        radius=radius,
        outline=(235, 235, 240, 255),
        width=border,
    )

    font = _font(int(size * 0.62))
    text = "B"
    # Center glyph
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (size - tw) / 2 - bbox[0]
    y = (size - th) / 2 - bbox[1] - size * 0.02
    draw.text((x, y), text, font=font, fill=(255, 255, 255, 255))
    return img


def main() -> int:
    OUT_LOGO.parent.mkdir(parents=True, exist_ok=True)
    hi = make_icon(1024)
    hi.save(OUT_LOGO, "PNG", optimize=True)
    print("wrote", OUT_LOGO, hi.size)

    for folder, px in MIPMAPS.items():
        dest_dir = ANDROID / folder
        dest_dir.mkdir(parents=True, exist_ok=True)
        icon = make_icon(px)
        path = dest_dir / "ic_launcher.png"
        icon.convert("RGBA").save(path, "PNG", optimize=True)
        print("wrote", path, px)

    # Also drop a web/favicon-friendly copy under assets/logos.
    make_icon(512).save(OUT_LOGO.parent / "app_icon_512.png", "PNG", optimize=True)
    print("done")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
