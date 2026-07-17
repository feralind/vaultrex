#!/usr/bin/env python3
"""Remove studio backgrounds from sealed / featured pack product art.

Writes transparent PNGs next to (or replacing) sources, then prints a
diagnostic report (corner opacity, white-halo risk, resolution).
"""

from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path

from PIL import Image
from rembg import remove

ROOT = Path(__file__).resolve().parents[1]
SEALED = ROOT / "assets" / "sealed"
FEATURED = ROOT / "assets" / "featured_packs"
REPORT = ROOT / "tools" / "art_bg_diagnostic.json"


def corner_stats(img: Image.Image, pad: int = 4) -> dict:
    """Sample corners for opaque near-white / near-black pixels."""
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
    opaque_white = 0
    opaque_black = 0
    transparent = 0
    for r, g, b, a in samples:
        if a < 20:
            transparent += 1
            continue
        mn, mx = min(r, g, b), max(r, g, b)
        if mx - mn <= 14 and mn >= 245:
            opaque_white += 1
        if mx - mn <= 14 and mx <= 18:
            opaque_black += 1
    n = max(1, len(samples))
    return {
        "corner_transparent_pct": round(100 * transparent / n, 1),
        "corner_white_pct": round(100 * opaque_white / n, 1),
        "corner_black_pct": round(100 * opaque_black / n, 1),
        "size": [w, h],
    }


def alpha_coverage(img: Image.Image) -> float:
    a = img.convert("RGBA").getchannel("A")
    hist = a.histogram()
    clear = sum(hist[:12])
    return round(100 * (1 - clear / max(1, sum(hist))), 1)


def needs_cutout(path: Path) -> bool:
    img = Image.open(path).convert("RGBA")
    st = corner_stats(img)
    # Already mostly transparent at corners → leave alone unless still white.
    if st["corner_transparent_pct"] >= 70 and st["corner_white_pct"] < 5:
        return False
    if st["corner_white_pct"] >= 15 or st["corner_black_pct"] >= 15:
        return True
    # Opaque JPEG / PNG with no alpha usage.
    if path.suffix.lower() in {".jpg", ".jpeg"}:
        return True
    if alpha_coverage(img) > 98 and (
        st["corner_white_pct"] >= 5 or st["corner_black_pct"] >= 5
    ):
        return True
    return False


def process_file(src: Path, out: Path) -> dict:
    before = corner_stats(Image.open(src))
    data = src.read_bytes()
    cut = remove(data)
    img = Image.open(__import__("io").BytesIO(cut)).convert("RGBA")
    # Tight crop to non-transparent content with small padding.
    bbox = img.getbbox()
    if bbox:
        l, t, r, b = bbox
        pad = 4
        l = max(0, l - pad)
        t = max(0, t - pad)
        r = min(img.width, r + pad)
        b = min(img.height, b + pad)
        img = img.crop((l, t, r, b))
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, "PNG", optimize=True)
    after = corner_stats(img)
    return {
        "src": str(src.relative_to(ROOT)).replace("\\", "/"),
        "out": str(out.relative_to(ROOT)).replace("\\", "/"),
        "before": before,
        "after": after,
        "alpha_subject_pct": alpha_coverage(img),
        "bytes_in": src.stat().st_size,
        "bytes_out": out.stat().st_size,
    }


def collect_targets() -> list[tuple[Path, Path]]:
    targets: list[tuple[Path, Path]] = []
    # Sealed TCG product shots: always emit PNG cutouts.
    for src in sorted(SEALED.glob("tcg_*")):
        if src.suffix.lower() not in {".jpg", ".jpeg", ".png", ".webp"}:
            continue
        m = re.match(r"tcg_(\d+)\.", src.name, re.I)
        if not m:
            continue
        # Prefer processing JPG when both exist; also reprocess opaque PNGs.
        out = SEALED / f"tcg_{m.group(1)}.png"
        if src.suffix.lower() == ".png" and out.exists():
            # Reprocess if still has studio corners.
            if not needs_cutout(src):
                continue
        if src.suffix.lower() in {".jpg", ".jpeg"}:
            targets.append((src, out))
        elif src.suffix.lower() == ".png":
            targets.append((src, out))

    # Alternate sealed pack arts (OGN-s*, etc.)
    for src in sorted(SEALED.glob("*-s*.png")):
        if needs_cutout(src):
            targets.append((src, src))

    # Featured Vaultrex rip packs (often black studio / fringe).
    for src in sorted(FEATURED.glob("pack_*.png")):
        if needs_cutout(src):
            targets.append((src, src))

    # De-dupe by output path (prefer JPG source when both listed).
    by_out: dict[Path, Path] = {}
    for src, out in targets:
        prev = by_out.get(out)
        if prev is None:
            by_out[out] = src
        elif prev.suffix.lower() == ".png" and src.suffix.lower() in {
            ".jpg",
            ".jpeg",
        }:
            by_out[out] = src
    return [(src, out) for out, src in by_out.items()]


def dart_png_ids(processed_ids: set[int]) -> str:
    ids = sorted(processed_ids)
    lines = ["  static const Set<int> _localPngIds = {"]
    for i in ids:
        lines.append(f"    {i},")
    lines.append("  };")
    return "\n".join(lines)


def main() -> int:
    pairs = collect_targets()
    print(f"Targets: {len(pairs)}")
    results = []
    png_ids: set[int] = set()
    for i, (src, out) in enumerate(pairs, 1):
        print(f"[{i}/{len(pairs)}] {src.name} -> {out.name}")
        try:
            row = process_file(src, out)
            results.append(row)
            m = re.search(r"tcg_(\d+)", out.name)
            if m:
                png_ids.add(int(m.group(1)))
            # Also keep existing png ids even if skipped.
        except Exception as e:
            print(f"  FAIL: {e}", file=sys.stderr)
            results.append({"src": str(src), "error": str(e)})

    # Include any existing tcg_*.png ids for dart update.
    for p in SEALED.glob("tcg_*.png"):
        m = re.match(r"tcg_(\d+)\.png$", p.name, re.I)
        if m:
            png_ids.add(int(m.group(1)))

    # Diagnostic pass over all sealed + featured after processing.
    diag_rows = []
    issues = Counter()
    for folder in (SEALED, FEATURED):
        for path in sorted(folder.glob("*")):
            if path.suffix.lower() not in {".png", ".jpg", ".jpeg", ".webp"}:
                continue
            st = corner_stats(Image.open(path))
            cov = alpha_coverage(Image.open(path)) if path.suffix.lower() == ".png" else 100.0
            flags = []
            if st["corner_white_pct"] >= 20:
                flags.append("white_corners")
                issues["white_corners"] += 1
            if st["corner_black_pct"] >= 20 and path.suffix.lower() != ".jpg":
                flags.append("black_corners")
                issues["black_corners"] += 1
            if path.suffix.lower() in {".jpg", ".jpeg"}:
                flags.append("still_jpg")
                issues["still_jpg"] += 1
            if path.suffix.lower() == ".png" and st["corner_transparent_pct"] < 40:
                flags.append("weak_alpha")
                issues["weak_alpha"] += 1
            if min(st["size"]) < 200:
                flags.append("low_res")
                issues["low_res"] += 1
            diag_rows.append(
                {
                    "path": str(path.relative_to(ROOT)).replace("\\", "/"),
                    "stats": st,
                    "alpha_subject_pct": cov,
                    "flags": flags,
                }
            )

    report = {
        "processed": results,
        "png_ids": sorted(png_ids),
        "issue_counts": dict(issues),
        "assets": diag_rows,
        "dart_snippet": dart_png_ids(png_ids),
    }
    REPORT.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("\n=== DIAGNOSTIC ===")
    print(f"Processed: {len(results)}")
    print(f"PNG cutout ids: {len(png_ids)}")
    print(f"Issue counts: {dict(issues)}")
    flagged = [r for r in diag_rows if r["flags"]]
    print(f"Flagged assets: {len(flagged)} / {len(diag_rows)}")
    for r in flagged[:25]:
        print(f"  {r['path']}: {', '.join(r['flags'])}")
    if len(flagged) > 25:
        print(f"  ... +{len(flagged) - 25} more")
    print(f"Wrote {REPORT}")
    print("\nDart _localPngIds snippet:")
    print(report["dart_snippet"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
