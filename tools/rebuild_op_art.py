#!/usr/bin/env python3
"""Rebuild One Piece catalog imageUrls to Limitless CDN (webp) with Bandai/TCG fallbacks.

Bandai stamps SAMPLE on all official digital renders (Scrydex/Limitless/TCGPlayer).
This script switches the primary host to Limitless for faster webp and correct
parallel (_p1) mapping. Optional --scrub writes desampled local webp assets
(OpenCV inpaint) and rewrites imageUrl to assets/card_art/onepiece/*.webp.
"""

from __future__ import annotations

import argparse
import json
import re
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "assets" / "data" / "onepiece_catalog.json"
ART_DIR = ROOT / "assets" / "card_art" / "onepiece"
UA = {"User-Agent": "VaultrexOpArt/1.0"}


def limitless_candidates(number: str) -> list[str]:
    n = (number or "").strip().upper()
    if not n or n.startswith("DON"):
        return []
    m = re.match(r"^((?:OP|ST|EB|PRB)\d+)-(\d{3})([A-Z]?)$", n)
    if not m:
        return []
    setc, digits, suf = m.group(1), m.group(2), m.group(3)
    core = f"{setc}-{digits}"
    base = f"https://limitlesstcg.nyc3.cdn.digitaloceanspaces.com/one-piece/{setc}"
    out: list[str] = []
    if suf:
        idx = ord(suf) - ord("A") + 1
        out.append(f"{base}/{core}_p{idx}_EN.webp")
        out.append(f"{base}/{core}{suf}_EN.webp")
    out.append(f"{base}/{core}_EN.webp")
    return out


def bandai_url(number: str) -> str | None:
    n = (number or "").strip().upper()
    if not n or n.startswith("DON"):
        return None
    m = re.match(r"^((?:OP|ST|EB|PRB)\d+)-(\d{3})([A-Z]?)$", n)
    if not m:
        return None
    setc, digits, suf = m.group(1), m.group(2), m.group(3)
    core = f"{setc}-{digits}"
    if suf:
        idx = ord(suf) - ord("A") + 1
        return f"https://en.onepiece-cardgame.com/images/cardlist/card/{core}_p{idx}.png"
    return f"https://en.onepiece-cardgame.com/images/cardlist/card/{core}.png"


def fetch(url: str, timeout: float = 25) -> bytes | None:
    try:
        req = urllib.request.Request(url, headers=UA)
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.read()
    except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError, OSError):
        return None


def head_ok(url: str) -> bool:
    try:
        req = urllib.request.Request(url, headers=UA, method="HEAD")
        with urllib.request.urlopen(req, timeout=12) as r:
            return 200 <= r.status < 400
    except Exception:
        # Some CDNs reject HEAD — try tiny GET
        data = fetch(url, timeout=12)
        return bool(data and len(data) > 1000)


def pick_limitless(number: str) -> str | None:
    for u in limitless_candidates(number):
        if head_ok(u):
            return u
    return None


def sample_template(w: int, scale: float) -> np.ndarray:
    fw = max(8, int(w * scale * 4.6))
    fh = max(8, int(w * scale * 1.1))
    pil = Image.new("L", (fw, fh), 0)
    d = ImageDraw.Draw(pil)
    try:
        font = ImageFont.truetype("arialbd.ttf", max(10, int(fh * 0.9)))
    except OSError:
        font = ImageFont.load_default()
    bbox = d.textbbox((0, 0), "SAMPLE", font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text(((fw - tw) // 2, (fh - th) // 2), "SAMPLE", fill=255, font=font)
    return np.array(pil)


def scrub_sample(bgr: np.ndarray) -> np.ndarray:
    """Hard-mask SAMPLE glyph via template match + Telea inpaint."""
    h, w = bgr.shape[:2]
    gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)
    best: tuple[float, tuple[int, int], np.ndarray] | None = None
    for scale in np.linspace(0.15, 0.27, 18):
        templ = sample_template(w, float(scale))
        if templ.shape[0] >= h or templ.shape[1] >= w:
            continue
        res = cv2.matchTemplate(gray, templ, cv2.TM_CCOEFF_NORMED)
        maxv = float(cv2.minMaxLoc(res)[1])
        maxl = cv2.minMaxLoc(res)[3]
        if best is None or maxv > best[0]:
            best = (maxv, maxl, templ)
    if best is None or best[0] < 0.22:
        return bgr
    _, (x, y), templ = best
    th, tw = templ.shape
    mask = np.zeros((h, w), np.uint8)
    mask[y : y + th, x : x + tw][templ > 20] = 255
    mask = cv2.dilate(
        mask, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (11, 11)), iterations=3
    )
    return cv2.inpaint(bgr, mask, 40, cv2.INPAINT_TELEA)


def scrub_bytes(data: bytes) -> bytes:
    arr = np.frombuffer(data, dtype=np.uint8)
    bgr = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if bgr is None:
        # PIL fallback for webp
        from io import BytesIO

        rgb = np.array(Image.open(BytesIO(data)).convert("RGB"))
        bgr = cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)
    out = scrub_sample(bgr)
    # Downscale slightly + webp for size
    h, w = out.shape[:2]
    if w > 520:
        nh = int(h * (520 / w))
        out = cv2.resize(out, (520, nh), interpolation=cv2.INTER_AREA)
    rgb = cv2.cvtColor(out, cv2.COLOR_BGR2RGB)
    from io import BytesIO

    buf = BytesIO()
    Image.fromarray(rgb).save(buf, format="WEBP", quality=78, method=4)
    return buf.getvalue()


def resolve_remote(card: dict) -> str | None:
    number = card.get("number") or ""
    lim = pick_limitless(number)
    if lim:
        return lim
    b = bandai_url(number)
    if b and head_ok(b):
        return b
    # keep existing scrydex / tcgplayer if present
    existing = card.get("imageUrl") or ""
    if existing:
        return existing
    pid = card.get("productId")
    if pid:
        return f"https://product-images.tcgplayer.com/{pid}.jpg"
    return None


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--scrub",
        action="store_true",
        help="Download + desample SAMPLE watermark into local webp assets",
    )
    ap.add_argument("--workers", type=int, default=8)
    ap.add_argument("--limit", type=int, default=0, help="Process only N cards (debug)")
    args = ap.parse_args()

    catalog = json.loads(CATALOG.read_text(encoding="utf-8-sig"))
    cards = catalog["cards"]
    if args.limit:
        cards = cards[: args.limit]

    print(f"cards={len(cards)} scrub={args.scrub}")
    if args.scrub:
        ART_DIR.mkdir(parents=True, exist_ok=True)

    def work(card: dict) -> tuple[str, str | None, str]:
        cid = card["id"]
        remote = resolve_remote(card)
        if not remote:
            return cid, None, "no-url"
        if not args.scrub:
            return cid, remote, "remote"
        # Prefer Limitless bytes for scrub source
        data = None
        for u in limitless_candidates(card.get("number") or "") + [remote]:
            data = fetch(u)
            if data and len(data) > 2000:
                remote = u
                break
        if not data:
            return cid, remote, "fetch-fail"
        try:
            scrubbed = scrub_bytes(data)
        except Exception as e:  # noqa: BLE001
            return cid, remote, f"scrub-fail:{type(e).__name__}"
        out = ART_DIR / f"{cid}.webp"
        out.write_bytes(scrubbed)
        return cid, f"assets/card_art/onepiece/{cid}.webp", "scrubbed"

    results = {}
    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = {ex.submit(work, c): c["id"] for c in cards}
        done = 0
        for fut in as_completed(futs):
            cid, url, status = fut.result()
            results[cid] = (url, status)
            done += 1
            if done % 50 == 0 or done == len(cards):
                print(f"  {done}/{len(cards)}")

    by_status: dict[str, int] = {}
    for c in catalog["cards"]:
        if c["id"] not in results:
            continue
        url, status = results[c["id"]]
        by_status[status] = by_status.get(status, 0) + 1
        if url:
            # Keep Scrydex in imageUrl if we only remapped remote — store limitless as primary
            c["imageUrl"] = url
            if status == "scrubbed":
                c["imageUrlSmall"] = url
            elif url.endswith(".webp") and "limitless" in url:
                c["imageUrlSmall"] = url
    catalog["imageSource"] = (
        "limitless+desample-local"
        if args.scrub
        else "limitlesstcg CDN (Bandai SAMPLE on official renders)"
    )
    CATALOG.write_text(
        json.dumps(catalog, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    print("status counts", by_status)
    if args.scrub:
        total = sum(p.stat().st_size for p in ART_DIR.glob("*.webp"))
        print(f"art dir bytes={total} files={len(list(ART_DIR.glob('*.webp')))}")


if __name__ == "__main__":
    main()
