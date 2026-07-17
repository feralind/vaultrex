"""Generate free-floating brand logo PNGs for the game picker."""
from __future__ import annotations

import os

from PIL import Image, ImageDraw, ImageFont

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "logos")


def _font(size: int, bold: bool = True) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        r"C:\Windows\Fonts\arialbd.ttf" if bold else r"C:\Windows\Fonts\arial.ttf",
        r"C:\Windows\Fonts\segoeuib.ttf" if bold else r"C:\Windows\Fonts\segoeui.ttf",
        r"C:\Windows\Fonts\impact.ttf",
        r"C:\Windows\Fonts\georgiab.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                pass
    return ImageFont.load_default()


def _georgia(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in (
        r"C:\Windows\Fonts\georgiab.ttf",
        r"C:\Windows\Fonts\georgia.ttf",
        r"C:\Windows\Fonts\arialbd.ttf",
    ):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return _font(size)


def _save(im: Image.Image, name: str) -> None:
    path = os.path.join(OUT, name)
    im.save(path, "PNG")
    print(name, im.size, os.path.getsize(path))


def riftbound() -> None:
    """Clean wordmark + portal mark — same 512×180 footprint as sibling logos."""
    w, h = 512, 180
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    # Portal mark (left): soft concentric rings + thin vertical rift slit.
    cx, cy = 78, 90
    for rx, ry, fill in (
        (54, 68, (40, 70, 160, 70)),
        (40, 50, (70, 130, 255, 110)),
        (26, 32, (120, 200, 255, 160)),
        (12, 14, (220, 240, 255, 230)),
    ):
        d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=fill)
    # Clean vertical portal slit (not a bolt)
    d.rounded_rectangle(
        (cx - 3, cy - 36, cx + 3, cy + 36),
        radius=3,
        fill=(236, 244, 255, 255),
    )
    d.line([(cx, cy - 34), (cx, cy + 34)], fill=(167, 139, 250, 200), width=2)

    # Wordmark — same weight class as MAGIC / GUNDAM tiles
    f = None
    for path in (
        r"C:\Windows\Fonts\arialbd.ttf",
        r"C:\Windows\Fonts\segoeuib.ttf",
        r"C:\Windows\Fonts\arial.ttf",
    ):
        if os.path.exists(path):
            f = ImageFont.truetype(path, 52)
            break
    if f is None:
        f = _font(52)

    text = "RIFTBOUND"
    tx, ty = 300, 92
    for dx in range(-2, 3):
        for dy in range(-2, 3):
            if dx or dy:
                d.text((tx + dx, ty + dy), text, font=f, fill=(56, 120, 255, 90), anchor="mm")
    d.text((tx, ty), text, font=f, fill=(210, 230, 255, 255), anchor="mm")
    _save(im, "riftbound.png")


def pokemon() -> None:
    w, h = 512, 180
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    f = _font(92)
    text = "Pokémon"
    for dx in range(-4, 5):
        for dy in range(-4, 5):
            if dx * dx + dy * dy <= 20:
                d.text((w // 2 + dx, h // 2 + dy), text, font=f, fill=(42, 117, 187, 255), anchor="mm")
    d.text((w // 2, h // 2), text, font=f, fill=(255, 203, 5, 255), anchor="mm")
    _save(im, "pokemon.png")


def mtg() -> None:
    w, h = 512, 180
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.text((w // 2, 70), "MAGIC", font=_georgia(48), fill=(245, 230, 200, 255), anchor="mm")
    d.text((w // 2, 118), "THE GATHERING", font=_georgia(22), fill=(196, 165, 116, 255), anchor="mm")

    def diamond(x: int, y: int, s: int) -> None:
        d.polygon([(x, y - s), (x + s, y), (x, y + s), (x - s, y)], fill=(249, 115, 22, 255))

    diamond(48, 90, 16)
    diamond(464, 90, 16)
    _save(im, "mtg.png")


def onepiece() -> None:
    w, h = 512, 180
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    f = None
    for path in (r"C:\Windows\Fonts\impact.ttf", r"C:\Windows\Fonts\arialbd.ttf"):
        if os.path.exists(path):
            f = ImageFont.truetype(path, 72)
            break
    if f is None:
        f = _font(72)
    text = "ONE PIECE"
    for dx in range(-3, 4):
        for dy in range(-3, 4):
            if abs(dx) + abs(dy) > 0:
                d.text((w // 2 + dx - 10, h // 2 + dy + 8), text, font=f, fill=(26, 26, 26, 255), anchor="mm")
    d.text((w // 2 - 10, h // 2 + 8), text, font=f, fill=(239, 68, 68, 255), anchor="mm")
    d.ellipse((430, 28, 490, 62), fill=(251, 191, 36, 255), outline=(26, 26, 26, 255), width=3)
    d.arc((434, 18, 486, 50), 200, 340, fill=(26, 26, 26, 255), width=3)
    d.rectangle((448, 42, 472, 50), fill=(220, 38, 38, 255))
    _save(im, "onepiece.png")


def lorcana() -> None:
    w, h = 512, 180
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((55, 35, 145, 125), fill=(124, 58, 237, 255))
    d.ellipse((75, 25, 165, 115), fill=(167, 139, 250, 255))
    d.ellipse((70, 45, 110, 85), fill=(233, 213, 255, 230))
    d.ellipse((100, 40, 125, 65), fill=(253, 244, 255, 200))
    d.text((340, 95), "LORCANA", font=_georgia(44), fill=(233, 213, 255, 255), anchor="mm")
    _save(im, "lorcana.png")


def gundam() -> None:
    w, h = 512, 180
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((40, 36, 472, 42), fill=(34, 211, 238, 200))
    d.rectangle((40, 138, 472, 144), fill=(34, 211, 238, 200))
    f = _font(64)
    text = "GUNDAM"
    for dx in range(-2, 3):
        for dy in range(-2, 3):
            if abs(dx) + abs(dy) > 0:
                d.text((w // 2 + dx, h // 2 + dy), text, font=f, fill=(34, 211, 238, 255), anchor="mm")
    d.text((w // 2, h // 2), text, font=f, fill=(226, 232, 240, 255), anchor="mm")
    _save(im, "gundam.png")


def main() -> None:
    import sys

    os.makedirs(OUT, exist_ok=True)
    targets = {
        "riftbound": riftbound,
        "pokemon": pokemon,
        "mtg": mtg,
        "onepiece": onepiece,
        "lorcana": lorcana,
        "gundam": gundam,
    }
    names = sys.argv[1:] or list(targets)
    for name in names:
        targets[name]()
    print("done")


if __name__ == "__main__":
    main()
