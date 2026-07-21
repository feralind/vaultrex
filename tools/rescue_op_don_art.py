#!/usr/bin/env python3
"""Rescue remaining OP cards (DON!! etc.) from TCGPlayer product images."""

from __future__ import annotations

import json
import urllib.request
from pathlib import Path

from rebuild_op_art import scrub_bytes

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "assets" / "data" / "onepiece_catalog.json"
ART = ROOT / "assets" / "card_art" / "onepiece"
UA = {"User-Agent": "VaultrexOpArt/1.0"}


def fetch(url: str) -> bytes | None:
    try:
        req = urllib.request.Request(url, headers=UA)
        with urllib.request.urlopen(req, timeout=25) as r:
            data = r.read()
            return data if data and len(data) > 2000 else None
    except Exception:
        return None


def main() -> None:
    d = json.loads(CATALOG.read_text(encoding="utf-8-sig"))
    ART.mkdir(parents=True, exist_ok=True)
    fail = [c for c in d["cards"] if not str(c.get("imageUrl", "")).startswith("assets/")]
    print("fixing", len(fail))
    ok = 0
    for c in fail:
        pid = c.get("productId")
        urls = [
            f"https://product-images.tcgplayer.com/{pid}.jpg",
            f"https://tcgplayer-cdn.tcgplayer.com/product/{pid}_in_1000x1000.jpg",
            c.get("imageUrl") or "",
        ]
        data = None
        for u in urls:
            if not u:
                continue
            data = fetch(u)
            if data:
                break
        if not data:
            print("still fail", c["id"], c.get("number"))
            continue
        scrubbed = scrub_bytes(data)
        out = ART / f"{c['id']}.webp"
        out.write_bytes(scrubbed)
        rel = f"assets/card_art/onepiece/{c['id']}.webp"
        c["imageUrl"] = rel
        c["imageUrlSmall"] = rel
        ok += 1
    CATALOG.write_text(
        json.dumps(d, ensure_ascii=False, separators=(",", ":")), encoding="utf-8"
    )
    left = sum(1 for c in d["cards"] if not str(c.get("imageUrl", "")).startswith("assets/"))
    print("rescued", ok, "remaining", left)


if __name__ == "__main__":
    main()
