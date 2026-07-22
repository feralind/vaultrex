"""Build crisp, optically-centered Bindora launcher icons.

User pick: classic #1 — white B on near-black charcoal.
Adaptive: dark plate + white B foreground (safe-zone inset).
Also writes legacy full-bleed mipmaps and a white notification silhouette.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "android" / "app" / "src" / "main" / "res"
ASSETS = ROOT / "assets" / "logos"
MOCKS = ROOT / "assets" / "logos" / "icon_mockups"

# Adaptive foreground canvas is 108dp; safe zone ~66% (~72dp) centered.
FG_SIZE = 1024
SAFE = 0.66  # fraction of canvas for glyph

# Classic charcoal (matches mockup 1)
BG = (18, 18, 18, 255)  # #121212
FG_B = (255, 255, 255, 255)

SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def load_font(px: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in (
        "C:/Windows/Fonts/arialbd.ttf",
        "C:/Windows/Fonts/segoeuib.ttf",
        "C:/Windows/Fonts/Bahnschrift.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    ):
        try:
            return ImageFont.truetype(path, px)
        except OSError:
            continue
    return ImageFont.load_default()


def draw_centered_b(
    size: int,
    *,
    fill: tuple[int, int, int, int],
    bg: tuple[int, int, int, int] | None = None,
    inset_frac: float = SAFE,
) -> Image.Image:
    """Render a perfectly centered B with optical vertical nudge."""
    im = Image.new("RGBA", (size, size), bg or (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    box = int(size * inset_frac)
    font_px = int(box * 0.78)
    font = load_font(font_px)
    text = "B"
    bbox = d.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (size - tw) / 2 - bbox[0]
    y = (size - th) / 2 - bbox[1] + size * 0.012
    d.text((x, y), text, font=font, fill=fill)
    return im


def save_resized(im: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.resize((size, size), Image.Resampling.LANCZOS).save(path, "PNG")
    print(f"wrote {path.relative_to(ROOT)} ({size})")


def main() -> int:
    ASSETS.mkdir(parents=True, exist_ok=True)
    MOCKS.mkdir(parents=True, exist_ok=True)

    # Master: white B on transparent (adaptive foreground)
    fg = draw_centered_b(FG_SIZE, fill=FG_B, inset_frac=0.62)
    # Full icon: charcoal circle + white B
    full = Image.new("RGBA", (FG_SIZE, FG_SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(full)
    pad = int(FG_SIZE * 0.02)
    d.ellipse(
        [pad, pad, FG_SIZE - 1 - pad, FG_SIZE - 1 - pad],
        fill=BG,
    )
    full.alpha_composite(fg)

    master = ASSETS / "bindora_icon_master.png"
    full.save(master, "PNG")
    full.save(MOCKS / "icon_mockup_1_classic.png", "PNG")
    fg.save(ASSETS / "bindora_icon_foreground.png", "PNG")
    print(f"wrote {master.relative_to(ROOT)}")

    for folder, size in SIZES.items():
        save_resized(fg, RES / folder / "ic_launcher_foreground.png", size)
        save_resized(full, RES / folder / "ic_launcher.png", size)
        save_resized(full, RES / folder / "ic_launcher_round.png", size)

    # Notification small icon: white silhouette on transparent
    notif = draw_centered_b(96, fill=FG_B, inset_frac=0.72)
    notif_dir = RES / "drawable"
    notif_dir.mkdir(parents=True, exist_ok=True)
    notif.save(notif_dir / "ic_stat_bindora.png", "PNG")
    print("wrote drawable/ic_stat_bindora.png")

    save_resized(full, ASSETS / "app_icon_512.png", 512)
    save_resized(full, ASSETS / "app_icon.png", 192)
    save_resized(full, ASSETS / "bindora.png", 512)

    colors = RES / "values" / "colors.xml"
    colors.write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#121212</color>
</resources>
""",
        encoding="utf-8",
    )
    print("updated ic_launcher_background to #121212")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
