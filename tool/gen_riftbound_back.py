"""Generate a crisp HD Riftbound-style main-deck card back PNG."""

from __future__ import annotations

import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1000, 1400
OUT = os.path.join(
    os.path.dirname(__file__),
    "..",
    "assets",
    "card_backs",
    "riftbound_back.png",
)

NAVY = (8, 22, 58)
GOLD = (212, 175, 95)
GOLD_LT = (232, 204, 138)


def main() -> None:
    # Draw at 2× then LANCZOS downsample for clean anti-aliased geometry.
    scale = 2
    w2, h2 = W * scale, H * scale
    img = Image.new("RGB", (w2, h2), NAVY)

    glow = Image.new("L", (w2, h2), 0)
    gd = ImageDraw.Draw(glow)
    gd.ellipse([w2 * 0.15, h2 * 0.18, w2 * 0.85, h2 * 0.82], fill=255)
    glow = glow.filter(ImageFilter.GaussianBlur(240))
    glow_rgb = Image.new("RGB", (w2, h2), (18, 40, 90))
    img = Image.composite(glow_rgb, img, glow)
    d = ImageDraw.Draw(img)

    cx, cy = w2 / 2, h2 / 2
    margin = 48 * scale

    def stroke_rr(xy: list[float], radius: float, color: tuple, width: int) -> None:
        x0, y0, x1, y1 = xy
        for woff in range(width):
            d.rounded_rectangle(
                [x0 + woff, y0 + woff, x1 - woff, y1 - woff],
                radius=max(1, radius - woff),
                outline=color,
                width=1,
            )

    stroke_rr([margin, margin, w2 - margin, h2 - margin], 56, GOLD, 5)
    inner = margin + 36
    stroke_rr([inner, inner, w2 - inner, h2 - inner], 36, GOLD, 3)

    def diamond(x: float, y: float, size: float, color: tuple, width: int = 3) -> None:
        pts = [(x, y - size), (x + size, y), (x, y + size), (x - size, y)]
        d.line(pts + [pts[0]], fill=color, width=width)

    ci = margin + 18
    for px, py in [(ci, ci), (w2 - ci, ci), (ci, h2 - ci), (w2 - ci, h2 - ci)]:
        diamond(px, py, 14, GOLD, 3)

    half = 210 * scale
    outer = [
        (cx, cy - half),
        (cx + half, cy),
        (cx, cy + half),
        (cx - half, cy),
    ]
    d.line(outer + [outer[0]], fill=GOLD, width=7)
    inner_h = half - 36
    inner_pts = [
        (cx, cy - inner_h),
        (cx + inner_h, cy),
        (cx, cy + inner_h),
        (cx - inner_h, cy),
    ]
    d.line(inner_pts + [inner_pts[0]], fill=GOLD_LT, width=3)

    wing_len = 190
    wing_h = 36
    for side in (-1, 1):
        x0 = cx + side * (half - 16)
        tip_x = x0 + side * wing_len
        pts = [
            (x0, cy - wing_h),
            (x0 + side * 56, cy - wing_h * 0.35),
            (tip_x, cy),
            (x0 + side * 56, cy + wing_h * 0.35),
            (x0, cy + wing_h),
            (x0 + side * 24, cy),
        ]
        d.line(pts + [pts[0]], fill=GOLD, width=3)

    for upward, yoff in [(True, -half + 80), (False, half - 80)]:
        yc = cy + yoff
        for rad in (310, 350, 390):
            bbox = [cx - rad, yc - rad, cx + rad, yc + rad]
            start, end = (200, 340) if upward else (20, 160)
            d.arc(bbox, start=start, end=end, fill=GOLD, width=3)

    diamond(cx, cy - half - 96, 20, GOLD, 3)
    diamond(cx, cy + half + 96, 20, GOLD, 3)

    try:
        font_lg = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 104)
        font_sm = ImageFont.truetype(r"C:\Windows\Fonts\arialbd.ttf", 56)
    except OSError:
        font_lg = ImageFont.load_default()
        font_sm = font_lg

    def tsize(font: ImageFont.ImageFont, text: str) -> tuple[int, int]:
        b = d.textbbox((0, 0), text, font=font)
        return b[2] - b[0], b[3] - b[1]

    def cbar(text: str, y: float, font: ImageFont.ImageFont, pad_x: int = 44, pad_y: int = 20) -> None:
        tw, th = tsize(font, text)
        box = [
            cx - tw / 2 - pad_x,
            y - th / 2 - pad_y,
            cx + tw / 2 + pad_x,
            y + th / 2 + pad_y,
        ]
        d.rectangle(box, fill=NAVY, outline=GOLD, width=3)
        # Anchor middle so LEAGUE / LEGENDS share the same center axis.
        d.text((cx, y), text, font=font, fill=GOLD_LT, anchor="mm")

    cbar("LEAGUE", cy - 116, font_lg)
    tw, th = tsize(font_sm, "OF")
    d.rectangle(
        [cx - tw / 2 - 28, cy - th / 2 - 12, cx + tw / 2 + 28, cy + th / 2 + 12],
        fill=NAVY,
    )
    d.text((cx, cy), "OF", font=font_sm, fill=GOLD_LT, anchor="mm")
    cbar("LEGENDS", cy + 116, font_lg)

    out_path = os.path.normpath(OUT)
    final = img.resize((W, H), Image.Resampling.LANCZOS)
    final.save(out_path, "PNG", optimize=True)
    print(f"Wrote {out_path} {final.size} {os.path.getsize(out_path)} bytes")


if __name__ == "__main__":
    main()
