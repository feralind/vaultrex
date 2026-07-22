#!/usr/bin/env python3
"""Download Yu-Gi-Oh! card art and rewrite catalog to local assets.

YGOPRODeck forbids continual hotlinking (IP blacklist) and serves no CORS
headers — Flutter Web CanvasKit cannot decode those URLs, so every card shows
the placeholder. Mirror One Piece: bundle under assets/card_art/yugioh/.

Usage:
  python tools/cache_yugioh_art.py
  python tools/cache_yugioh_art.py --workers 4 --quality 72
"""

from __future__ import annotations

import argparse
import io
import json
import re
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "assets" / "data" / "yugioh_catalog.json"
ART_DIR = ROOT / "assets" / "card_art" / "yugioh"
UA = {"User-Agent": "BindoraYgoArtCache/1.0 (+local rehost; not hotlink)"}

YGO_RE = re.compile(
    r"https?://images\.ygoprodeck\.com/images/cards(?:_small)?/(\d+)\.jpg",
    re.I,
)
TCG_RE = re.compile(
    r"https?://(?:tcgplayer-cdn\.tcgplayer\.com/product/(\d+)|"
    r"product-images\.tcgplayer\.com/(\d+))",
    re.I,
)


def asset_key(url: str, product_id: int | None) -> str | None:
    m = YGO_RE.search(url or "")
    if m:
        return f"pc_{m.group(1)}"
    m = TCG_RE.search(url or "")
    if m:
        pid = m.group(1) or m.group(2)
        return f"tcg_{pid}"
    if product_id and product_id > 0:
        return f"tcg_{product_id}"
    return None


def fetch(url: str, timeout: float = 30) -> bytes | None:
    try:
        req = urllib.request.Request(url, headers=UA)
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.read()
    except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError, OSError):
        return None


def to_webp(data: bytes, quality: int) -> bytes | None:
    try:
        im = Image.open(io.BytesIO(data))
        if im.mode not in ("RGB", "RGBA"):
            im = im.convert("RGB")
        # Cap long edge so inspect stays sharp without ballooning APK size.
        w, h = im.size
        long_edge = max(w, h)
        if long_edge > 900:
            scale = 900 / long_edge
            im = im.resize(
                (max(1, int(w * scale)), max(1, int(h * scale))),
                Image.Resampling.LANCZOS,
            )
        out = io.BytesIO()
        im.save(out, format="WEBP", quality=quality, method=4)
        return out.getvalue()
    except Exception:
        return None


def download_one(
    key: str,
    urls: list[str],
    quality: int,
    force: bool,
) -> tuple[str, str]:
    dest = ART_DIR / f"{key}.webp"
    if dest.exists() and dest.stat().st_size > 500 and not force:
        return key, "exists"
    for url in urls:
        raw = fetch(url)
        if not raw:
            continue
        webp = to_webp(raw, quality)
        if not webp:
            continue
        dest.write_bytes(webp)
        return key, f"ok:{len(webp)}"
    return key, "fail"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--workers", type=int, default=3)
    ap.add_argument("--quality", type=int, default=72)
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--delay", type=float, default=0.12, help="pause between job starts")
    args = ap.parse_args()

    ART_DIR.mkdir(parents=True, exist_ok=True)
    data = json.loads(CATALOG.read_text(encoding="utf-8-sig"))
    cards = data.get("cards") or []

    # key -> preferred download URLs (full size first)
    jobs: dict[str, list[str]] = {}
    card_keys: list[str | None] = []

    for c in cards:
        url = str(c.get("imageUrl") or "")
        # Prefer full-size YGO URL even if catalog already points at local/old.
        key = None
        if url.startswith("assets/card_art/yugioh/"):
            stem = Path(url).stem
            key = stem
            card_keys.append(key)
            continue
        key = asset_key(url, int(c.get("productId") or 0))
        card_keys.append(key)
        if not key:
            continue
        if key in jobs:
            continue
        urls: list[str] = []
        m = YGO_RE.search(url)
        if m:
            pc = m.group(1)
            urls.append(f"https://images.ygoprodeck.com/images/cards/{pc}.jpg")
            urls.append(f"https://images.ygoprodeck.com/images/cards_small/{pc}.jpg")
        else:
            pid = int(c.get("productId") or 0)
            if pid > 0:
                urls.append(
                    f"https://tcgplayer-cdn.tcgplayer.com/product/{pid}_in_1000x1000.jpg"
                )
                urls.append(f"https://product-images.tcgplayer.com/{pid}.jpg")
            if url.startswith("http"):
                urls.insert(0, url)
        jobs[key] = urls

    print(f"cards={len(cards)} unique_keys={len(jobs)} dir={ART_DIR}")

    ok = fail = skipped = 0
    with ThreadPoolExecutor(max_workers=max(1, args.workers)) as pool:
        futs = []
        for i, (key, urls) in enumerate(jobs.items()):
            if args.delay > 0 and i > 0:
                time.sleep(args.delay)
            futs.append(
                pool.submit(download_one, key, urls, args.quality, args.force)
            )
        for fut in as_completed(futs):
            key, status = fut.result()
            if status == "exists":
                skipped += 1
            elif status.startswith("ok"):
                ok += 1
            else:
                fail += 1
            done = ok + fail + skipped
            if done % 50 == 0 or done == len(jobs):
                print(f"  progress {done}/{len(jobs)} ok={ok} skip={skipped} fail={fail}")

    rewritten = 0
    missing = 0
    for c, key in zip(cards, card_keys):
        if not key:
            missing += 1
            continue
        rel = f"assets/card_art/yugioh/{key}.webp"
        path = ROOT / rel
        if not path.exists() or path.stat().st_size < 500:
            missing += 1
            continue
        c["imageUrl"] = rel
        c["imageUrlSmall"] = rel
        rewritten += 1

    data["imageSource"] = (
        "Local assets/card_art/yugioh (YGOPRODeck HD rehosted; no hotlink)"
    )
    data["artCachedAt"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    CATALOG.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(f"rewrote catalog imageUrls={rewritten} missing={missing}")
    print(f"download ok={ok} skipped={skipped} fail={fail}")
    return 0 if missing == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
