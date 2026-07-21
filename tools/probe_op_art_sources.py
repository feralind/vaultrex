#!/usr/bin/env python3
"""Probe One Piece art hosts: Scrydex vs Bandai vs TCGPlayer product-images."""

from __future__ import annotations

import json
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "assets" / "data" / "onepiece_catalog.json"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) VaultrexArtProbe/1.0"}


def head_or_get(url: str) -> tuple[str, int | None, str | None, int | None, bytes]:
    req = urllib.request.Request(url, headers=UA)
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            data = r.read(256)
            return (
                "ok",
                r.status,
                r.headers.get("Content-Type"),
                int(r.headers.get("Content-Length") or 0) or None,
                data,
            )
    except urllib.error.HTTPError as e:
        return ("http", e.code, e.headers.get("Content-Type") if e.headers else None, None, b"")
    except Exception as e:  # noqa: BLE001
        return ("err", None, type(e).__name__, None, str(e).encode()[:80])


def main() -> None:
    cards = json.loads(CATALOG.read_text(encoding="utf-8-sig"))["cards"]
    picks = []
    for needle in ("OP01-001", "OP01-002", "OP01-003A", "OP05-119", "OP13-118"):
        for c in cards:
            if c.get("number") == needle:
                picks.append(c)
                break
    if len(picks) < 3:
        picks = cards[:5]

    for c in picks:
        num = c.get("number") or ""
        pid = c["productId"]
        print(f"\n=== {c['id']} {num} {c['name'][:50]}")
        candidates = [
            ("catalog", c.get("imageUrl") or ""),
            ("small", c.get("imageUrlSmall") or ""),
            ("product-images", f"https://product-images.tcgplayer.com/{pid}.jpg"),
            ("product-fit", f"https://product-images.tcgplayer.com/fit-in/874x874/{pid}.jpg"),
            ("bandai", f"https://en.onepiece-cardgame.com/images/cardlist/card/{num}.png"),
            (
                "optcg-api",
                f"https://optcg-api.arjunbansal-ai.workers.dev/images/{num}",
            ),
        ]
        for label, url in candidates:
            if not url:
                continue
            status, code, ctype, clen, head = head_or_get(url)
            magic = head[:12]
            print(
                f"  {label:14} {status:4} code={code} type={ctype} len={clen} magic={magic!r}"
            )
            print(f"                 {url}")


if __name__ == "__main__":
    main()
