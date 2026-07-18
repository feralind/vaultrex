#!/usr/bin/env python3
"""Download MTG (TCGCSV category 1) dumps and build catalog + sealed JSON."""

from __future__ import annotations

import json
import re
import urllib.request
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "tools" / "raw_mtg"
OUT = ROOT / "assets" / "data"
CATEGORY = 1

# Modern main sets — abbreviations match TCGPlayer / TCGCSV groups.
SETS = [
    {"code": "FDN", "name": "Foundations", "groupId": 23556},
    {"code": "MH3", "name": "Modern Horizons 3", "groupId": 23444},
    {"code": "DSK", "name": "Duskmourn: House of Horror", "groupId": 23550},
    {"code": "BLB", "name": "Bloomburrow", "groupId": 23447},
    {"code": "OTJ", "name": "Outlaws of Thunder Junction", "groupId": 23439},
    {"code": "DFT", "name": "Aetherdrift", "groupId": 23874},
]

UA = {"User-Agent": "VaultrexCatalogBot/1.0"}


def fetch_json(url: str) -> dict:
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as res:
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
    if low in {"u", "uncommon"}:
        return "Uncommon"
    if low in {"r", "rare"}:
        return "Rare"
    if low in {"m", "mythic", "mythic rare"} or "mythic" in low:
        return "Epic"
    if low in {"t", "token"} or "token" in low:
        return "Token"
    if low in {"p", "promo"} or "promo" in low:
        return "Promo"
    if low in {"l", "land", "basic land"}:
        return "Common"
    if any(
        k in low
        for k in ("special", "showcase", "borderless", "extended", "serialized")
    ):
        return "Epic" if "mythic" in low or "serialized" in low else "Rare"
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
            r"Booster|Bundle|Box|Collector|Set Booster|Draft Booster|Play Booster|"
            r"VIP|Gift|Commander Deck|Starter|Kit|Case|Pack|Display|Prerelease|"
            r"Theme Booster|Jumpstart|Deck$",
            name,
            re.I,
        )
    )


def sealed_kind(name: str) -> str:
    n = name.lower()
    if "booster box" in n or "display" in n:
        return "box"
    if "booster" in n and "box" not in n:
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
            products_url = f"https://tcgcsv.com/tcgplayer/{CATEGORY}/{gid}/products"
            prices_url = f"https://tcgcsv.com/tcgplayer/{CATEGORY}/{gid}/prices"
            products = fetch_json(products_url)
            prices = fetch_json(prices_url)
            prod_path.write_text(json.dumps(products), encoding="utf-8")
            price_path.write_text(json.dumps(prices), encoding="utf-8")

        price_map = build_price_map(prices.get("results") or [])
        for p in products.get("results") or []:
            pname = str(p.get("name") or "")
            prod_id = int(p["productId"])
            rarity = normalize_rarity(ext(p.get("extendedData"), "Rarity"))
            number = ext(p.get("extendedData"), "Number")
            card_type = ext(p.get("extendedData"), "Card Type") or ext(
                p.get("extendedData"), "Type"
            )
            img_hi, img_small = upgrade_images(str(p.get("imageUrl") or ""))

            market = price_map.get(f"{prod_id}|Normal") or price_map.get(str(prod_id), 0.0)
            foil = price_map.get(f"{prod_id}|Foil")
            if foil is None:
                foil = price_map.get(f"{prod_id}|Holofoil")

            if is_sealed_name(pname) or not number:
                if not is_sealed_name(pname) and not number:
                    continue
                kind = sealed_kind(pname)
                sealed_price = market
                for k in (f"{prod_id}|Normal", f"{prod_id}|", str(prod_id)):
                    if k in price_map and price_map[k] > 0:
                        sealed_price = price_map[k]
                        break
                packs = 30 if kind == "box" else None
                sealed.append(
                    {
                        "id": f"mtg_sku_{prod_id}",
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

            if re.search(r"Booster|Bundle|Box|Deck|Kit|Case|Display", pname, re.I):
                continue

            cards.append(
                {
                    "id": f"mtg_{prod_id}",
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
                    "imageUrlSmall": img_small,
                    "imageKey": f"mtg_{prod_id}",
                }
            )

    # Deduplicate
    by_id = {c["id"]: c for c in cards}
    cards = list(by_id.values())
    by_sku = {s["id"]: s for s in sealed}
    sealed = list(by_sku.values())

    catalog = {
        "generatedAt": datetime.now().isoformat(),
        "source": "tcgcsv.com category 1 (Magic: The Gathering)",
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

    cat_path = OUT / "mtg_catalog.json"
    sealed_path = OUT / "mtg_sealed.json"
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
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
