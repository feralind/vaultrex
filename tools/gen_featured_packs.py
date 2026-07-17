"""Generate transparent featured pack PNGs for Card Candy."""
from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = os.path.join(
    os.path.dirname(__file__),
    '..',
    'assets',
    'featured_packs',
)

TIERS = {
    'common': {
        'file': 'pack_common.png',
        'foil': [(40, 180, 90), (120, 255, 140), (20, 120, 70), (180, 255, 200)],
        'icon': (34, 197, 94),
        'outline': None,
        'label': 'COMMON',
    },
    'uncommon': {
        'file': 'pack_uncommon.png',
        'foil': [(20, 160, 180), (80, 230, 240), (10, 100, 140), (160, 255, 255)],
        'icon': (20, 184, 166),
        'outline': None,
        'label': 'UNCOMMON',
    },
    'rare': {
        'file': 'pack_rare.png',
        'foil': [(255, 180, 60), (255, 120, 160), (255, 200, 80), (255, 140, 100)],
        'icon': (249, 115, 22),
        'outline': None,
        'label': 'RARE',
    },
    'epic': {
        'file': 'pack_epic.png',
        'foil': [(140, 60, 220), (220, 80, 200), (90, 40, 180), (200, 140, 255)],
        'icon': (168, 85, 247),
        'outline': None,
        'label': 'EPIC',
    },
    'legendary': {
        'file': 'pack_legendary.png',
        'foil': [(80, 10, 20), (160, 30, 40), (40, 0, 10), (200, 140, 40)],
        'icon': (220, 38, 38),
        'outline': (212, 175, 55),
        'label': 'LEGENDARY',
    },
    'mythic': {
        'file': 'pack_mythic.png',
        'foil': [
            (255, 80, 120),
            (80, 200, 255),
            (180, 80, 255),
            (255, 220, 80),
            (80, 255, 160),
        ],
        'icon': (255, 255, 255),
        'outline': 'rainbow',
        'label': 'MYTHIC',
    },
}

W, H = 512, 720


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def foil_color(colors, x, y, w, h):
    t = (
        x / w
        + y / h * 0.6
        + math.sin(x * 0.04) * 0.08
        + math.cos(y * 0.05) * 0.08
    ) % 1.0
    n = len(colors)
    seg = t * (n - 1)
    i = int(seg)
    f = seg - i
    i2 = min(i + 1, n - 1)
    return lerp(colors[i], colors[i2], f) + (255,)


def rounded_pack_mask(w, h):
    mask = Image.new('L', (w, h), 0)
    d = ImageDraw.Draw(mask)
    margin_x, margin_y = 48, 36
    body = [margin_x, margin_y + 40, w - margin_x, h - margin_y - 20]
    d.rounded_rectangle(body, radius=48, fill=255)
    d.rounded_rectangle(
        [margin_x + 10, margin_y, w - margin_x - 10, margin_y + 56],
        radius=18,
        fill=255,
    )
    d.rounded_rectangle(
        [margin_x + 16, h - margin_y - 36, w - margin_x - 16, h - margin_y],
        radius=12,
        fill=255,
    )
    return mask


def draw_swirl_icon(draw, cx, cy, r, fill, outline=None):
    for i in range(5):
        a0 = i * 72
        pts = []
        for t in range(0, 220, 8):
            ang = math.radians(a0 + t * 1.6)
            rad = r * (0.15 + t / 220 * 0.85)
            pts.append((cx + math.cos(ang) * rad, cy + math.sin(ang) * rad))
        if len(pts) > 1:
            col = fill if len(fill) == 4 else fill + (220,)
            draw.line(pts, fill=col, width=max(3, r // 10))
    draw.ellipse(
        [cx - r * 0.22, cy - r * 0.22, cx + r * 0.22, cy + r * 0.22],
        fill=fill,
    )
    if outline == 'rainbow':
        rainbow = [
            (255, 80, 120),
            (255, 180, 60),
            (80, 255, 140),
            (80, 180, 255),
            (180, 80, 255),
        ]
        for i, c in enumerate(rainbow):
            rr = r * (1.05 + i * 0.02)
            draw.arc(
                [cx - rr, cy - rr, cx + rr, cy + rr],
                0 + i * 30,
                300 + i * 20,
                fill=c,
                width=4,
            )
    elif outline:
        draw.ellipse(
            [cx - r * 1.05, cy - r * 1.05, cx + r * 1.05, cy + r * 1.05],
            outline=outline,
            width=3,
        )


def make_pack(cfg):
    mask = rounded_pack_mask(W, H)
    foil = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    px = foil.load()
    for y in range(H):
        for x in range(W):
            if mask.getpixel((x, y)) > 20:
                c = foil_color(cfg['foil'], x, y, W, H)
                shine = 1.0 + 0.12 * math.sin((x + y) * 0.03)
                c = tuple(min(255, int(c[i] * shine)) for i in range(3)) + (c[3],)
                px[x, y] = c

    # Dim central sunburst (intentionally soft vs loud reference glow).
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    base = cfg['foil'][0]
    for i in range(8, 0, -1):
        alpha = int(8 + i * 1.5)
        r = 40 + i * 28
        gd.ellipse(
            [W // 2 - r, H // 2 - 40 - r, W // 2 + r, H // 2 - 40 + r],
            fill=base + (alpha,),
        )
    glow = glow.filter(ImageFilter.GaussianBlur(18))

    foil.putalpha(mask)
    out = Image.alpha_composite(Image.new('RGBA', (W, H), (0, 0, 0, 0)), glow)
    out = Image.alpha_composite(out, foil)
    draw = ImageDraw.Draw(out)

    for dy in (48, 62, H - 70, H - 56):
        draw.line([(70, dy), (W - 70, dy)], fill=(255, 255, 255, 55), width=2)

    draw_swirl_icon(draw, W // 2, H // 2 - 30, 78, cfg['icon'], cfg['outline'])

    cy = H - 130
    for dx in (-28, 0, 28):
        draw.ellipse(
            [W // 2 + dx - 10, cy - 10, W // 2 + dx + 10, cy + 10],
            fill=(212, 175, 55, 230),
            outline=(255, 230, 140, 255),
            width=2,
        )

    try:
        font_sm = ImageFont.truetype('arial.ttf', 16)
        font_md = ImageFont.truetype('arialbd.ttf', 18)
    except OSError:
        font_sm = ImageFont.load_default()
        font_md = font_sm

    draw.text(
        (W // 2 - 42, H - 108),
        'POWERED BY',
        fill=(255, 255, 255, 180),
        font=font_sm,
    )
    draw.text(
        (W // 2 - 40, H - 88),
        'RIP PACK',
        fill=(255, 255, 255, 230),
        font=font_md,
    )
    draw.text(
        (W // 2 - 40, 78),
        cfg['label'],
        fill=(255, 255, 255, 210),
        font=font_md,
    )

    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, cfg['file'])
    out.save(path, 'PNG')
    print('wrote', path)


def main():
    for cfg in TIERS.values():
        make_pack(cfg)
    print('done')


if __name__ == '__main__':
    main()
