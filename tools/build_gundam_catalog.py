#!/usr/bin/env python3
"""Download Gundam Card Game (TCGCSV category 86) and build catalog + sealed JSON."""

from __future__ import annotations

import json
import re
import urllib.request
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "tools" / "raw_gundam"
OUT = ROOT / "assets" / "data"
CATEGORY = 86

# First-wave sets — groupIds from TCGCSV category 86.
SETS = [
    {"code": "GD01", "name": "Newtype Rising", "groupId": 24221},
    {"code": "GD02", "name": "Dual Impact", "groupId": 24408},
    {"code": "GD03", "name": "Steel Requiem", "groupId": 24522},
    {"code": "GD04", "name": "Phantom Aria", "groupId": 24633},
    {"code": "GD05", "name": "Freedom Ascension", "groupId": 24699},
    {"code": "ST01", "name": "Starter Deck 01: Heroic Beginnings", "groupId": 24222},
    {"code": "ST02", "name": "Starter Deck 02: Wings of Advance", "groupId": 24223},
    {"code": "EB01", "name": "Eternal Nexus", "groupId": 24693},
]

UA = {"User-Agent": "VaultrexCatalogBot/1.0"}


def fetch_json(url: str) -> dict:
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=90) as res:
        return json.loads(res.read().decode("utf-8"))


def ext(extended: list | None, key: str) -> str | None:
    if not extended:
        return None
    for e in extended:
        if e.get("name") == key or e.get("displayName") == key:
            v = e.get("value")
            return None if v is None else str(v)
    return None


def normalize_rarity(r: str | None) -> str:
    if not r:
        return "Common"
    t = r.strip()
    low = t.lower()
    if low in {"c", "common"}:
        return "Common"
    if low in {"u", "uc", "uncommon"}:
        return "Uncommon"
    if low in {"r", "rare"}:
        return "Rare"
    if low in {"lr", "legendary rare", "sr", "super rare"}:
        return "Epic"
    if low in {"scr", "secret rare", "sec", "ar", "alternate art"}:
        return "Showcase"
    if low in {"pr", "promo", "p"}:
        return "Promo"
    if "secret" in low or "alternate" in low:
        return "Showcase"
    if "legendary" in low or "super" in low:
        return "Epic"
    return t


def upgrade_images(img: str) -> tuple[str, str]:
    if not img:
        return "", ""
    if img.endswith("_200w.jpg"):
        return img.replace("_200w.jpg", "_in_1000x1000.jpg"), img
    if img.endswith("_400w.jpg"):
        return (
            img.replace("_400w.jpg", "_in_1000x1000.jpg"),
            img.replace("_400w.jpg", "_200w.jpg"),
        )
    if re.search(r"_in_\d+x\d+\.jpg$", img):
        return img, re.sub(r"_in_\d+x\d+\.jpg$", "_200w.jpg", img)
    return img, img


def is_sealed_name(name: str) -> bool:
    return bool(
        re.search(
            r"Booster|Bundle|Box|Collector|Display|Case|Pack|Starter Deck|"
            r"Deck Build|Deck Set",
            name,
            re.I,
        )
    )


def sealed_kind(name: str) -> str:
    n = name.lower()
    if "booster box" in n or ("box" in n and "pack" not in n and "starter" not in n):
        if "case" in n:
            return "other"
        return "box"
    if "booster" in n or "pack" in n:
        return "pack"
    if "deck" in n:
        return "deck"
    return "other"


def build_price_map(prices: list) -> dict:
    out: dict[str, float] = {}
    for pr in prices:
        prod = str(pr.get("productId"))
        mp = pr.get("marketPrice")
        if mp is None:
            mp = pr.get("midPrice")
        if mp is None:
            mp = pr.get("lowPrice")
        if mp is None:
            mp = 0
        mp = float(mp)
        sub = pr.get("subTypeName") or ""
        out[f"{prod}|{sub}"] = mp
        if prod not in out or mp > out[prod]:
            out[prod] = mp
    return out


def normalize_number(raw: str | None, set_code: str) -> str | None:
    if not raw:
        return None
    n = raw.strip()
    m = re.match(r"^([A-Z0-9]+)-(\d+)([A-Za-z]?)$", n, re.I)
    if m:
        return f"{m.group(1).upper()}-{m.group(2).zfill(3)}{(m.group(3) or '').upper()}"
    m2 = re.match(r"^0*(\d+)([A-Za-z]?)$", n)
    if m2:
        return f"{set_code.upper()}-{m2.group(1).zfill(3)}{(m2.group(2) or '').upper()}"
    return n


def main() -> int:
    RAW.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)

    cards: list[dict] = []
    sealed: list[dict] = []

    for s in SETS:
        code, name, gid = s["code"], s["name"], s["groupId"]
        prod_path = RAW / f"products_{code}.json"
        price_path = RAW / f"prices_{code}.json"
        if prod_path.exists() and price_path.exists():
            print(f"local {code} group={gid}")
            products = json.loads(prod_path.read_text(encoding="utf-8"))
            prices = json.loads(price_path.read_text(encoding="utf-8"))
        else:
            print(f"fetch {code} group={gid}")
            products = fetch_json(
                f"https://tcgcsv.com/tcgplayer/{CATEGORY}/{gid}/products"
            )
            prices = fetch_json(
                f"https://tcgcsv.com/tcgplayer/{CATEGORY}/{gid}/prices"
            )
            prod_path.write_text(json.dumps(products), encoding="utf-8")
            price_path.write_text(json.dumps(prices), encoding="utf-8")

        price_map = build_price_map(prices.get("results") or [])
        for p in products.get("results") or []:
            pname = str(p.get("name") or "")
            prod_id = int(p["productId"])
            card_type = (
                ext(p.get("extendedData"), "Card Type")
                or ext(p.get("extendedData"), "CardType")
                or ext(p.get("extendedData"), "Type")
            )
            rarity = normalize_rarity(ext(p.get("extendedData"), "Rarity"))
            number_raw = ext(p.get("extendedData"), "Number") or ext(
                p.get("extendedData"), "#"
            )
            img_hi, img_small = upgrade_images(str(p.get("imageUrl") or ""))

            market = price_map.get(f"{prod_id}|Normal") or price_map.get(
                str(prod_id), 0.0
            )
            foil = price_map.get(f"{prod_id}|Foil")
            if foil is None:
                foil = price_map.get(f"{prod_id}|Holofoil")

            if is_sealed_name(pname) or not number_raw:
                if is_sealed_name(pname):
                    kind = sealed_kind(pname)
                    sealed_price = market
                    for k in (f"{prod_id}|Normal", f"{prod_id}|", str(prod_id)):
                        if k in price_map and price_map[k] > 0:
                            sealed_price = price_map[k]
                            break
                    packs = 24 if kind == "box" else None
                    sealed.append(
                        {
                            "id": f"gd_sku_{prod_id}",
                            "productId": prod_id,
                            "setCode": code,
                            "setName": name,
                            "name": pname,
                            "kind": kind,
                            "marketPrice": round(float(sealed_price), 2),
                            "imageUrl": img_hi,
                            "imageUrlSmall": img_small,
                            "packsPerBox": packs,
                        }
                    )
                continue

            number = normalize_number(number_raw, code)
            if not number:
                continue

            cards.append(
                {
                    "id": f"gd_{prod_id}",
                    "productId": prod_id,
                    "setCode": code,
                    "setName": name,
                    "name": pname,
                    "number": number,
                    "rarity": rarity,
                    "cardType": card_type,
                    "domain": None,
                    "marketPrice": round(float(market), 2),
                    "foilMarketPrice": (
                        round(float(foil), 2) if foil is not None else None
                    ),
                    "imageUrl": img_hi,
                    "imageUrlSmall": img_small or img_hi,
                    "imageKey": f"gd_{prod_id}",
                }
            )

    by_id = {c["id"]: c for c in cards}
    cards = list(by_id.values())
    by_sku = {s["id"]: s for s in sealed}
    sealed = [s for s in by_sku.values() if s["kind"] in ("pack", "box", "deck")]

    catalog = {
        "generatedAt": datetime.now().isoformat(),
        "source": "tcgcsv.com category 86 (Gundam Card Game)",
        "setCodes": [s["code"] for s in SETS],
        "cardCount": len(cards),
        "cards": cards,
    }
    sealed_out = {
        "generatedAt": catalog["generatedAt"],
        "source": catalog["source"],
        "productCount": len(sealed),
        "products": sealed,
    }

    cat_path = OUT / "gundam_catalog.json"
    sealed_path = OUT / "gundam_sealed.json"
    cat_path.write_text(
        "\ufeff" + json.dumps(catalog, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    sealed_path.write_text(
        "\ufeff" + json.dumps(sealed_out, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    print(f"wrote {cat_path.name} cards={len(cards)}")
    print(f"wrote {sealed_path.name} products={len(sealed)}")
    chase = sorted(cards, key=lambda c: c["marketPrice"], reverse=True)[:12]
    print("top chase:")
    for c in chase:
        print(f"  {c['id']:16} ${c['marketPrice']:8.2f}  {c['name'][:48]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
