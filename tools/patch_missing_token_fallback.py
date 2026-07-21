"""Point the 3 tokens with no public CDN art at a local fallback asset."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "assets/data/riftbound_catalog.json"
FALLBACK = "assets/card_backs/riftbound_back.png"
MISSING = {"rb_678186", "rb_678187", "rb_696621", "rb_696620"}  # include Gold T08 too if scry fails


def main() -> None:
    data = json.loads(CATALOG.read_text(encoding="utf-8-sig"))
    n = 0
    for c in data["cards"]:
        if c["id"] in MISSING:
            c["imageUrl"] = FALLBACK
            c["imageUrlSmall"] = FALLBACK
            n += 1
            print("fallback", c["id"], c["name"], c["number"])
    CATALOG.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("patched", n)


if __name__ == "__main__":
    main()
