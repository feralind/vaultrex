#!/usr/bin/env python3
"""Download One Piece (TCGCSV category 68) dumps and build catalog + sealed JSON."""

from __future__ import annotations

import json
import re
import urllib.request
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "tools" / "raw_onepiece"
OUT = ROOT / "assets" / "data"
CATEGORY = 68

# Launch sets — groupIds match TcgcsvPriceRefresh.onepieceGroups / TCGCSV.
SETS = [
    {"code": "OP01", "name": "Romance Dawn", "groupId": 3188},
    {"code": "OP02", "name": "Paramount War", "groupId": 17698},
    {"code": "OP05", "name": "Awakening of the New Era", "groupId": 23213},
    {"code": "OP09", "name": "Emperors in the New World", "groupId": 23589},
    {"code": "OP13", "name": "Carrying On His Will", "groupId": 24303},
    {"code": "PRB01", "name": "Premium Booster -The Best-", "groupId": 23496},
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


def normalize_rarity(r: str | None, card_type: str | None = None) -> str:
    """Map OPTCG rarities into Bindora parseRarity strings."""
    if not r:
        if card_type and "don" in card_type.lower():
            return "Token"
        return "Common"
    t = r.strip()
    low = t.lower()
    if low in {"c", "common"}:
        return "Common"
    if low in {"uc", "u", "uncommon"}:
        return "Uncommon"
    if low in {"r", "rare"}:
        return "Rare"
    if low in {"sr", "super rare"}:
        return "Epic"
    if low in {"sec", "secret rare", "sp", "special", "manga", "tr", "treasure rare"}:
        return "Showcase"
    if low in {"l", "leader"} or (card_type or "").lower() == "leader":
        return "Epic"
    if low in {"pr", "promo", "p"}:
        return "Promo"
    if "don" in low or (card_type and "don" in card_type.lower()):
        return "Token"
    if "manga" in low or low == "sp":
        return "Showcase"
    if "treasure" in low:
        return "Showcase"
    if "secret" in low:
        return "Showcase"
    if "super" in low:
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


def scrydex_image(set_code: str, number: str | None) -> str | None:
    """Prefer Scrydex CDN when collector id is known (OP01-001 / OP01-001A)."""
    if not number:
        return None
    n = number.strip()
    # Already full OPTCG id
    m = re.match(r"^([A-Z0-9]+)-(\d{3}[A-Z]?)$", n, re.I)
    if m:
        cid = f"{m.group(1).upper()}-{m.group(2).upper()}"
        # Scrydex PRB uses PRB-01 style sometimes; keep PRB01 as set folder key
        return f"https://images.scrydex.com/onepiece/{cid}/large"
    # Bare collector number
    m2 = re.match(r"^0*(\d+)([A-Za-z]?)$", n)
    if m2:
        body = m2.group(1).zfill(3) + (m2.group(2).upper() if m2.group(2) else "")
        return f"https://images.scrydex.com/onepiece/{set_code.upper()}-{body}/large"
    return None


def is_sealed_name(name: str) -> bool:
    return bool(
        re.search(
            r"Booster|Bundle|Box|Collector|Display|Case|Pack|Starter Deck|"
            r"Deck Set|Premium Booster|Sleeved",
            name,
            re.I,
        )
    ) and not bool(re.search(r"\(Box Topper\)", name, re.I))


def sealed_kind(name: str) -> str:
    n = name.lower()
    if "booster box" in n or ("box" in n and "pack" not in n and "topper" not in n):
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


def normalize_collector_number(
    raw: str | None, set_code: str, name: str, card_type: str | None, don_idx: list[int]
) -> str | None:
    """Return OPTCG-style collector id (OP01-001 / OP01-001A) or DON-###."""
    is_parallel = "parallel" in name.lower()
    ctype = (card_type or "").lower()

    if raw:
        n = raw.strip()
        # OP01-001 / ST01-001
        m = re.match(r"^([A-Z0-9]+)-(\d+)([A-Za-z]?)$", n, re.I)
        if m:
            body = m.group(2).zfill(3)
            letter = (m.group(3) or "").upper()
            if is_parallel and not letter:
                letter = "A"
            return f"{m.group(1).upper()}-{body}{letter}"
        # Bare digits
        m2 = re.match(r"^0*(\d+)([A-Za-z]?)$", n)
        if m2:
            body = m2.group(1).zfill(3)
            letter = (m2.group(2) or "").upper()
            if is_parallel and not letter:
                letter = "A"
            return f"{set_code.upper()}-{body}{letter}"
        return n

    # DON!! cards often lack a number in TCGCSV
    if "don" in name.lower() or "don" in ctype:
        don_idx[0] += 1
        return f"DON-{don_idx[0]:03d}"
    return None


def main() -> int:
    RAW.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)

    cards: list[dict] = []
    sealed: list[dict] = []
    don_idx = [0]

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
            card_type = (
                ext(p.get("extendedData"), "Card Type")
                or ext(p.get("extendedData"), "CardType")
                or ext(p.get("extendedData"), "Type")
            )
            rarity_raw = ext(p.get("extendedData"), "Rarity")
            rarity = normalize_rarity(rarity_raw, card_type)
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

            if is_sealed_name(pname) or (
                not number_raw
                and not (
                    "don" in pname.lower()
                    or (card_type or "").lower().startswith("don")
                )
            ):
                if not is_sealed_name(pname) and not number_raw:
                    # Non-card / junk without number
                    if not re.search(r"Booster|Box|Pack|Deck|Case|Display", pname, re.I):
                        continue
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
                            "id": f"op_sku_{prod_id}",
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

            number = normalize_collector_number(
                number_raw, code, pname, card_type, don_idx
            )
            if not number:
                continue

            scry = scrydex_image(code, number)
            # Prefer Limitless webp (same Bandai SAMPLE as Scrydex, faster CDN).
            # Runtime uses Limitless / Bandai / TCGPlayer CDN (SAMPLE watermark OK).
            lim = None
            if number:
                import re as _re
                n = str(number).strip().upper()
                m = _re.match(r"^((?:OP|ST|EB|PRB)\d+)-(\d{3})([A-Z]?)$", n)
                if m:
                    setc, digits, suf = m.group(1), m.group(2), m.group(3)
                    core = f"{setc}-{digits}"
                    base = f"https://limitlesstcg.nyc3.cdn.digitaloceanspaces.com/one-piece/{setc}"
                    if suf:
                        idx = ord(suf) - ord("A") + 1
                        lim = f"{base}/{core}_p{idx}_EN.webp"
                    else:
                        lim = f"{base}/{core}_EN.webp"
            # Prefer Limitless → Scrydex → TCGPlayer upgraded
            final_hi = lim or scry or img_hi
            final_small = img_small or img_hi

            cards.append(
                {
                    "id": f"op_{prod_id}",
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
                    "imageUrl": final_hi,
                    "imageUrlSmall": final_small,
                    "imageKey": f"op_{prod_id}",
                }
            )

    by_id = {c["id"]: c for c in cards}
    cards = list(by_id.values())
    by_sku = {s["id"]: s for s in sealed}
    sealed = [s for s in by_sku.values() if s["kind"] in ("pack", "box")]

    catalog = {
        "generatedAt": datetime.now().isoformat(),
        "source": "tcgcsv.com category 68 (One Piece Card Game)",
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

    cat_path = OUT / "onepiece_catalog.json"
    sealed_path = OUT / "onepiece_sealed.json"
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

    # Top chase preview for featured packs
    chase = sorted(cards, key=lambda c: c["marketPrice"], reverse=True)[:20]
    print("top chase:")
    for c in chase:
        print(f"  {c['id']:16} ${c['marketPrice']:8.2f}  {c['name'][:48]}  {c['number']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
