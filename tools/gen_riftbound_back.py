"""Generate a clean flat Riftbound main-deck (blue) card-back PNG."""
from __future__ import annotations
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "card_backs")
REF = os.path.join(OUT_DIR, "riftbound_backs_ref.jpg")
OUT = os.path.join(OUT_DIR, "riftbound_back.png")

def spark(d, x, y, s, fill):
    pts = [(x, y - s), (x + s * 0.65, y), (x, y + s), (x - s * 0.65, y)]
    d.line(pts + [pts[0]], fill=fill, width=2)

def generate():
    os.makedirs(OUT_DIR, exist_ok=True)
    if os.path.exists(REF):
        im = Image.open(REF)
        im.crop((820, 140, 1240, 960)).save(os.path.join(OUT_DIR, "_blue_crop_preview.jpg"), quality=90)

    w, h = 750, 1050
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    navy_deep = (8, 18, 52, 255)
    navy = (14, 32, 82, 255)
    gold = (212, 175, 95, 255)
    gold_dim = (184, 148, 72, 210)
    d.rounded_rectangle((0, 0, w - 1, h - 1), radius=42, fill=navy_deep)

    vignette = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    cx, cy = w // 2, h // 2
    for i in range(16, 0, -1):
        rad = int(max(w, h) * 0.48 * (i / 16))
        a = int(6 + i * 1.6)
        vd.ellipse((cx - rad, cy - rad, cx + rad, cy + rad), fill=(*navy[:3], a))
    img = Image.alpha_composite(img, vignette)
    d = ImageDraw.Draw(img)

    d.rounded_rectangle((26, 26, w - 27, h - 27), radius=28, outline=gold, width=3)
    d.rounded_rectangle((40, 40, w - 41, h - 41), radius=22, outline=gold_dim, width=1)

    cx, cy = w / 2, h / 2
    for rad, width in ((210, 2), (255, 1), (305, 1)):
        bbox = (cx - rad, cy - rad, cx + rad, cy + rad)
        d.arc(bbox, start=45, end=135, fill=gold_dim, width=width)
        d.arc(bbox, start=225, end=315, fill=gold_dim, width=width)

    bar_h, bar_w = 32, 290
    for dy in (-56, 56):
        y0 = cy + dy - bar_h / 2
        x0 = cx - bar_w / 2
        d.rounded_rectangle((x0, y0, x0 + bar_w, y0 + bar_h), radius=3, outline=gold, width=2, fill=(16, 34, 88, 200))

    diamond_r = 170
    def diamond(scale, width, color):
        pts = [
            (cx, cy - diamond_r * scale),
            (cx + diamond_r * 0.72 * scale, cy),
            (cx, cy + diamond_r * scale),
            (cx - diamond_r * 0.72 * scale, cy),
        ]
        d.line(pts + [pts[0]], fill=color, width=width)

    diamond(1.0, 3, gold)
    diamond(0.93, 2, gold)
    diamond(0.55, 2, gold_dim)
    spark(d, cx, cy - diamond_r - 50, 16, gold)
    spark(d, cx, cy + diamond_r + 50, 16, gold)
    for ox, oy in ((72, 72), (w - 72, 72), (72, h - 72), (w - 72, h - 72)):
        spark(d, ox, oy, 10, gold_dim)

    font_paths = [r"C:\Windows\Fonts\arialbd.ttf", r"C:\Windows\Fonts\segoeuib.ttf", r"C:\Windows\Fonts\arial.ttf"]
    fp = next((p for p in font_paths if os.path.exists(p)), None)
    def font(size):
        return ImageFont.truetype(fp, size) if fp else ImageFont.load_default()

    def center_text(text, y, size, tracking=3):
        f = font(size)
        widths = [d.textbbox((0, 0), ch, font=f)[2] - d.textbbox((0, 0), ch, font=f)[0] for ch in text]
        total = sum(widths) + tracking * (len(text) - 1)
        x = cx - total / 2
        for i, ch in enumerate(text):
            d.text((x, y), ch, font=f, fill=gold)
            x += widths[i] + tracking

    center_text("LEAGUE", cy - 82, 38, 5)
    center_text("OF", cy - 30, 22, 8)
    center_text("LEGENDS", cy + 16, 38, 5)
    img.save(OUT, "PNG")
    print(f"wrote {OUT} ({img.size[0]}x{img.size[1]}, {os.path.getsize(OUT)} bytes)")

if __name__ == "__main__":
    generate()
