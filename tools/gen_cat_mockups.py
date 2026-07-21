"""
Cute 32-bit style cat design mockups — many directions for Tom to pick.
Each variant: idle strip + walk strip with SOLID rump/back (no holes).
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parents[1] / "assets" / "mascot" / "cat_mockups"
SIZE = 32
SCALE = 6

E = (0, 0, 0, 0)


def blank():
    return [[E] * SIZE for _ in range(SIZE)]


def p(g, x, y, c):
    if 0 <= x < SIZE and 0 <= y < SIZE and c[3] > 0:
        g[y][x] = c


def rect(g, x0, y0, x1, y1, c):
    for y in range(min(y0, y1), max(y0, y1) + 1):
        for x in range(min(x0, x1), max(x0, x1) + 1):
            p(g, x, y, c)


def oval(g, cx, cy, rx, ry, c):
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            if ((x - cx) / max(rx, 1)) ** 2 + ((y - cy) / max(ry, 1)) ** 2 <= 1.05:
                p(g, x, y, c)


def outline(g, k):
    solid = {(x, y) for y in range(SIZE) for x in range(SIZE) if g[y][x][3] == 255}
    for x, y in solid:
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < SIZE and 0 <= ny < SIZE and g[ny][nx][3] == 0:
                p(g, nx, ny, k)


def to_img(g):
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    pix = im.load()
    for y in range(SIZE):
        for x in range(SIZE):
            pix[x, y] = g[y][x]
    return im.resize((SIZE * SCALE, SIZE * SCALE), Image.Resampling.NEAREST)


# ─── Style A: Super chibi blob (Tamagotchi cute) ───────────────────────────
# Huge round head, tiny body, filled back always.

def style_a_pal():
    return dict(
        K=(20, 16, 24, 255),
        B=(40, 38, 48, 255),
        D=(26, 24, 32, 255),
        L=(70, 68, 80, 255),
        EYE=(255, 200, 80, 255),
        PUP=(30, 20, 20, 255),
        PNK=(255, 160, 185, 255),
        RED=(230, 70, 90, 255),
        GLD=(255, 210, 70, 255),
        PAW=(200, 198, 210, 255),
        S=(0, 0, 0, 40),
    )


def draw_a(g, pose, frame, pal):
    K, B, D, L, EYE, PUP, PNK, RED, GLD, PAW, S = (
        pal[k] for k in "K B D L EYE PUP PNK RED GLD PAW S".split()
    )
    # soft shadow
    oval(g, 16, 29, 8, 2, S)
    bob = 0
    if pose == "walk":
        bob = [0, -1, 0, -1][frame % 4]

    # BODY — solid oval rump (never hollow)
    oval(g, 17, 20 + bob, 9, 7, B)
    oval(g, 15, 19 + bob, 7, 5, L)  # chest
    oval(g, 22, 21 + bob, 4, 5, D)  # back fill / rump shade — KEY

    # HEAD — big circle 3/4
    oval(g, 12, 11 + bob, 8, 7, B)
    oval(g, 11, 10 + bob, 6, 5, L)
    # ears
    rect(g, 6, 3 + bob, 8, 7 + bob, B)
    p(g, 7, 5 + bob, PNK)
    rect(g, 14, 3 + bob, 16, 7 + bob, B)
    p(g, 15, 5 + bob, PNK)
    # face
    if frame % 4 == 2 and pose == "idle":
        rect(g, 8, 10 + bob, 10, 10 + bob, K)
        rect(g, 13, 10 + bob, 15, 10 + bob, K)
    else:
        rect(g, 8, 9 + bob, 10, 11 + bob, EYE)
        rect(g, 13, 9 + bob, 15, 11 + bob, EYE)
        p(g, 9, 10 + bob, PUP)
        p(g, 14, 10 + bob, PUP)
    p(g, 11, 12 + bob, PNK)
    # whiskers
    for wy in (11, 12, 13):
        p(g, 4, wy + bob, PAW)
        p(g, 19, wy + bob, PAW)
    # collar
    rect(g, 9, 16 + bob, 15, 17 + bob, RED)
    p(g, 12, 18 + bob, GLD)

    # legs
    if pose == "walk":
        lifts = [(0, 1), (1, 0), (0, 1), (1, 0)][frame % 4]
        for i, lx in enumerate((10, 14, 18, 22)):
            lift = lifts[i % 2]
            rect(g, lx, 24 + bob - lift, lx + 1, 27, B)
            p(g, lx, 28, PAW)
    else:
        for lx in (11, 14, 18, 21):
            rect(g, lx, 25 + bob, lx + 1, 27, B)
            p(g, lx, 28, PAW)

    # tail — attached to filled rump
    if pose == "walk":
        pts = [(24, 18), (25, 16), (26, 15), (27, 16), (27, 18)]
    else:
        pts = [(24, 19), (25, 17), (26, 15), (26, 13), (25, 12)]
    for x, y in pts:
        p(g, x, y + bob, B)
        p(g, x, y + 1 + bob, D)

    outline(g, K)


# ─── Style B: Soft SNES 32-bit (more shading, plump) ───────────────────────

def style_b_pal():
    return dict(
        K=(15, 12, 18, 255),
        B=(45, 42, 55, 255),
        D=(30, 28, 38, 255),
        M=(55, 52, 68, 255),
        L=(85, 80, 100, 255),
        EYE=(255, 220, 90, 255),
        PUP=(25, 18, 20, 255),
        PNK=(255, 155, 180, 255),
        RED=(210, 55, 75, 255),
        GLD=(255, 205, 60, 255),
        PAW=(210, 205, 220, 255),
        S=(0, 0, 0, 45),
    )


def draw_b(g, pose, frame, pal):
    K, B, D, M, L, EYE, PUP, PNK, RED, GLD, PAW, S = (
        pal[k] for k in "K B D M L EYE PUP PNK RED GLD PAW S".split()
    )
    oval(g, 16, 30, 9, 2, S)
    bob = [0, -1, 0, -1, 0, -1, 0, -1][frame % 8] if pose == "walk" else 0

    # plump body facing left, SOLID back
    oval(g, 16, 19 + bob, 10, 8, B)
    oval(g, 14, 18 + bob, 8, 6, M)
    oval(g, 12, 17 + bob, 5, 4, L)
    # explicit rump block so walk never holes
    oval(g, 23, 20 + bob, 5, 6, D)
    rect(g, 20, 17 + bob, 26, 24 + bob, D)
    rect(g, 21, 18 + bob, 25, 23 + bob, B)

    # 3/4 head
    oval(g, 11, 10 + bob, 8, 7, B)
    oval(g, 10, 9 + bob, 6, 5, L)
    rect(g, 5, 3 + bob, 7, 7 + bob, B)
    p(g, 6, 5 + bob, PNK)
    rect(g, 13, 3 + bob, 15, 7 + bob, B)
    p(g, 14, 5 + bob, PNK)
    if pose == "idle" and frame == 2:
        rect(g, 7, 9 + bob, 9, 9 + bob, K)
        rect(g, 12, 9 + bob, 14, 9 + bob, K)
    else:
        rect(g, 7, 8 + bob, 9, 10 + bob, EYE)
        rect(g, 12, 8 + bob, 14, 10 + bob, EYE)
        p(g, 8, 9 + bob, PUP)
        p(g, 13, 9 + bob, PUP)
    p(g, 10, 11 + bob, PNK)
    for wy in (10, 11, 12):
        p(g, 3, wy + bob, PAW)
        p(g, 18, wy + bob, PAW)
    rect(g, 8, 15 + bob, 14, 16 + bob, RED)
    p(g, 11, 17 + bob, GLD)

    # legs with solid hips
    if pose == "walk":
        cyc = [0, 1, 2, 1, 0, -1, -2, -1]
        o = cyc[frame % 8]
        for lx, shade in ((9 + o, B), (13 - o, B), (18 + o, D), (22 - o, D)):
            rect(g, lx, 24 + bob, lx + 2, 27, shade)
            rect(g, lx, 28, lx + 2, 28, PAW)
    else:
        for lx in (10, 13, 18, 21):
            rect(g, lx, 25, lx + 2, 27, B)
            rect(g, lx, 28, lx + 2, 28, PAW)

    # tail from rump
    for i, (dx, dy) in enumerate([(0, 0), (1, -1), (2, -2), (2, -3), (1, -4), (0, -4)]):
        p(g, 26 + dx, 18 + dy + bob, B if i < 3 else M)

    outline(g, K)


# ─── Style C: Round sitting mascot (always cute face-forward-ish) ───────────

def style_c_pal():
    return dict(
        K=(18, 14, 20, 255),
        B=(35, 35, 42, 255),
        D=(22, 22, 28, 255),
        L=(65, 65, 75, 255),
        EYE=(255, 230, 100, 255),
        PUP=(40, 30, 20, 255),
        PNK=(255, 170, 190, 255),
        RED=(240, 60, 80, 255),
        GLD=(255, 215, 60, 255),
        PAW=(220, 220, 230, 255),
        S=(0, 0, 0, 40),
    )


def draw_c(g, pose, frame, pal):
    K, B, D, L, EYE, PUP, PNK, RED, GLD, PAW, S = (
        pal[k] for k in "K B D L EYE PUP PNK RED GLD PAW S".split()
    )
    oval(g, 16, 30, 8, 2, S)
    bob = [0, -1, 0, -1][frame % 4] if pose == "walk" else [0, 0, 1, 0][frame % 4]

    # big round body — fully filled
    oval(g, 16, 18 + bob, 10, 9, B)
    oval(g, 16, 17 + bob, 8, 7, L)
    oval(g, 20, 19 + bob, 5, 6, D)  # side shade / back

    # huge head
    oval(g, 16, 10 + bob, 9, 8, B)
    oval(g, 16, 9 + bob, 7, 6, L)
    rect(g, 9, 2 + bob, 11, 6 + bob, B)
    p(g, 10, 4 + bob, PNK)
    rect(g, 20, 2 + bob, 22, 6 + bob, B)
    p(g, 21, 4 + bob, PNK)
    if pose == "idle" and frame == 2:
        rect(g, 11, 9 + bob, 13, 9 + bob, K)
        rect(g, 18, 9 + bob, 20, 9 + bob, K)
    else:
        rect(g, 11, 8 + bob, 13, 11 + bob, EYE)
        rect(g, 18, 8 + bob, 20, 11 + bob, EYE)
        p(g, 12, 9 + bob, PUP)
        p(g, 19, 9 + bob, PUP)
    p(g, 16, 12 + bob, PNK)
    # blush
    p(g, 10, 12 + bob, PNK)
    p(g, 21, 12 + bob, PNK)
    rect(g, 12, 16 + bob, 19, 17 + bob, RED)
    p(g, 15, 18 + bob, GLD)
    p(g, 16, 18 + bob, GLD)

    if pose == "walk":
        for i, lx in enumerate((10, 14, 18, 22)):
            lift = (frame + i) % 2
            rect(g, lx, 25 + bob - lift, lx + 2, 27, B)
            rect(g, lx, 28, lx + 2, 28, PAW)
    else:
        for lx in (11, 14, 18, 21):
            rect(g, lx, 26, lx + 2, 27, B)
            rect(g, lx, 28, lx + 2, 28, PAW)

    # chubby tail
    for x, y in [(24, 16), (25, 14), (26, 13), (26, 12), (25, 11)]:
        p(g, x, y + bob, B)

    outline(g, K)


# ─── Style D: Tiny RPG pet (longer body, solid silhouette) ──────────────────

def style_d_pal():
    return dict(
        K=(12, 10, 14, 255),
        B=(38, 36, 44, 255),
        D=(24, 22, 30, 255),
        L=(72, 70, 82, 255),
        EYE=(255, 195, 70, 255),
        PUP=(20, 15, 15, 255),
        PNK=(255, 150, 175, 255),
        RED=(200, 45, 65, 255),
        GLD=(255, 200, 55, 255),
        PAW=(195, 195, 205, 255),
        S=(0, 0, 0, 40),
    )


def draw_d(g, pose, frame, pal):
    K, B, D, L, EYE, PUP, PNK, RED, GLD, PAW, S = (
        pal[k] for k in "K B D L EYE PUP PNK RED GLD PAW S".split()
    )
    oval(g, 15, 30, 9, 2, S)
    bob = [0, -1, 0, -1, 0, -1, 0, -1][frame % 8] if pose == "walk" else 0

    # elongated body, filled end-to-end
    rect(g, 6, 15 + bob, 24, 24 + bob, B)
    rect(g, 7, 16 + bob, 23, 23 + bob, B)
    rect(g, 8, 17 + bob, 14, 21 + bob, L)
    rect(g, 18, 16 + bob, 24, 24 + bob, D)  # solid rear
    rect(g, 19, 17 + bob, 23, 23 + bob, B)

    # head 3/4 on left
    oval(g, 10, 10 + bob, 7, 6, B)
    oval(g, 9, 9 + bob, 5, 4, L)
    rect(g, 5, 4 + bob, 7, 7 + bob, B)
    p(g, 6, 5 + bob, PNK)
    rect(g, 12, 4 + bob, 14, 7 + bob, B)
    p(g, 13, 5 + bob, PNK)
    if pose == "idle" and frame == 2:
        rect(g, 7, 9 + bob, 8, 9 + bob, K)
        rect(g, 11, 9 + bob, 12, 9 + bob, K)
    else:
        rect(g, 7, 8 + bob, 8, 10 + bob, EYE)
        rect(g, 11, 8 + bob, 12, 10 + bob, EYE)
        p(g, 7, 9 + bob, PUP)
        p(g, 11, 9 + bob, PUP)
    p(g, 9, 11 + bob, PNK)
    for wy in (10, 11):
        p(g, 3, wy + bob, PAW)
        p(g, 16, wy + bob, PAW)
    rect(g, 7, 14 + bob, 13, 15 + bob, RED)
    p(g, 10, 16 + bob, GLD)

    if pose == "walk":
        offs = [0, 2, 3, 1, 0, -2, -3, -1]
        o = offs[frame % 8]
        pairs = [(8 + o, B), (12 - o, B), (17 + o, D), (21 - o, D)]
        for lx, col in pairs:
            rect(g, lx, 24 + bob, lx + 2, 27, col)
            rect(g, lx, 28, lx + 2, 28, PAW)
    else:
        for lx in (8, 12, 17, 21):
            rect(g, lx, 25, lx + 2, 27, B)
            rect(g, lx, 28, lx + 2, 28, PAW)

    # tail from solid rear
    for dx, dy in [(0, 0), (1, -1), (2, -2), (3, -2), (4, -1), (4, 0)]:
        p(g, 24 + dx, 18 + dy + bob, B)

    outline(g, K)


# ─── Style E: Kawaii sparkle (huge eyes + blush) ────────────────────────────

def style_e_pal():
    return dict(
        K=(22, 18, 28, 255),
        B=(42, 40, 52, 255),
        D=(28, 26, 36, 255),
        L=(78, 74, 92, 255),
        EYE=(255, 235, 120, 255),
        PUP=(35, 25, 30, 255),
        HI=(255, 255, 255, 255),
        PNK=(255, 150, 180, 255),
        RED=(235, 65, 95, 255),
        GLD=(255, 215, 80, 255),
        PAW=(230, 225, 240, 255),
        S=(0, 0, 0, 40),
    )


def draw_e(g, pose, frame, pal):
    K, B, D, L, EYE, PUP, HI, PNK, RED, GLD, PAW, S = (
        pal[k] for k in "K B D L EYE PUP HI PNK RED GLD PAW S".split()
    )
    oval(g, 16, 30, 8, 2, S)
    bob = [0, -1, 0, -1][frame % 4] if pose == "walk" else 0

    oval(g, 17, 20 + bob, 9, 7, B)
    oval(g, 15, 19 + bob, 7, 5, L)
    oval(g, 22, 21 + bob, 5, 5, D)
    rect(g, 19, 18 + bob, 25, 24 + bob, D)
    rect(g, 20, 19 + bob, 24, 23 + bob, B)

    oval(g, 12, 10 + bob, 9, 8, B)
    oval(g, 11, 9 + bob, 7, 6, L)
    rect(g, 5, 2 + bob, 8, 7 + bob, B)
    p(g, 6, 4 + bob, PNK)
    p(g, 7, 5 + bob, PNK)
    rect(g, 14, 2 + bob, 17, 7 + bob, B)
    p(g, 15, 4 + bob, PNK)
    p(g, 16, 5 + bob, PNK)

    if pose == "idle" and frame == 2:
        rect(g, 7, 10 + bob, 10, 10 + bob, K)
        rect(g, 13, 10 + bob, 16, 10 + bob, K)
    else:
        rect(g, 7, 8 + bob, 10, 12 + bob, EYE)
        rect(g, 13, 8 + bob, 16, 12 + bob, EYE)
        p(g, 8, 10 + bob, PUP)
        p(g, 9, 10 + bob, PUP)
        p(g, 14, 10 + bob, PUP)
        p(g, 15, 10 + bob, PUP)
        p(g, 7, 8 + bob, HI)
        p(g, 13, 8 + bob, HI)
    p(g, 11, 13 + bob, PNK)
    # blush
    rect(g, 5, 12 + bob, 6, 13 + bob, PNK)
    rect(g, 17, 12 + bob, 18, 13 + bob, PNK)
    rect(g, 8, 16 + bob, 15, 17 + bob, RED)
    p(g, 11, 18 + bob, GLD)
    p(g, 12, 18 + bob, GLD)

    if pose == "walk":
        for i, lx in enumerate((10, 14, 18, 22)):
            lift = (frame + i) % 2
            rect(g, lx, 25 + bob - lift, lx + 1, 27, B)
            p(g, lx, 28, PAW)
    else:
        for lx in (11, 14, 18, 21):
            rect(g, lx, 26, lx + 1, 27, B)
            p(g, lx, 28, PAW)

    for x, y in [(24, 18), (25, 16), (26, 15), (27, 16), (27, 18), (26, 19)]:
        p(g, x, y + bob, B)
    outline(g, K)


# ─── Style F: Loaf cat (max chunk, short legs) ──────────────────────────────

def style_f_pal():
    return dict(
        K=(16, 14, 20, 255),
        B=(48, 46, 58, 255),
        D=(32, 30, 40, 255),
        L=(80, 76, 94, 255),
        EYE=(255, 210, 85, 255),
        PUP=(28, 20, 22, 255),
        PNK=(255, 165, 185, 255),
        RED=(220, 55, 75, 255),
        GLD=(255, 205, 65, 255),
        PAW=(215, 210, 225, 255),
        S=(0, 0, 0, 45),
    )


def draw_f(g, pose, frame, pal):
    K, B, D, L, EYE, PUP, PNK, RED, GLD, PAW, S = (
        pal[k] for k in "K B D L EYE PUP PNK RED GLD PAW S".split()
    )
    oval(g, 16, 30, 10, 2, S)
    bob = [0, -1, 0, -1][frame % 4] if pose == "walk" else 0

    # fat loaf body — solid brick of cat
    oval(g, 16, 20 + bob, 12, 8, B)
    oval(g, 14, 19 + bob, 9, 6, L)
    oval(g, 23, 20 + bob, 6, 7, D)
    rect(g, 18, 16 + bob, 27, 25 + bob, D)
    rect(g, 19, 17 + bob, 26, 24 + bob, B)

    # head sits on loaf
    oval(g, 11, 12 + bob, 8, 7, B)
    oval(g, 10, 11 + bob, 6, 5, L)
    rect(g, 5, 5 + bob, 7, 9 + bob, B)
    p(g, 6, 7 + bob, PNK)
    rect(g, 13, 5 + bob, 15, 9 + bob, B)
    p(g, 14, 7 + bob, PNK)
    if pose == "idle" and frame == 2:
        rect(g, 7, 11 + bob, 9, 11 + bob, K)
        rect(g, 12, 11 + bob, 14, 11 + bob, K)
    else:
        rect(g, 7, 10 + bob, 9, 12 + bob, EYE)
        rect(g, 12, 10 + bob, 14, 12 + bob, EYE)
        p(g, 8, 11 + bob, PUP)
        p(g, 13, 11 + bob, PUP)
    p(g, 10, 13 + bob, PNK)
    rect(g, 8, 16 + bob, 14, 17 + bob, RED)
    p(g, 11, 18 + bob, GLD)

    # stubby loaf feet
    if pose == "walk":
        for i, lx in enumerate((8, 13, 19, 24)):
            lift = (frame + i) % 2
            rect(g, lx, 26 + bob - lift, lx + 2, 27, B)
            rect(g, lx, 28, lx + 2, 28, PAW)
    else:
        for lx in (9, 13, 19, 23):
            rect(g, lx, 26, lx + 2, 27, B)
            rect(g, lx, 28, lx + 2, 28, PAW)

    for x, y in [(26, 17), (27, 15), (28, 14), (28, 16), (27, 18)]:
        p(g, x, y + bob, B)
    outline(g, K)


# ─── Style G: Tuxedo (cream muzzle + white socks) ───────────────────────────

def style_g_pal():
    return dict(
        K=(14, 12, 16, 255),
        B=(36, 34, 42, 255),
        D=(22, 20, 28, 255),
        L=(70, 68, 80, 255),
        W=(245, 242, 250, 255),
        CRM=(255, 245, 230, 255),
        EYE=(120, 220, 255, 255),
        PUP=(20, 30, 40, 255),
        PNK=(255, 160, 180, 255),
        RED=(230, 50, 70, 255),
        GLD=(255, 210, 70, 255),
        S=(0, 0, 0, 40),
    )


def draw_g(g, pose, frame, pal):
    K, B, D, L, W, CRM, EYE, PUP, PNK, RED, GLD, S = (
        pal[k] for k in "K B D L W CRM EYE PUP PNK RED GLD S".split()
    )
    oval(g, 16, 30, 9, 2, S)
    bob = [0, -1, 0, -1, 0, -1, 0, -1][frame % 8] if pose == "walk" else 0

    oval(g, 16, 19 + bob, 10, 8, B)
    oval(g, 14, 18 + bob, 7, 6, L)
    oval(g, 12, 18 + bob, 4, 4, CRM)  # cream chest
    oval(g, 23, 20 + bob, 5, 6, D)
    rect(g, 20, 17 + bob, 26, 24 + bob, D)
    rect(g, 21, 18 + bob, 25, 23 + bob, B)

    oval(g, 11, 10 + bob, 8, 7, B)
    oval(g, 10, 10 + bob, 5, 4, CRM)
    rect(g, 5, 3 + bob, 7, 7 + bob, B)
    p(g, 6, 5 + bob, PNK)
    rect(g, 13, 3 + bob, 15, 7 + bob, B)
    p(g, 14, 5 + bob, PNK)
    if pose == "idle" and frame == 2:
        rect(g, 7, 9 + bob, 9, 9 + bob, K)
        rect(g, 12, 9 + bob, 14, 9 + bob, K)
    else:
        rect(g, 7, 8 + bob, 9, 10 + bob, EYE)
        rect(g, 12, 8 + bob, 14, 10 + bob, EYE)
        p(g, 8, 9 + bob, PUP)
        p(g, 13, 9 + bob, PUP)
    p(g, 10, 11 + bob, PNK)
    rect(g, 8, 15 + bob, 14, 16 + bob, RED)
    p(g, 11, 17 + bob, GLD)

    if pose == "walk":
        cyc = [0, 1, 2, 1, 0, -1, -2, -1]
        o = cyc[frame % 8]
        for lx in (9 + o, 13 - o, 18 + o, 22 - o):
            rect(g, lx, 24 + bob, lx + 2, 26, B)
            rect(g, lx, 27, lx + 2, 28, W)  # white socks
    else:
        for lx in (10, 13, 18, 21):
            rect(g, lx, 25, lx + 2, 26, B)
            rect(g, lx, 27, lx + 2, 28, W)

    for dx, dy in [(0, 0), (1, -1), (2, -2), (2, -3), (1, -4), (0, -3)]:
        p(g, 26 + dx, 18 + dy + bob, B)
    outline(g, K)


# ─── Style H: Platformer pet (upright, chunky game sprite) ──────────────────

def style_h_pal():
    return dict(
        K=(10, 8, 14, 255),
        B=(50, 46, 60, 255),
        D=(34, 30, 42, 255),
        L=(90, 84, 105, 255),
        EYE=(255, 240, 100, 255),
        PUP=(20, 15, 20, 255),
        PNK=(255, 140, 170, 255),
        RED=(255, 70, 90, 255),
        GLD=(255, 220, 70, 255),
        PAW=(230, 225, 240, 255),
        S=(0, 0, 0, 40),
    )


def draw_h(g, pose, frame, pal):
    K, B, D, L, EYE, PUP, PNK, RED, GLD, PAW, S = (
        pal[k] for k in "K B D L EYE PUP PNK RED GLD PAW S".split()
    )
    oval(g, 16, 30, 7, 2, S)
    bob = [0, -2, 0, -2][frame % 4] if pose == "walk" else 0

    # upright oval body
    oval(g, 16, 18 + bob, 8, 9, B)
    oval(g, 15, 16 + bob, 6, 7, L)
    oval(g, 20, 19 + bob, 5, 7, D)
    rect(g, 18, 14 + bob, 23, 24 + bob, D)
    rect(g, 19, 15 + bob, 22, 23 + bob, B)

    # big round head on top
    oval(g, 15, 9 + bob, 8, 7, B)
    oval(g, 14, 8 + bob, 6, 5, L)
    rect(g, 8, 2 + bob, 10, 6 + bob, B)
    p(g, 9, 4 + bob, PNK)
    rect(g, 17, 2 + bob, 19, 6 + bob, B)
    p(g, 18, 4 + bob, PNK)
    if pose == "idle" and frame == 2:
        rect(g, 11, 8 + bob, 13, 8 + bob, K)
        rect(g, 16, 8 + bob, 18, 8 + bob, K)
    else:
        rect(g, 11, 7 + bob, 13, 10 + bob, EYE)
        rect(g, 16, 7 + bob, 18, 10 + bob, EYE)
        p(g, 12, 8 + bob, PUP)
        p(g, 17, 8 + bob, PUP)
    p(g, 14, 11 + bob, PNK)
    rect(g, 12, 14 + bob, 18, 15 + bob, RED)
    p(g, 15, 16 + bob, GLD)

    if pose == "walk":
        for i, lx in enumerate((11, 15, 18, 21)):
            lift = abs(((frame + i) % 4) - 1)
            rect(g, lx, 25 + bob - lift, lx + 2, 27, B)
            rect(g, lx, 28, lx + 2, 28, PAW)
    else:
        for lx in (12, 15, 18, 20):
            rect(g, lx, 26, lx + 2, 27, B)
            rect(g, lx, 28, lx + 2, 28, PAW)

    for x, y in [(22, 14), (23, 12), (24, 11), (24, 13), (23, 15)]:
        p(g, x, y + bob, B)
    outline(g, K)


# ─── Style I: Fluffy longhair (extra outline fluff) ─────────────────────────

def style_i_pal():
    return dict(
        K=(18, 14, 22, 255),
        B=(44, 40, 54, 255),
        D=(30, 26, 38, 255),
        M=(58, 54, 70, 255),
        L=(88, 82, 100, 255),
        EYE=(255, 200, 90, 255),
        PUP=(25, 18, 22, 255),
        PNK=(255, 155, 175, 255),
        RED=(215, 50, 70, 255),
        GLD=(255, 205, 60, 255),
        PAW=(220, 215, 230, 255),
        S=(0, 0, 0, 40),
    )


def draw_i(g, pose, frame, pal):
    K, B, D, M, L, EYE, PUP, PNK, RED, GLD, PAW, S = (
        pal[k] for k in "K B D M L EYE PUP PNK RED GLD PAW S".split()
    )
    oval(g, 16, 30, 10, 2, S)
    bob = [0, -1, 0, -1][frame % 4] if pose == "walk" else 0

    # fluffy body layers
    oval(g, 16, 19 + bob, 11, 9, M)
    oval(g, 16, 19 + bob, 9, 7, B)
    oval(g, 14, 18 + bob, 7, 5, L)
    oval(g, 23, 20 + bob, 6, 7, D)
    rect(g, 19, 16 + bob, 27, 25 + bob, D)
    rect(g, 20, 17 + bob, 26, 24 + bob, B)
    # fluff tufts on back
    for fx, fy in [(22, 15), (24, 14), (26, 16), (25, 18)]:
        p(g, fx, fy + bob, M)

    oval(g, 11, 10 + bob, 9, 8, M)
    oval(g, 11, 10 + bob, 7, 6, B)
    oval(g, 10, 9 + bob, 5, 4, L)
    # fluffy ears
    rect(g, 4, 2 + bob, 7, 8 + bob, B)
    p(g, 5, 4 + bob, PNK)
    p(g, 6, 5 + bob, M)
    rect(g, 13, 2 + bob, 16, 8 + bob, B)
    p(g, 14, 4 + bob, PNK)
    p(g, 15, 5 + bob, M)
    if pose == "idle" and frame == 2:
        rect(g, 7, 9 + bob, 9, 9 + bob, K)
        rect(g, 12, 9 + bob, 14, 9 + bob, K)
    else:
        rect(g, 7, 8 + bob, 9, 10 + bob, EYE)
        rect(g, 12, 8 + bob, 14, 10 + bob, EYE)
        p(g, 8, 9 + bob, PUP)
        p(g, 13, 9 + bob, PUP)
    p(g, 10, 11 + bob, PNK)
    rect(g, 8, 15 + bob, 14, 16 + bob, RED)
    p(g, 11, 17 + bob, GLD)

    if pose == "walk":
        for i, lx in enumerate((9, 13, 18, 22)):
            lift = (frame + i) % 2
            rect(g, lx, 25 + bob - lift, lx + 2, 27, B)
            rect(g, lx, 28, lx + 2, 28, PAW)
    else:
        for lx in (10, 13, 18, 21):
            rect(g, lx, 26, lx + 2, 27, B)
            rect(g, lx, 28, lx + 2, 28, PAW)

    for x, y in [(26, 17), (27, 15), (28, 13), (29, 14), (28, 16), (27, 18)]:
        p(g, x, y + bob, M)
        p(g, x, y + 1 + bob, B)
    outline(g, K)


# ─── Style J: GBA limited palette (chunky 4-tone) ───────────────────────────

def style_j_pal():
    return dict(
        K=(8, 8, 12, 255),
        B=(55, 50, 65, 255),
        D=(35, 32, 45, 255),
        L=(95, 90, 110, 255),
        EYE=(255, 230, 60, 255),
        PUP=(10, 10, 14, 255),
        PNK=(255, 130, 160, 255),
        RED=(230, 40, 70, 255),
        GLD=(255, 200, 40, 255),
        PAW=(200, 195, 210, 255),
        S=(0, 0, 0, 50),
    )


def draw_j(g, pose, frame, pal):
    K, B, D, L, EYE, PUP, PNK, RED, GLD, PAW, S = (
        pal[k] for k in "K B D L EYE PUP PNK RED GLD PAW S".split()
    )
    oval(g, 16, 30, 8, 2, S)
    bob = [0, -1, 0, -1][frame % 4] if pose == "walk" else 0

    # blocky filled body
    rect(g, 7, 15 + bob, 24, 25 + bob, B)
    rect(g, 8, 16 + bob, 15, 22 + bob, L)
    rect(g, 18, 16 + bob, 24, 25 + bob, D)
    rect(g, 19, 17 + bob, 23, 24 + bob, B)

    # block head
    rect(g, 5, 6 + bob, 17, 15 + bob, B)
    rect(g, 6, 7 + bob, 14, 13 + bob, L)
    rect(g, 5, 3 + bob, 8, 7 + bob, B)
    p(g, 6, 5 + bob, PNK)
    rect(g, 12, 3 + bob, 15, 7 + bob, B)
    p(g, 13, 5 + bob, PNK)
    if pose == "idle" and frame == 2:
        rect(g, 7, 9 + bob, 9, 9 + bob, K)
        rect(g, 12, 9 + bob, 14, 9 + bob, K)
    else:
        rect(g, 7, 8 + bob, 9, 11 + bob, EYE)
        rect(g, 12, 8 + bob, 14, 11 + bob, EYE)
        p(g, 8, 9 + bob, PUP)
        p(g, 13, 9 + bob, PUP)
    p(g, 10, 12 + bob, PNK)
    rect(g, 8, 14 + bob, 14, 15 + bob, RED)
    p(g, 11, 16 + bob, GLD)

    if pose == "walk":
        for i, lx in enumerate((8, 12, 17, 21)):
            lift = (frame + i) % 2
            rect(g, lx, 25 + bob - lift, lx + 2, 27, B)
            rect(g, lx, 28, lx + 2, 28, PAW)
    else:
        for lx in (9, 12, 17, 20):
            rect(g, lx, 26, lx + 2, 27, B)
            rect(g, lx, 28, lx + 2, 28, PAW)

    for x, y in [(24, 17), (25, 15), (26, 14), (26, 16), (25, 18)]:
        p(g, x, y + bob, B)
    outline(g, K)


STYLES = [
    ("A_chibi_blob", "A · Super chibi blob", style_a_pal, draw_a, 4, 4),
    ("B_snes_soft", "B · Soft 32-bit SNES", style_b_pal, draw_b, 4, 8),
    ("C_round_mascot", "C · Round mascot", style_c_pal, draw_c, 4, 4),
    ("D_rpg_pet", "D · Tiny RPG pet", style_d_pal, draw_d, 4, 8),
    ("E_kawaii_sparkle", "E · Kawaii sparkle", style_e_pal, draw_e, 4, 4),
    ("F_loaf_cat", "F · Loaf cat", style_f_pal, draw_f, 4, 4),
    ("G_tuxedo", "G · Tuxedo (cream + socks)", style_g_pal, draw_g, 4, 8),
    ("H_platformer", "H · Platformer pet", style_h_pal, draw_h, 4, 4),
    ("I_fluffy", "I · Fluffy longhair", style_i_pal, draw_i, 4, 4),
    ("J_gba_chunky", "J · GBA chunky", style_j_pal, draw_j, 4, 4),
]


def strip(frames):
    imgs = [to_img(f) for f in frames]
    s = Image.new("RGBA", (imgs[0].width * len(imgs), imgs[0].height), (30, 30, 36, 255))
    for i, im in enumerate(imgs):
        s.paste(im, (i * im.width, 0), im)
    return s


def board():
    OUT.mkdir(parents=True, exist_ok=True)
    rows = []
    labels = []
    for folder, title, pal_fn, draw, idle_n, walk_n in STYLES:
        pal = pal_fn()
        idle = [blank() for _ in range(idle_n)]
        walk = [blank() for _ in range(walk_n)]
        for i, g in enumerate(idle):
            draw(g, "idle", i, pal)
        for i, g in enumerate(walk):
            draw(g, "walk", i, pal)
        d = OUT / folder
        d.mkdir(parents=True, exist_ok=True)
        for i, g in enumerate(idle):
            to_img(g).save(d / f"idle_{i:02d}.png")
        for i, g in enumerate(walk):
            to_img(g).save(d / f"walk_{i:02d}.png")
        idle_s = strip(idle)
        walk_s = strip(walk)
        idle_s.save(d / "preview_idle.png")
        walk_s.save(d / "preview_walk.png")
        # combined row: idle | walk
        gap = 12
        row = Image.new(
            "RGBA",
            (idle_s.width + gap + walk_s.width, max(idle_s.height, walk_s.height) + 28),
            (22, 22, 28, 255),
        )
        row.paste(idle_s, (0, 28), idle_s)
        row.paste(walk_s, (idle_s.width + gap, 28), walk_s)
        draw_im = ImageDraw.Draw(row)
        draw_im.text((8, 6), f"{title}   idle →   walk →", fill=(220, 220, 230, 255))
        rows.append(row)
        labels.append(title)
        print("ok", folder)

    # master board
    w = max(r.width for r in rows)
    h = sum(r.height for r in rows) + 16 * (len(rows) + 1)
    board_im = Image.new("RGBA", (w + 24, h + 40), (18, 18, 22, 255))
    dr = ImageDraw.Draw(board_im)
    dr.text(
        (12, 10),
        "Bindora cat mockups — pick A–J",
        fill=(240, 240, 245, 255),
    )
    y = 40
    for r in rows:
        board_im.paste(r, (12, y), r)
        y += r.height + 16
    board_im.save(OUT / "CHOOSE_BOARD.png")
    print("wrote", OUT / "CHOOSE_BOARD.png")


if __name__ == "__main__":
    board()
