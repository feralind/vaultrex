#!/usr/bin/env python3
"""Bake Rare Candy–style top→bottom scrub peel frames (OPTIONAL / LEGACY).

Live pack theater now peels the real `packImageUrl` at runtime via
`ScrubPeelStage` in lib/widgets/pack_peel_scrub.dart — do not ship a fixed
Bindora/Riftbound bake for all products.

This script remains useful for reference motion studies or marketing clips.

Outputs (legacy):
  assets/rip/peel_sealed.png
  assets/rip/frames/peel_XX.png
  assets/rip/peel_generic.mp4
"""

from __future__ import annotations

import math
import subprocess
from pathlib import Path

import imageio_ffmpeg
import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "rip"
FRAMES_DIR = OUT_DIR / "frames"
PACK_SRC = ROOT / "assets" / "featured_packs" / "riftbound" / "pack_legendary.png"
CARD_BACK = ROOT / "assets" / "card_backs" / "riftbound_back.png"

W, H = 720, 1280
FPS = 48
# Dense scrub set — Flutter crossfades between adjacent frames for sub-frame feel.
N_FRAMES = 96
PACK_MAX_H = int(H * 0.72)
# Soft edge width (px) for anti-aliased tear masks.
TEAR_AA = 1.75


def ease_in_out(t: float) -> float:
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)


def ease_out_cubic(t: float) -> float:
    t = max(0.0, min(1.0, t))
    return 1.0 - (1.0 - t) ** 3


def ease_scrub(t: float) -> float:
    """Near-linear progress for finger scrub — mild ease only at ends."""
    t = max(0.0, min(1.0, t))
    # 85% linear + 15% smoothstep keeps tip travel even while softening starts.
    return t * 0.85 + ease_in_out(t) * 0.15


def smoothstep01(x: np.ndarray) -> np.ndarray:
    x = np.clip(x, 0.0, 1.0)
    return x * x * (3.0 - 2.0 * x)


def studio_bg(size: tuple[int, int]) -> Image.Image:
    w, h = size
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    cx, cy = w * 0.5, h * 0.36
    rx, ry = w * 0.52, h * 0.58
    d = np.sqrt(((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2)
    d = np.clip(d, 0, 1.8)
    fall = np.clip(d, 0, 1)
    r = 10 + (1.0 - fall) * 16
    g = 14 + (1.0 - fall) * 20
    b = 26 + (1.0 - fall) * 34
    outer = np.clip((d - 0.9) / 0.8, 0, 1)
    r = r * (1 - outer) + 4 * outer
    g = g * (1 - outer) + 6 * outer
    b = b * (1 - outer) + 10 * outer
    rgb = np.stack([r, g, b], axis=-1).astype(np.uint8)
    return Image.fromarray(rgb, "RGB").convert("RGBA")


def load_pack() -> Image.Image:
    raw = Image.open(PACK_SRC).convert("RGBA")
    arr = np.asarray(raw)
    alpha = arr[..., 3]
    lum = arr[..., :3].max(axis=-1)
    mask = (alpha > 8) & (lum > 12)
    ys, xs = np.where(mask)
    if len(xs) > 50:
        pad = 4
        x0, x1 = max(0, xs.min() - pad), min(raw.width, xs.max() + pad + 1)
        y0, y1 = max(0, ys.min() - pad), min(raw.height, ys.max() + pad + 1)
        raw = raw.crop((x0, y0, x1, y1))
    scale = PACK_MAX_H / raw.height
    nw, nh = int(raw.width * scale), int(raw.height * scale)
    pack = raw.resize((nw, nh), Image.Resampling.LANCZOS)
    pack = ImageEnhance.Contrast(pack).enhance(1.04)
    pack = ImageEnhance.Color(pack).enhance(1.03)
    return pack


def load_card_back(size: tuple[int, int]) -> Image.Image:
    w, h = size
    rad = max(14, w // 18)
    if CARD_BACK.exists():
        raw = Image.open(CARD_BACK).convert("RGBA")
        card = raw.resize((w, h), Image.Resampling.LANCZOS)
    else:
        card = Image.new("RGBA", (w, h), (12, 20, 40, 255))
        d = ImageDraw.Draw(card)
        d.rounded_rectangle([2, 2, w - 3, h - 3], radius=rad, outline=(200, 210, 230, 255), width=3)
    # Soft round-rect clip so edges match pack theater card backs.
    clip = Image.new("L", (w, h), 0)
    ImageDraw.Draw(clip).rounded_rectangle([0, 0, w - 1, h - 1], radius=rad, fill=255)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(card, (0, 0))
    out.putalpha(clip)
    return out


def pack_shadow(pack: Image.Image, strength: float = 0.55) -> Image.Image:
    a = pack.split()[-1]
    s = a.point(lambda p: int(p * strength))
    shadow = Image.new("RGBA", pack.size, (0, 0, 0, 0))
    shadow.putalpha(s)
    return shadow.filter(ImageFilter.GaussianBlur(18))


def set_opacity(im: Image.Image, factor: float) -> Image.Image:
    r, g, b, a = im.split()
    a = a.point(lambda p: int(p * max(0.0, min(1.0, factor))))
    return Image.merge("RGBA", (r, g, b, a))


def v_tear_edge_y(x: float, pw: float, tip_y: float, top_y: float, jag: float) -> float:
    """Y of the V tear edge at pack-local x. tip_y is the lowest point (center)."""
    cx = pw * 0.5
    # Width of V at top — spans nearly full pack by the time tip is deep.
    half = max(1.0, pw * 0.48)
    # Distance from center normalized 0..1
    t = min(1.0, abs(x - cx) / half)
    # Parabolic V: center deepest
    base = top_y + (tip_y - top_y) * (1.0 - t * t)
    # Organic jaggedness — stronger near tip, never a flat "pill" band
    zig = math.sin(x * 0.085 + tip_y * 0.04) * jag * (0.35 + 0.65 * (1.0 - t))
    zig += math.sin(x * 0.21) * jag * 0.35
    # Finer secondary grain so adjacent frames don't share identical jags
    zig += math.sin(x * 0.47 + tip_y * 0.11) * jag * 0.12
    return base + zig


def _tear_edge_array(pw: int, tip_y: float, top_y: float) -> np.ndarray:
    jag = 3.2 + min(7.5, (tip_y - top_y) * 0.018)
    xs = np.arange(pw, dtype=np.float32)
    return np.array(
        [v_tear_edge_y(float(x), float(pw), tip_y, top_y, jag) for x in xs],
        dtype=np.float32,
    )


def remaining_pack_mask(pw: int, ph: int, tip_y: float, top_y: float) -> Image.Image:
    """Anti-aliased alpha for the still-sealed lower portion (below V tear)."""
    edge = _tear_edge_array(pw, tip_y, top_y)
    yy = np.arange(ph, dtype=np.float32)[:, None]
    # Signed distance below edge (+) = remaining pack.
    dist = yy - edge[None, :]
    soft = smoothstep01((dist + TEAR_AA) / (2.0 * TEAR_AA))
    return Image.fromarray((soft * 255.0).astype(np.uint8), "L")


def peeled_region_mask(pw: int, ph: int, tip_y: float, top_y: float) -> Image.Image:
    """Mask for foil that has been torn open (above V edge), soft-edged."""
    rem = np.asarray(remaining_pack_mask(pw, ph, tip_y, top_y), dtype=np.float32)
    peeled = np.clip(255.0 - rem, 0, 255).astype(np.uint8)
    # Tiny blur keeps flap composites free of stair-steps between scrub frames.
    return Image.fromarray(peeled, "L").filter(ImageFilter.GaussianBlur(0.45))


def flap_band_mask(pw: int, ph: int, tip_y: float, top_y: float) -> Image.Image:
    """Only the foil band just above the tear — not the entire opened region.

    Rare Candy flaps are a curling strip along the rip, not full half-packs.
    """
    peeled = np.asarray(peeled_region_mask(pw, ph, tip_y, top_y), dtype=np.float32)
    # Keep a band of ~18–28% pack height above the current tip.
    band_h = max(28.0, ph * 0.22)
    yy = np.arange(ph, dtype=np.float32)[:, None]
    # Soft window: near tip (strong) → fade toward top of pack
    dist_above = tip_y - yy
    in_band = (dist_above >= -4) & (dist_above <= band_h)
    fall = np.clip(dist_above / band_h, 0, 1)
    weight = np.where(in_band, (1.0 - fall * 0.55), 0.0)
    # Also kill anything far above once tip is deep (avoid giant ghost flaps)
    if tip_y > ph * 0.55:
        weight = weight * np.clip(1.0 - (tip_y / ph - 0.55) / 0.45, 0.15, 1.0)
    out = (peeled / 255.0 * weight * 255.0).astype(np.uint8)
    return Image.fromarray(out, "L")


def foil_underside(size: tuple[int, int]) -> Image.Image:
    """Bright silver foil underside for peeled flaps (Rare Candy look)."""
    w, h = size
    yy = np.linspace(0, 1, h, dtype=np.float32)[:, None]
    xx = np.linspace(0, 1, w, dtype=np.float32)[None, :]
    base = 210 + 35 * np.sin(xx * 9 + yy * 4) + 20 * np.cos(xx * 14 - yy * 6)
    base = np.clip(base, 170, 250)
    rgb = np.stack([base, base * 0.98, base * 0.94], axis=-1).astype(np.uint8)
    img = Image.fromarray(rgb, "RGB").convert("RGBA")
    # Specular streaks
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for i in range(5):
        x0 = int(w * (0.1 + i * 0.18))
        gd.line([(x0, 0), (x0 + int(w * 0.08), h)], fill=(255, 255, 255, 40), width=max(2, w // 40))
    glow = glow.filter(ImageFilter.GaussianBlur(3))
    return Image.alpha_composite(img, glow)


def make_flap(
    pack: Image.Image,
    peeled_mask: Image.Image,
    *,
    left: bool,
    open_t: float,
    exit_t: float,
) -> tuple[Image.Image, tuple[int, int]]:
    """Build one curling flap from the peeled region (left or right of center)."""
    pw, ph = pack.size
    cx = pw // 2
    side_arr = np.zeros((ph, pw), dtype=np.uint8)
    peeled = np.asarray(peeled_mask)
    if left:
        side_arr[:, :cx] = peeled[:, :cx]
    else:
        side_arr[:, cx:] = peeled[:, cx:]
    side = Image.fromarray(side_arr, "L")

    # Outer art flap
    outer = pack.copy()
    oa = np.asarray(outer.split()[-1], dtype=np.float32)
    sm = np.asarray(side, dtype=np.float32)
    outer.putalpha(Image.fromarray((oa * sm / 255.0).astype(np.uint8), "L"))

    # Underside foil — dominant on the tear face (Rare Candy silver lip)
    under = foil_underside((pw, ph))
    ua = np.asarray(under.split()[-1], dtype=np.float32)
    under.putalpha(Image.fromarray((ua * sm / 255.0).astype(np.uint8), "L"))

    flap = Image.new("RGBA", (pw + 48, ph + 48), (0, 0, 0, 0))
    ox, oy = 24, 24
    # Underside sits slightly toward the tear (center) so silver reads first
    ux = ox + (10 if left else -10)
    flap.alpha_composite(under, (ux, oy + 3))
    # Outer art offset outward so thickness shows
    ox_art = ox + (-4 if left else 4)
    flap.alpha_composite(outer, (ox_art, oy))

    # Mild curl early; stronger only as flaps exit (avoid paper-doll halves)
    ang = (1 if left else -1) * (4 + open_t * 18 + exit_t * 42)
    sx = max(0.55, 1.0 - open_t * 0.12 - exit_t * 0.35)
    nw = max(1, int(flap.width * sx))
    scaled = flap.resize((nw, flap.height), Image.Resampling.LANCZOS)
    pad = Image.new("RGBA", flap.size, (0, 0, 0, 0))
    if left:
        pad.paste(scaled, (0, 0), scaled)
    else:
        pad.paste(scaled, (flap.width - nw, 0), scaled)

    rotated = pad.rotate(ang, resample=Image.Resampling.BICUBIC, expand=True)
    fade = max(0.0, 1.0 - exit_t * 1.2)
    rotated = set_opacity(rotated, fade)

    sep = open_t * 0.08 + exit_t * 0.92
    dx = int((-1 if left else 1) * sep * pw * 0.55)
    dy = int(-sep * ph * 0.34 - open_t * ph * 0.02)
    dx -= (rotated.width - pw) // 2
    dy -= (rotated.height - ph) // 2
    return rotated, (dx, dy)


def draw_tear_lip(
    canvas: Image.Image,
    pack_box: tuple[int, int, int, int],
    tip_y: float,
    top_y: float,
    strength: float,
) -> None:
    """Bright specular lip along the V tear — never a flat horizontal pill."""
    if strength < 0.02:
        return
    ox, oy, pw, ph = pack_box
    jag = 3.2 + min(7.5, (tip_y - top_y) * 0.018)
    pts = []
    # Sub-pixel denser samples → smoother lip across scrub frames
    for xi in range(0, pw, 1):
        y = v_tear_edge_y(float(xi), float(pw), tip_y, top_y, jag)
        if top_y - 2 <= y <= tip_y + 2:
            pts.append((ox + xi, oy + y))
    if len(pts) < 4:
        return
    glow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    # Thin V rim only — no wide band that reads as a UI pill
    for width, alpha in ((5, 42), (2, 130), (1, 200)):
        gd.line(pts, fill=(255, 248, 230, int(alpha * strength)), width=width, joint="curve")
    glow = glow.filter(ImageFilter.GaussianBlur(0.65))
    canvas.alpha_composite(glow)


def render_frame(
    t: float,
    pack: Image.Image,
    card: Image.Image,
    bg: Image.Image,
) -> Image.Image:
    """t in [0,1]: sealed → V peel → flaps clear → card hold."""
    canvas = bg.copy()
    pw, ph = pack.size
    ox = (W - pw) // 2
    oy = (H - ph) // 2 - int(H * 0.02)

    # Phase splits tuned for dense scrub:
    # Near-linear peel tip so adjacent frames advance evenly under the finger.
    # 0–0.015 idle sealed
    # 0.015–0.62 V tear advances top→bottom
    # 0.34–0.70 flaps curl (band only)
    # 0.56–1.0 flaps exit, card holds
    peel_t = ease_scrub(max(0.0, min(1.0, (t - 0.015) / 0.605)))
    open_t = ease_in_out(max(0.0, min(1.0, (t - 0.34) / 0.32)))
    exit_t = ease_out_cubic(max(0.0, (t - 0.56) / 0.44))

    sh = pack_shadow(pack, 0.50 * (1.0 - exit_t * 0.85))
    canvas.alpha_composite(sh, (ox + 10, oy + 22))

    # Card under pack — visible once tear opens
    card_vis = min(1.0, peel_t * 1.4 + open_t * 0.3 + exit_t)
    if card_vis > 0.02:
        cw, ch = card.size
        bx = ox + (pw - cw) // 2
        by = oy + (ph - ch) // 2
        scale = 0.96 + exit_t * 0.04
        nw, nh = max(1, int(cw * scale)), max(1, int(ch * scale))
        c = set_opacity(card.resize((nw, nh), Image.Resampling.LANCZOS), card_vis)
        canvas.alpha_composite(c, (bx + (cw - nw) // 2, by + (ch - nh) // 2))

    top_y = ph * 0.02
    # Tip travels from near top to past bottom so pack fully clears
    tip_y = top_y + peel_t * ph * 1.08

    if peel_t < 0.012 and open_t < 0.01:
        # Fully sealed — single intact pack image
        canvas.alpha_composite(pack, (ox, oy))
    else:
        # Remaining sealed lower pack (one piece — no vertical half split)
        rem_mask = remaining_pack_mask(pw, ph, tip_y, top_y)
        rem = pack.copy()
        ra = np.asarray(rem.split()[-1], dtype=np.float32)
        rm = np.asarray(rem_mask, dtype=np.float32)
        rem.putalpha(Image.fromarray((ra * rm / 255.0).astype(np.uint8), "L"))
        canvas.alpha_composite(rem, (ox, oy))

        # Peeled flaps — curling band along the tear only (not full half-packs)
        if peel_t > 0.015 and exit_t < 0.85:
            band = flap_band_mask(pw, ph, tip_y, top_y)
            for is_left in (True, False):
                flap, (fdx, fdy) = make_flap(
                    pack, band, left=is_left, open_t=open_t, exit_t=exit_t
                )
                if flap.split()[-1].getextrema()[1] > 0:
                    canvas.alpha_composite(flap, (ox + fdx, oy + fdy))

        draw_tear_lip(
            canvas,
            (ox, oy, pw, ph),
            tip_y,
            top_y,
            strength=min(1.0, peel_t * 1.2) * (1.0 - exit_t),
        )

    out = Image.new("RGB", (W, H), (8, 10, 18))
    out.paste(canvas, mask=canvas.split()[-1])
    return out


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    FRAMES_DIR.mkdir(parents=True, exist_ok=True)

    pack = load_pack()
    card = load_card_back((int(pack.width * 0.88), int(pack.height * 0.86)))
    bg = studio_bg((W, H))

    for old in FRAMES_DIR.glob("peel_*.png"):
        old.unlink()

    sealed = render_frame(0.0, pack, card, bg)
    sealed_path = OUT_DIR / "peel_sealed.png"
    sealed.save(sealed_path, "PNG", optimize=True)
    print("wrote", sealed_path, sealed.size)

    frames: list[Image.Image] = []
    for i in range(N_FRAMES):
        # Map scrub index so frame 0 is sealed and last frames still have content
        t = i / max(1, N_FRAMES - 1)
        frame = render_frame(t, pack, card, bg)
        frames.append(frame)
        frame.save(FRAMES_DIR / f"peel_{i:02d}.png", "PNG", optimize=True)
        if i % 12 == 0:
            print(f"frame {i}/{N_FRAMES}")

    ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
    mp4 = OUT_DIR / "peel_generic.mp4"
    cmd = [
        ffmpeg,
        "-y",
        "-f",
        "rawvideo",
        "-vcodec",
        "rawvideo",
        "-pix_fmt",
        "rgb24",
        "-s",
        f"{W}x{H}",
        "-r",
        str(FPS),
        "-i",
        "-",
        "-an",
        "-c:v",
        "libx264",
        "-pix_fmt",
        "yuv420p",
        "-preset",
        "medium",
        "-crf",
        "18",
        "-movflags",
        "+faststart",
        str(mp4),
    ]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stderr=subprocess.PIPE)
    assert proc.stdin is not None
    for frame in frames:
        proc.stdin.write(frame.tobytes())
    proc.stdin.close()
    err = proc.stderr.read().decode("utf-8", "replace") if proc.stderr else ""
    code = proc.wait()
    if code != 0:
        print(err[-2000:])
        return code
    print("wrote", mp4, "size", mp4.stat().st_size)
    print("frames", N_FRAMES)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
