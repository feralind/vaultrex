"""Resize classic Bindora icon into Android mipmaps + logo assets."""
from PIL import Image
from pathlib import Path

SRC = Path("assets/logos/icon_mockups/icon_mockup_1_classic.png")
ROOT = Path("android/app/src/main/res")

# Standard launcher sizes
SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

img = Image.open(SRC).convert("RGBA")

# Crop to content if needed — keep square. Soft pad for mask safety:
# Android adaptive masks clip corners; keep B inset already in art.

for folder, size in SIZES.items():
    out_dir = ROOT / folder
    out_dir.mkdir(parents=True, exist_ok=True)
    resized = img.resize((size, size), Image.Resampling.LANCZOS)
    out = out_dir / "ic_launcher.png"
    resized.save(out, "PNG")
    print(f"wrote {out} ({size}x{size})")

# App assets used in-app / web
img.resize((512, 512), Image.Resampling.LANCZOS).save(
    "assets/logos/app_icon_512.png", "PNG"
)
img.resize((192, 192), Image.Resampling.LANCZOS).save(
    "assets/logos/app_icon.png", "PNG"
)
img.resize((512, 512), Image.Resampling.LANCZOS).save(
    "assets/logos/bindora.png", "PNG"
)
print("updated assets/logos app icons")
