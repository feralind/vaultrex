#!/usr/bin/env python3
"""Download Yu-Gi-Oh! (TCGCSV category 2) dumps and build catalog + sealed JSON.

Art: YGOPRODeck HD (no SAMPLE watermark) matched by set code / passcode / name.
Prices: TCGCSV market. Launch sets stay in sync with TcgcsvPriceRefresh.yugiohGroups.
"""

from __future__ import annotations

import json
import re
import urllib.request
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "tools" / "raw_yugioh"
OUT = ROOT / "assets" / "data"
CATEGORY = 2

# Launch sets — groupIds match TcgcsvPriceRefresh.yugiohGroups.
SETS = [
    {"code": "LOB", "name": "Legend of Blue Eyes White Dragon", "groupId": 22881},
    {"code": "RA04", "name": "Quarter Century Stampede", "groupId": 23891},
    {"code": "RA05", "name": "Rarity Collection 5", "groupId": 24555},
    {"code": "DOOD", "name": "Doom of Dimensions", "groupId": 24357},
    {"code": "PHRE", "name": "Phantom Revenge", "groupId": 24475},
    {"code": "BPRO", "name": "Burst Protocol", "groupId": 24558},
    {"code": "BLZD", "name": "Blazing Dominion", "groupId": 24581},
]

UA = {"User-Agent": "BindoraYgoCatalog/1.0"}
YGO_API = "https://db.ygoprodeck.com/api/v7/cardinfo.php"
YGO_IMG = "https://images.ygoprodeck.com/images/cards/{}.jpg"
YGO_IMG_SM = "https://images.ygoprodeck.com/images/cards_small/{}.jpg"


def fetch_json(url: str, timeout: float = 120) -> dict | list:
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=timeout) as res:
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
    """Map YGO rarities into Bindora parseRarity strings."""
    if not r:
        return "Common"
    low = r.strip().lower()
    if low in {"c", "common", "normal parallel rare", "short print", "starfoil rare"}:
        return "Common"
    if low in {"uc", "u", "uncommon", "rare parallel rare"}:
        return "Uncommon"
    if low in {"r", "rare", "super rare", "sr", "duel terminal rare parallel rare"}:
        return "Rare"
    if low in {
        "ur",
        "ultra rare",
        "ultimate rare",
        "gold rare",
        "premium gold rare",
        "collective rare",
    }:
        return "Epic"
    if any(
        x in low
        for x in (
            "secret",
            "ghost",
            "starlight",
            "platinum",
            "quarter century",
            "prismatic",
            "collector's",
            "extra secret",
            "holographic",
            "10000",
        )
    ):
        return "Showcase"
    if "promo" in low:
        return "Promo"
    if "common" in low:
        return "Common"
    if "uncommon" in low:
        return "Uncommon"
    if "super" in low or "ultra" in low or "ultimate" in low:
        return "Epic" if "ultra" in low or "ultimate" in low else "Rare"
    if "rare" in low:
        return "Rare"
    return "Rare"


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
            r"Booster|Bundle|Box|Collector|Display|Case|Pack|Structure Deck|"
            r"Tin|Mega Pack|Tournament Pack|Starter Deck|Battle Pack",
            name,
            re.I,
        )
    )


def sealed_kind(name: str) -> str:
    n = name.lower()
    if "booster box" in n or ("box" in n and "pack" not in n and "tin" not in n):
        if "case" in n:
            return "other"
        return "box"
    if "booster" in n or "pack" in n:
        return "pack"
    if "deck" in n:
        return "deck"
    if "tin" in n:
        return "other"
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


def load_ygoprodeck_index() -> tuple[dict[str, dict], dict[str, dict], dict[str, dict]]:
    """Maps: set_code -> art, passcode -> art, name_lower -> art."""
    cache = RAW / "ygoprodeck_cardinfo.json"
    if cache.exists():
        print("local ygoprodeck dump")
        payload = json.loads(cache.read_text(encoding="utf-8"))
    else:
        print("fetch ygoprodeck cardinfo (all)…")
        payload = fetch_json(YGO_API, timeout=180)
        RAW.mkdir(parents=True, exist_ok=True)
        cache.write_text(json.dumps(payload), encoding="utf-8")

    by_set: dict[str, dict] = {}
    by_pass: dict[str, dict] = {}
    by_name: dict[str, dict] = {}
    for card in payload.get("data") or []:
        images = card.get("card_images") or []
        if not images:
            continue
        primary = images[0]
        art = {
            "imageUrl": primary.get("image_url")
            or YGO_IMG.format(primary.get("id") or card.get("id")),
            "imageUrlSmall": primary.get("image_url_small")
            or YGO_IMG_SM.format(primary.get("id") or card.get("id")),
            "passcode": str(card.get("id") or ""),
            "name": card.get("name") or "",
        }
        pid = str(card.get("id") or "")
        if pid:
            by_pass[pid] = art
        name = (card.get("name") or "").strip().lower()
        if name and name not in by_name:
            by_name[name] = art
        for img in images:
            iid = str(img.get("id") or "")
            if iid and iid not in by_pass:
                by_pass[iid] = {
                    "imageUrl": img.get("image_url") or YGO_IMG.format(iid),
                    "imageUrlSmall": img.get("image_url_small") or YGO_IMG_SM.format(iid),
                    "passcode": iid,
                    "name": card.get("name") or "",
                }
        for s in card.get("card_sets") or []:
            code = (s.get("set_code") or "").strip().upper()
            if code and code not in by_set:
                by_set[code] = art
    print(f"ygoprodeck index sets={len(by_set)} pass={len(by_pass)} names={len(by_name)}")
    return by_set, by_pass, by_name


def normalize_set_number(raw: str | None, set_code: str) -> str | None:
    if not raw:
        return None
    n = raw.strip().upper().replace(" ", "")
    # Already LOB-EN001 / RA05-EN083 / MRD-EN098
    if re.match(r"^[A-Z0-9]+-[A-Z]{0,2}\d+", n):
        return n
    # Bare EN001 / 001
    m = re.match(r"^(?:EN|EU|NA|JP|AE)?[-_]?0*(\d+)([A-Z]?)$", n)
    if m:
        return f"{set_code}-EN{m.group(1).zfill(3)}{m.group(2)}"
    m2 = re.match(r"^0*(\d+)$", n)
    if m2:
        return f"{set_code}-EN{m2.group(1).zfill(3)}"
    return n


def resolve_art(
    *,
    number: str | None,
    name: str,
    password: str | None,
    tcg_hi: str,
    tcg_sm: str,
    by_set: dict,
    by_pass: dict,
    by_name: dict,
) -> tuple[str, str, str]:
    """Return (imageUrl, imageUrlSmall, source). Prefer YGOPRODeck HD."""
    if password:
        p = password.strip()
        if p in by_pass:
            a = by_pass[p]
            return a["imageUrl"], a["imageUrlSmall"], "ygoprodeck-pass"
    if number:
        n = number.strip().upper()
        if n in by_set:
            a = by_set[n]
            return a["imageUrl"], a["imageUrlSmall"], "ygoprodeck-set"
        # Try without region prefix variants LOB-001 vs LOB-EN001
        alt = re.sub(r"-EN", "-", n)
        if alt in by_set:
            a = by_set[alt]
            return a["imageUrl"], a["imageUrlSmall"], "ygoprodeck-set"
        # Prefix match: RA05-EN083 vs RA05-EN083?
        for k, a in by_set.items():
            if k.endswith(n) or n.endswith(k):
                return a["imageUrl"], a["imageUrlSmall"], "ygoprodeck-set"
    key = re.sub(r"\s*\(.*?\)\s*$", "", name).strip().lower()
    if key in by_name:
        a = by_name[key]
        return a["imageUrl"], a["imageUrlSmall"], "ygoprodeck-name"
    # Strip rarity suffix in name
    key2 = re.sub(r"\s*-\s*.*$", "", key).strip()
    if key2 in by_name:
        a = by_name[key2]
        return a["imageUrl"], a["imageUrlSmall"], "ygoprodeck-name"
    if tcg_hi:
        return tcg_hi, tcg_sm or tcg_hi, "tcgplayer"
    return "", "", "none"


def main() -> int:
    RAW.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    by_set, by_pass, by_name = load_ygoprodeck_index()

    cards: list[dict] = []
    sealed: list[dict] = []
    art_stats: dict[str, int] = {}

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
            products = fetch_json(f"https://tcgcsv.com/tcgplayer/{CATEGORY}/{gid}/products")
            prices = fetch_json(f"https://tcgcsv.com/tcgplayer/{CATEGORY}/{gid}/prices")
            prod_path.write_text(json.dumps(products), encoding="utf-8")
            price_path.write_text(json.dumps(prices), encoding="utf-8")

        price_map = build_price_map(prices.get("results") or [])
        for p in products.get("results") or []:
            pname = str(p.get("name") or "")
            prod_id = int(p["productId"])
            rarity_raw = ext(p.get("extendedData"), "Rarity")
            rarity = normalize_rarity(rarity_raw)
            number_raw = (
                ext(p.get("extendedData"), "Number")
                or ext(p.get("extendedData"), "#")
                or ext(p.get("extendedData"), "Card Number")
            )
            password = (
                ext(p.get("extendedData"), "Password")
                or ext(p.get("extendedData"), "Passcode")
                or ext(p.get("extendedData"), "Monster ID")
            )
            card_type = (
                ext(p.get("extendedData"), "Card Type")
                or ext(p.get("extendedData"), "Type")
                or ext(p.get("extendedData"), "Monster Type")
            )
            img_hi, img_small = upgrade_images(str(p.get("imageUrl") or ""))
            market = price_map.get(f"{prod_id}|Normal") or price_map.get(
                f"{prod_id}|1st Edition"
            ) or price_map.get(f"{prod_id}|Unlimited") or price_map.get(
                str(prod_id), 0.0
            )
            foil = price_map.get(f"{prod_id}|Foil") or price_map.get(
                f"{prod_id}|Holofoil"
            )

            if is_sealed_name(pname) and not number_raw:
                kind = sealed_kind(pname)
                sealed_price = market
                for k in (
                    f"{prod_id}|Normal",
                    f"{prod_id}|1st Edition",
                    f"{prod_id}|",
                    str(prod_id),
                ):
                    if k in price_map and price_map[k] > 0:
                        sealed_price = price_map[k]
                        break
                packs = 24 if kind == "box" else None
                sealed.append(
                    {
                        "id": f"ygo_sku_{prod_id}",
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

            number = normalize_set_number(number_raw, code)
            if not number and not password:
                # Skip non-card junk
                if is_sealed_name(pname):
                    continue
                # Still try name match as a card
                if pname.strip().lower() not in by_name:
                    continue
                number = f"{code}-UNK{prod_id % 10000:04d}"

            art_hi, art_sm, art_src = resolve_art(
                number=number,
                name=pname,
                password=password,
                tcg_hi=img_hi,
                tcg_sm=img_small,
                by_set=by_set,
                by_pass=by_pass,
                by_name=by_name,
            )
            art_stats[art_src] = art_stats.get(art_src, 0) + 1
            if not art_hi:
                continue

            cards.append(
                {
                    "id": f"ygo_{prod_id}",
                    "productId": prod_id,
                    "setCode": code,
                    "setName": name,
                    "name": pname,
                    "number": number or password or str(prod_id),
                    "rarity": rarity,
                    "cardType": card_type,
                    "domain": None,
                    "marketPrice": round(float(market), 2),
                    "foilMarketPrice": (
                        round(float(foil), 2) if foil is not None else None
                    ),
                    "imageUrl": art_hi,
                    "imageUrlSmall": art_sm,
                    "imageKey": f"ygo_{prod_id}",
                }
            )

    by_id = {c["id"]: c for c in cards}
    cards = list(by_id.values())
    by_sku = {s["id"]: s for s in sealed}
    sealed = [s for s in by_sku.values() if s["kind"] in ("pack", "box")]

    # Ensure at least one pack + box per set for shop (synthetic if missing).
    for s in SETS:
        code, name = s["code"], s["name"]
        has_pack = any(x["setCode"] == code and x["kind"] == "pack" for x in sealed)
        has_box = any(x["setCode"] == code and x["kind"] == "box" for x in sealed)
        set_cards = [c for c in cards if c["setCode"] == code]
        if not set_cards:
            continue
        avg = sum(c["marketPrice"] for c in set_cards) / max(1, len(set_cards))
        pack_price = max(2.49, min(24.99, round(avg * 0.35 + 2.5, 2)))
        if not has_pack:
            sealed.append(
                {
                    "id": f"ygo_sku_pack_{code.lower()}",
                    "productId": 900000 + abs(hash(code)) % 90000,
                    "setCode": code,
                    "setName": name,
                    "name": f"{name} Booster Pack",
                    "kind": "pack",
                    "marketPrice": pack_price,
                    "imageUrl": "",
                    "imageUrlSmall": "",
                    "packsPerBox": None,
                }
            )
        if not has_box:
            sealed.append(
                {
                    "id": f"ygo_sku_box_{code.lower()}",
                    "productId": 910000 + abs(hash(code)) % 90000,
                    "setCode": code,
                    "setName": name,
                    "name": f"{name} Booster Box",
                    "kind": "box",
                    "marketPrice": round(pack_price * 24 * 0.92, 2),
                    "imageUrl": "",
                    "imageUrlSmall": "",
                    "packsPerBox": 24,
                }
            )

    catalog = {
        "generatedAt": datetime.now().isoformat(),
        "source": "tcgcsv.com category 2 + ygoprodeck.com images",
        "imageSource": (
            "YGOPRODeck HD URLs (run tools/cache_yugioh_art.py to rehost locally)"
        ),
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

    cat_path = OUT / "yugioh_catalog.json"
    sealed_path = OUT / "yugioh_sealed.json"
    cat_path.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    sealed_path.write_text(
        json.dumps(sealed_out, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(f"wrote {cat_path.name} cards={len(cards)}")
    print(f"wrote {sealed_path.name} products={len(sealed)}")
    print("art sources", art_stats)
    print(
        "NOTE: run `python tools/cache_yugioh_art.py` so imageUrls point at "
        "assets/card_art/yugioh/ (YGOPRODeck forbids hotlinking; no CORS)."
    )
    chase = sorted(cards, key=lambda c: c["marketPrice"], reverse=True)[:24]
    print("top chase:")
    for c in chase:
        print(
            f"  {c['id']:18} ${c['marketPrice']:8.2f}  {c['name'][:42]:42}  {c['number']}"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
