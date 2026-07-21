"""
Bindora pixel cat — Style G Tuxedo (cream muzzle + white socks).
32×32 -> ×6 NEAREST. Banks: walk 8, idle 4, scratch 6, happy 4.
Solid rump/back on every walk frame.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parents[1] / "assets" / "mascot" / "pixel_cat"
SCALE = 6
SIZE = 32

E = (0, 0, 0, 0)
K = (14, 12, 16, 255)
B = (36, 34, 42, 255)
D = (22, 20, 28, 255)
L = (70, 68, 80, 255)
W = (245, 242, 250, 255)
CRM = (255, 245, 230, 255)
EYE = (120, 220, 255, 255)
PUP = (20, 30, 40, 255)
PNK = (255, 160, 180, 255)
RED = (230, 50, 70, 255)
GLD = (255, 210, 70, 255)
S = (0, 0, 0, 40)


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


def outline(g):
    solid = {
        (x, y)
        for y in range(SIZE)
        for x in range(SIZE)
        if g[y][x][3] == 255 and g[y][x] != S
    }
    for x, y in solid:
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < SIZE and 0 <= ny < SIZE and g[ny][nx][3] == 0:
                p(g, nx, ny, K)


def body_solid(g, bob=0):
    """Filled silhouette — cream chest + solid rump (no walk holes)."""
    oval(g, 16, 19 + bob, 10, 8, B)
    oval(g, 14, 18 + bob, 7, 6, L)
    oval(g, 12, 18 + bob, 4, 4, CRM)
    oval(g, 23, 20 + bob, 5, 6, D)
    rect(g, 20, 17 + bob, 26, 24 + bob, D)
    rect(g, 21, 18 + bob, 25, 23 + bob, B)


def head(g, bob=0, *, blink=False, happy=False):
    oval(g, 11, 10 + bob, 8, 7, B)
    oval(g, 10, 10 + bob, 5, 4, CRM)
    rect(g, 5, 3 + bob, 7, 7 + bob, B)
    p(g, 6, 5 + bob, PNK)
    rect(g, 13, 3 + bob, 15, 7 + bob, B)
    p(g, 14, 5 + bob, PNK)
    if blink:
        rect(g, 7, 9 + bob, 9, 9 + bob, K)
        rect(g, 12, 9 + bob, 14, 9 + bob, K)
    elif happy:
        # ^ ^ eyes
        p(g, 7, 9 + bob, EYE)
        p(g, 8, 8 + bob, EYE)
        p(g, 9, 9 + bob, EYE)
        p(g, 12, 9 + bob, EYE)
        p(g, 13, 8 + bob, EYE)
        p(g, 14, 9 + bob, EYE)
    else:
        rect(g, 7, 8 + bob, 9, 10 + bob, EYE)
        rect(g, 12, 8 + bob, 14, 10 + bob, EYE)
        p(g, 8, 9 + bob, PUP)
        p(g, 13, 9 + bob, PUP)
    p(g, 10, 11 + bob, PNK)
    for wy in (10, 11):
        p(g, 3, wy + bob, W)
        p(g, 16, wy + bob, W)
    rect(g, 8, 15 + bob, 14, 16 + bob, RED)
    p(g, 11, 17 + bob, GLD)


def legs_idle(g, bob=0):
    for lx in (10, 13, 18, 21):
        rect(g, lx, 25 + bob, lx + 2, 26, B)
        rect(g, lx, 27, lx + 2, 28, W)


def legs_walk(g, frame, bob=0):
    cyc = [0, 1, 2, 1, 0, -1, -2, -1]
    o = cyc[frame % 8]
    for lx in (9 + o, 13 - o, 18 + o, 22 - o):
        rect(g, lx, 24 + bob, lx + 2, 26, B)
        rect(g, lx, 27, lx + 2, 28, W)


def tail(g, bob=0, pose="up"):
    if pose == "walk":
        pts = [(0, 0), (1, -1), (2, -2), (2, -3), (1, -4), (0, -3)]
    elif pose == "low":
        pts = [(0, 0), (1, 1), (2, 1), (3, 0), (4, -1), (4, 0)]
    else:
        pts = [(0, 0), (1, -1), (2, -2), (2, -3), (1, -4), (0, -4)]
    for i, (dx, dy) in enumerate(pts):
        p(g, 26 + dx, 18 + dy + bob, B if i < 3 else D)


def walk(i):
    g = blank()
    oval(g, 16, 30, 9, 2, S)
    bob = [0, -1, 0, -1, 0, -1, 0, -1][i % 8]
    body_solid(g, bob)
    head(g, bob)
    legs_walk(g, i, bob)
    tail(g, bob, "walk")
    outline(g)
    return g


def idle(i):
    g = blank()
    oval(g, 16, 30, 9, 2, S)
    breath = [0, 0, 1, 1][i % 4]
    body_solid(g, -breath)
    head(g, -breath, blink=(i == 2))
    legs_idle(g, -breath)
    tail(g, -breath, "up" if i % 2 == 0 else "low")
    outline(g)
    return g


def scratch(i):
    g = blank()
    oval(g, 16, 30, 8, 2, S)
    body_solid(g, 0)
    head(g, 0, happy=(i in (2, 3, 4)))
    # front legs planted
    for lx in (10, 13):
        rect(g, lx, 25, lx + 2, 26, B)
        rect(g, lx, 27, lx + 2, 28, W)
    # hind haunch solid
    rect(g, 18, 22, 24, 26, D)
    rect(g, 19, 23, 23, 25, B)
    # scratching hind leg arc toward head
    arc = [
        (20, 20, 22, 25),
        (18, 14, 21, 20),
        (15, 9, 19, 15),
        (13, 6, 17, 11),
        (14, 8, 18, 13),
        (18, 16, 21, 22),
    ][i % 6]
    x0, y0, x1, y1 = arc
    rect(g, x0, y0, x1, y1, D)
    rect(g, x0, y0, x0 + 1, y0, W)
    if i in (2, 3):
        p(g, 10, 5, W)
        p(g, 11, 4, W)
    tail(g, 0, "low")
    outline(g)
    return g


def happy(i):
    g = blank()
    oval(g, 16, 30, 9, 2, S)
    bounce = [0, -2, -3, -1][i % 4]
    body_solid(g, bounce)
    head(g, bounce, happy=True)
    legs_idle(g, bounce)
    # socks stay grounded-ish when bouncing
    if bounce < 0:
        for lx in (10, 13, 18, 21):
            rect(g, lx, 28, lx + 2, 28, W)
    tail(g, bounce, "up")
    if i % 2 == 0:
        p(g, 8, 2 + bounce, PNK)
        p(g, 9, 1 + bounce, PNK)
        p(g, 10, 2 + bounce, PNK)
    outline(g)
    return g


def to_img(grid):
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    pix = im.load()
    for y in range(SIZE):
        for x in range(SIZE):
            pix[x, y] = grid[y][x]
    return im.resize((SIZE * SCALE, SIZE * SCALE), Image.Resampling.NEAREST)


def save(name, frames):
    folder = OUT / name
    folder.mkdir(parents=True, exist_ok=True)
    imgs = []
    for i, fr in enumerate(frames):
        im = to_img(fr)
        im.save(folder / f"{i:02d}.png")
        imgs.append(im)
    strip = Image.new("RGBA", (imgs[0].width * len(imgs), imgs[0].height))
    for i, im in enumerate(imgs):
        strip.paste(im, (i * im.width, 0))
    strip.save(OUT / f"preview_{name}.png")
    print(name, len(imgs))


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    save("walk", [walk(i) for i in range(8)])
    save("idle", [idle(i) for i in range(4)])
    save("scratch", [scratch(i) for i in range(6)])
    save("happy", [happy(i) for i in range(4)])
    print("style: G tuxedo ->", OUT)


if __name__ == "__main__":
    main()
