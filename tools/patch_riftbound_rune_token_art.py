"""Rewrite broken Riftbound rune/token imageUrl fields to working hosts."""
from __future__ import annotations

import json
import re
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "assets/data/riftbound_catalog.json"


def status(url: str) -> int | str:
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=12) as r:
            return r.status
    except urllib.error.HTTPError as e:
        return e.code
    except Exception as e:
        return type(e).__name__


def first_ok(urls: list[str]) -> str | None:
    for u in urls:
        if u and status(u) == 200:
            return u
    return None


def main() -> None:
    data = json.loads(CATALOG.read_text(encoding="utf-8-sig"))
    cards = data["cards"]
    by_key = {(c["setCode"], str(c.get("number") or "").upper()): c for c in cards}

    changed = 0
    still_bad = []

    for c in cards:
        num = str(c.get("number") or "")
        raw = num.split("/")[0].strip()
        name = c.get("name") or ""
        setc = c["setCode"]
        pid = c["productId"]

        is_rune = bool(re.match(r"^R\d", raw, re.I))
        is_token = bool(re.match(r"^T\d", raw, re.I))
        is_over = "oversized" in name.lower()
        if not (is_rune or is_token or is_over):
            continue

        candidates: list[str] = []

        # Scrydex tokens (set-local)
        left = raw.split("//")[0].strip()
        right = raw.split("//")[-1].strip() if "//" in raw else ""
        pick = right if ("gold" in name.lower() and right) else left
        tok = re.match(r"^[Tt]0*([0-9]+)$", pick)
        if tok:
            tid = f"T{tok.group(1).zfill(2)}"
            candidates.append(f"https://images.scrydex.com/riftbound/{setc}-{tid}/large")

        # product-images for this pid
        candidates.append(f"https://product-images.tcgplayer.com/{pid}.jpg")
        candidates.append(f"https://product-images.tcgplayer.com/fit-in/874x874/{pid}.jpg")

        # Base rune → sibling Ra
        m = re.match(r"^(R0*\d+)$", raw, re.I)
        if m:
            sib = by_key.get((setc, f"{raw.upper()}A"))
            if sib:
                candidates.append(
                    f"https://product-images.tcgplayer.com/{sib['productId']}.jpg"
                )

        # Letter b rune → sibling a
        m = re.match(r"^(R0*\d+)B$", raw, re.I)
        if m:
            sib = by_key.get((setc, f"{m.group(1).upper()}A"))
            if sib:
                candidates.append(
                    f"https://product-images.tcgplayer.com/{sib['productId']}.jpg"
                )

        candidates.append(c.get("imageUrl") or "")
        candidates.append(c.get("imageUrlSmall") or "")

        hit = first_ok(candidates)
        if hit:
            if c.get("imageUrl") != hit:
                c["imageUrl"] = hit
                # keep a usable small thumb
                if "product-images.tcgplayer.com/" in hit and hit.endswith(".jpg"):
                    c["imageUrlSmall"] = hit
                changed += 1
        else:
            still_bad.append((c["id"], setc, num, name))

    CATALOG.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"updated imageUrl on {changed} cards")
    print(f"still unresolved: {len(still_bad)}")
    for row in still_bad:
        print(" ", row)


if __name__ == "__main__":
    main()
