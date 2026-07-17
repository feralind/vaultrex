#!/usr/bin/env python3
"""Harden alpha + choke white/gray fringes on sealed product PNGs.

Also downloads missing shop Pokémon pack/box arts and runs the same pipeline.
"""

from __future__ import annotations

import io
import json
import re
import urllib.request
from collections import Counter, deque
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SEALED = ROOT / "assets" / "sealed"
REPORT = ROOT / "tools" / "art_bg_diagnostic.json"


def harden_alpha(rgba: np.ndarray) -> np.ndarray:
    """Snap soft rembg haze: low→0, high→255; keep mid only on edges."""
    a = rgba[:, :, 3].astype(np.int16)
    out = rgba.copy()
    out[:, :, 3] = np.where(a < 40, 0, np.where(a > 220, 255, a)).astype(np.uint8)
    return out


def near_white_mask(rgba: np.ndarray, floor: int = 210, chroma: int = 28) -> np.ndarray:
    r, g, b, a = rgba[:, :, 0], rgba[:, :, 1], rgba[:, :, 2], rgba[:, :, 3]
    mn = np.minimum(np.minimum(r, g), b)
    mx = np.maximum(np.maximum(r, g), b)
    return (a >= 12) & ((mx - mn) <= chroma) & (mn >= floor)


def light_gray_fringe(rgba: np.ndarray) -> np.ndarray:
    r, g, b, a = rgba[:, :, 0], rgba[:, :, 1], rgba[:, :, 2], rgba[:, :, 3]
    mn = np.minimum(np.minimum(r, g), b)
    mx = np.maximum(np.maximum(r, g), b)
    return (a >= 12) & (a < 250) & ((mx - mn) <= 22) & (mx <= 55)


def border_distance(h: int, w: int) -> np.ndarray:
    yy, xx = np.mgrid[0:h, 0:w]
    return np.minimum(np.minimum(xx, yy), np.minimum(w - 1 - xx, h - 1 - yy))


def flood_clear(rgba: np.ndarray, seed_mask: np.ndarray) -> np.ndarray:
    """Clear pixels reachable from borders through seed_mask (in-place alpha)."""
    h, w = rgba.shape[:2]
    visited = np.zeros((h, w), dtype=np.uint8)
    q: deque[tuple[int, int]] = deque()

    def push(x: int, y: int) -> None:
        if x < 0 or y < 0 or x >= w or y >= h:
            return
        if visited[y, x]:
            return
        if not seed_mask[y, x]:
            return
        visited[y, x] = 1
        q.append((x, y))

    for x in range(w):
        push(x, 0)
        push(x, h - 1)
    for y in range(h):
        push(0, y)
        push(w - 1, y)

    while q:
        x, y = q.popleft()
        rgba[y, x, 3] = 0
        push(x - 1, y)
        push(x + 1, y)
        push(x, y - 1)
        push(x, y + 1)
    return rgba


def choke_near_white_touching_clear(rgba: np.ndarray, passes: int = 4) -> np.ndarray:
    """Peel near-white pixels that touch transparency (vectorized neighbor check)."""
    for _ in range(passes):
        a = rgba[:, :, 3]
        nw = near_white_mask(rgba, floor=200, chroma=32)
        # Dilate clear mask by 1px
        clear = a < 20
        touch = np.zeros_like(clear)
        touch[1:, :] |= clear[:-1, :]
        touch[:-1, :] |= clear[1:, :]
        touch[:, 1:] |= clear[:, :-1]
        touch[:, :-1] |= clear[:, 1:]
        kill = nw & touch
        if not kill.any():
            break
        rgba[:, :, 3] = np.where(kill, 0, a)
    return rgba


def process_image(img: Image.Image, border_px: int = 10) -> Image.Image:
    rgba = np.array(img.convert("RGBA"), dtype=np.uint8)
    rgba = harden_alpha(rgba)
    h, w = rgba.shape[:2]
    dist = border_distance(h, w)

    # Border fringe choke — only bright near-white near the frame edge.
    # Keep floor high so cream/white pack art (tails, Poké Balls) survives.
    fringe = near_white_mask(rgba, floor=235, chroma=18) | light_gray_fringe(rgba)
    rgba[:, :, 3] = np.where(fringe & (dist <= border_px), 0, rgba[:, :, 3])

    # Edge-connected flood: clear + bright studio white from borders.
    clear = rgba[:, :, 3] < 12
    seed = clear | near_white_mask(rgba, floor=245, chroma=14)
    rgba = flood_clear(rgba, seed)

    rgba = choke_near_white_touching_clear(rgba, passes=3)
    rgba = harden_alpha(rgba)

    out = Image.fromarray(rgba, "RGBA")
    bbox = out.getbbox()
    if bbox:
        l, t, r, b = bbox
        pad = 4
        out = out.crop(
            (
                max(0, l - pad),
                max(0, t - pad),
                min(out.width, r + pad),
                min(out.height, b + pad),
            )
        )
    return out


def prefer_1000(url: str) -> str:
    if not url:
        return url
    # TCGPlayer product CDN patterns.
    url = re.sub(r"_in_\d+x\d+", "_in_1000x1000", url)
    if "_in_1000x1000" not in url and url.endswith(".jpg"):
        # Some rows already full URL without size token.
        pass
    return url


def download(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "VaultrexArtBot/1.0"})
    with urllib.request.urlopen(req, timeout=35) as res:
        return res.read()


def shop_pokemon_missing() -> list[tuple[int, str, str]]:
    catalog = json.loads(
        (ROOT / "assets/data/pokemon_sealed.json").read_text(encoding="utf-8-sig")
    )
    missing: list[tuple[int, str, str]] = []
    for p in catalog["products"]:
        kind = p.get("kind")
        if kind not in ("pack", "box"):
            continue
        name = p.get("name") or ""
        low = name.lower()
        if "code card" in low or "art bundle" in low or low.endswith(" case") or " case" in low:
            continue
        pid = int(p["productId"])
        out = SEALED / f"tcg_{pid}.png"
        if out.exists():
            continue
        url = prefer_1000(p.get("imageUrl") or "")
        if not url:
            continue
        missing.append((pid, name, url))
    return missing


def corner_stats(img: Image.Image, pad: int = 4) -> dict:
    rgba = img.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()
    samples = []
    for y in range(pad):
        for x in range(pad):
            samples.extend(
                [
                    px[x, y],
                    px[w - 1 - x, y],
                    px[x, h - 1 - y],
                    px[w - 1 - x, h - 1 - y],
                ]
            )
    tr = tw = 0
    for r, g, b, a in samples:
        if a < 20:
            tr += 1
            continue
        mn, mx = min(r, g, b), max(r, g, b)
        if mx - mn <= 14 and mn >= 245:
            tw += 1
    n = max(1, len(samples))
    arr = np.array(rgba)
    clear = float((arr[:, :, 3] < 12).mean() * 100)
    nw = int(
        (
            (arr[:, :, :3].max(2) - arr[:, :, :3].min(2) <= 25)
            & (arr[:, :, :3].min(2) >= 230)
            & (arr[:, :, 3] >= 200)
        ).sum()
    )
    return {
        "corner_transparent_pct": round(100 * tr / n, 1),
        "corner_white_pct": round(100 * tw / n, 1),
        "clear_pct": round(clear, 1),
        "near_white_opaque": nw,
        "size": [w, h],
    }


def dart_png_ids(ids: list[int]) -> str:
    lines = ["  static const Set<int> _localPngIds = {"]
    for i in ids:
        lines.append(f"    {i},")
    lines.append("  };")
    return "\n".join(lines)


def main() -> int:
    SEALED.mkdir(parents=True, exist_ok=True)

    # 1) Download missing shop Pokémon pack/box arts.
    missing = shop_pokemon_missing()
    print(f"Missing shop Pokémon sealed arts: {len(missing)}")
    for i, (pid, name, url) in enumerate(missing, 1):
        print(f"  [{i}/{len(missing)}] download {pid} {name[:48]}")
        try:
            data = download(url)
            img = Image.open(io.BytesIO(data))
            cut = process_image(img)
            cut.save(SEALED / f"tcg_{pid}.png", "PNG", optimize=True)
            print(f"    -> tcg_{pid}.png {cut.size}")
        except Exception as e:
            # Try non-rewritten URL if 1000 rewrite failed.
            try:
                raw_url = next(
                    p["imageUrl"]
                    for p in json.loads(
                        (ROOT / "assets/data/pokemon_sealed.json").read_text(
                            encoding="utf-8-sig"
                        )
                    )["products"]
                    if p["productId"] == pid
                )
                if raw_url != url:
                    data = download(raw_url)
                    cut = process_image(Image.open(io.BytesIO(data)))
                    cut.save(SEALED / f"tcg_{pid}.png", "PNG", optimize=True)
                    print(f"    -> fallback tcg_{pid}.png {cut.size}")
                else:
                    print(f"    FAIL {e}")
            except Exception as e2:
                print(f"    FAIL {e2}")

    # 2) Harden every sealed PNG (tcg_* and alternate *-s*).
    targets = sorted(SEALED.glob("tcg_*.png")) + sorted(SEALED.glob("*-s*.png"))
    print(f"Harden/fringe-choke: {len(targets)}")
    for i, path in enumerate(targets, 1):
        before = corner_stats(Image.open(path))
        cut = process_image(Image.open(path))
        cut.save(path, "PNG", optimize=True)
        after = corner_stats(cut)
        print(
            f"  [{i}/{len(targets)}] {path.name} "
            f"clear {before['clear_pct']}->{after['clear_pct']} "
            f"nw {before['near_white_opaque']}->{after['near_white_opaque']} "
            f"cW {before['corner_white_pct']}->{after['corner_white_pct']}"
        )

    # 3) Diagnostic
    png_ids = sorted(
        int(p.stem.split("_")[1]) for p in SEALED.glob("tcg_*.png")
    )
    issues: Counter[str] = Counter()
    rows = []
    for path in sorted(SEALED.glob("*.png")) + sorted(
        (ROOT / "assets/featured_packs").glob("pack_*.png")
    ):
        st = corner_stats(Image.open(path))
        flags = []
        if st["corner_white_pct"] >= 15:
            flags.append("white_corners")
            issues["white_corners"] += 1
        if st["near_white_opaque"] > 25000:
            flags.append("many_near_white_pixels")
            issues["many_near_white_pixels"] += 1
        if st["clear_pct"] < 5 and path.name.startswith("tcg_"):
            flags.append("low_transparency")
            issues["low_transparency"] += 1
        if min(st["size"]) < 220:
            flags.append("low_res")
            issues["low_res"] += 1
        rows.append(
            {
                "path": str(path.relative_to(ROOT)).replace("\\", "/"),
                "stats": st,
                "flags": flags,
            }
        )

    report = {
        "summary": {
            "transparent_png_cutouts": len(png_ids),
            "legacy_jpg_remaining": len(list(SEALED.glob("tcg_*.jpg"))),
            "issue_counts": dict(issues),
            "shop_pokemon_downloaded": len(missing),
        },
        "png_ids": png_ids,
        "dart_snippet": dart_png_ids(png_ids),
        "flagged": [r for r in rows if r["flags"]],
    }
    REPORT.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("\n=== DIAGNOSTIC ===")
    print(json.dumps(report["summary"], indent=2))
    print(f"Flagged: {len(report['flagged'])}")
    for r in report["flagged"][:20]:
        print(f"  {r['path']}: {r['flags']}")
    print(f"Wrote {REPORT}")
    print("\nDart _localPngIds:")
    print(report["dart_snippet"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
