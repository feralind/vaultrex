"""Probe working art hosts for Riftbound runes/tokens that 403 on tcgplayer-cdn."""
from __future__ import annotations

import json
import re
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
cards = json.loads(
    (ROOT / "assets/data/riftbound_catalog.json").read_text(encoding="utf-8-sig")
)["cards"]


def status(url: str):
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=12) as r:
            return r.status
    except urllib.error.HTTPError as e:
        return e.code
    except Exception as e:
        return type(e).__name__


def main() -> None:
    runes = [
        c
        for c in cards
        if re.match(r"^R0*[1-6]([a-zA-Z])?$", str(c.get("number") or ""), re.I)
    ]
    tokens = [
        c
        for c in cards
        if re.match(r"^T\d", str(c.get("number") or "").split("/")[0].strip(), re.I)
    ]
    print(f"runes={len(runes)} tokens={len(tokens)}")

    fixes = []
    for c in runes + tokens:
        pid = c["productId"]
        candidates = [
            f"https://product-images.tcgplayer.com/{pid}.jpg",
            f"https://product-images.tcgplayer.com/fit-in/874x874/{pid}.jpg",
            c.get("imageUrl") or "",
            c.get("imageUrlSmall") or "",
        ]
        # sibling letter variant for base rune
        num = str(c.get("number") or "")
        if re.match(r"^R0*\d+$", num, re.I):
            for o in cards:
                if o["setCode"] == c["setCode"] and str(o.get("number") or "").upper() == f"{num.upper()}A":
                    candidates.append(
                        f"https://product-images.tcgplayer.com/{o['productId']}.jpg"
                    )
                    break
        # scrydex token
        left = num.split("/")[0].strip().split("//")[0].strip()
        tok = re.match(r"^[Tt]0*([0-9]+)$", left)
        if tok:
            tid = f"T{tok.group(1).zfill(2)}"
            candidates.append(
                f"https://images.scrydex.com/riftbound/{c['setCode']}-{tid}/large"
            )

        hit = None
        for u in candidates:
            if not u:
                continue
            st = status(u)
            if st == 200:
                hit = u
                break
        print(
            c["setCode"],
            num,
            c["name"][:28],
            "->",
            "OK" if hit else "NONE",
            (hit or "")[-55:],
        )
        if hit and hit != c.get("imageUrl"):
            fixes.append((c["id"], hit))

    print(f"suggested catalog URL rewrites: {len(fixes)}")
    out = ROOT / "tools/rune_token_art_fixes.json"
    out.write_text(json.dumps(fixes, indent=2), encoding="utf-8")
    print("wrote", out)


if __name__ == "__main__":
    main()
