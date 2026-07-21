"""Audit EVERY card art URL across Riftbound, Pokémon, MTG, and One Piece catalogs.

Mirrors lib/data/scrydex_art.dart:
- Signature * → Scrydex `s` suffix
- preferCatalogArt for oversized / runes / tokens / // names → TCGPlayer imageUrl
- Pokémon setCode → expansion id map
- MTG setCode as-is
- One Piece OP01-001 / OP01-001A (3-digit pad, upper letter)
"""
from __future__ import annotations

import json
import re
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

POKEMON_EXP = {
    "MEW": "sv3pt5",
    "OBF": "sv3",
    "PAL": "sv2",
    "TWM": "sv6",
    "SSP": "sv8",
    "PRE": "sv8pt5",
}
MTG_SETS = {"FDN", "MH3", "DSK", "BLB", "OTJ", "DFT"}
RB_SETS = {"OGS", "OGN", "SFD", "UNL"}
OP_SETS = {"OP01", "OP02", "OP05", "OP09", "OP13", "PRB01", "PRB-01"}


def normalize_number(raw: str | None) -> str | None:
    if not raw:
        return None
    n = str(raw).split("/")[0].strip()
    if "//" in n:
        n = n.split("//")[0].strip()
    # One Piece full collector ids → numeric+letter body for callers that pad.
    op = re.match(r"^(OP\d+|PRB-?\d+|ST\d+|EB\d+)[- ]?0*([0-9]+[a-zA-Z]?)$", n, re.I)
    if op:
        return op.group(2)
    is_sig = "*" in n
    n = n.replace("*", "").strip()
    if not n:
        return None
    rune = re.match(r"^[Rr]0*([0-9]+[a-zA-Z]?)$", n)
    if rune:
        body = rune.group(1)
        digits = re.match(r"^([0-9]+)", body)
        if not digits:
            return f"R{body.upper()}"
        rest = body[len(digits.group(1)) :]
        return f"R{digits.group(1).zfill(2)}{rest}"
    tok = re.match(r"^[Tt]0*([0-9]+)$", n)
    if tok:
        padded = f"T{tok.group(1).zfill(2)}"
        return f"{padded}s" if is_sig else padded
    m = re.match(r"^0*([0-9]+[a-zA-Z]?)$", n)
    if m:
        base = m.group(1)
        return f"{base}s" if is_sig else base
    return n or None


def prefer_catalog(name: str, number: str | None, image_url: str = "") -> bool:
    nl = (name or "").lower()
    if "oversized" in nl:
        return True
    raw = str(number or "").split("/")[0].strip()
    if re.match(r"^[Rr]\d", raw):
        return True
    if (image_url or "").startswith("assets/"):
        return True
    if raw.upper().startswith("DON") or "don!!" in nl:
        return True
    return False


def head(url: str):
    """Prefer HEAD; fall back to ranged GET (TCGPlayer often 403s HEAD)."""
    headers = {"User-Agent": "Mozilla/5.0 (compatible; BindoraArtAudit/1.0)"}
    try:
        req = urllib.request.Request(url, method="HEAD", headers=headers)
        with urllib.request.urlopen(req, timeout=15) as r:
            return r.status
    except Exception:
        pass
    try:
        headers2 = {**headers, "Range": "bytes=0-0"}
        req = urllib.request.Request(url, method="GET", headers=headers2)
        with urllib.request.urlopen(req, timeout=15) as r:
            return 200 if r.status in (200, 206) else r.status
    except urllib.error.HTTPError as e:
        return e.code
    except Exception as e:
        return type(e).__name__


def load_cards(path: Path) -> list:
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    return data if isinstance(data, list) else data.get("cards", [])


def resolve_url(franchise: str, card: dict) -> tuple[str | None, str]:
    """Return (url, kind) where kind is scrydex|catalog|asset|none."""
    name = card.get("name") or ""
    number = card.get("number")
    catalog = card.get("imageUrl") or card.get("imageUrlSmall") or ""

    if prefer_catalog(name, number, catalog):
        if catalog.startswith("assets/"):
            return (catalog, "asset")
        return (catalog or None, "catalog" if catalog else "none")

    num = normalize_number(number)
    setc = (card.get("setCode") or "").upper()

    if franchise == "riftbound":
        if not num or setc not in RB_SETS:
            return (catalog or None, "catalog" if catalog else "none")
        # Gold dual-face tokens: prefer right collector number.
        raw_full = str(number or "").strip()
        if "//" in raw_full and "gold" in (name or "").lower():
            right = raw_full.split("//")[-1].strip().split("/")[0].strip()
            alt = normalize_number(right)
            if alt:
                num = alt
        if setc == "OGS":
            digits = re.match(r"^(\d+)", num)
            if digits and int(digits.group(1)) > 24:
                setc = "OGN"
        cid = f"{setc}-{num}"
        return (f"https://images.scrydex.com/riftbound/{cid}/large", "scrydex")

    if franchise == "pokemon":
        exp = POKEMON_EXP.get(setc)
        if not exp or not num:
            return (catalog or None, "catalog" if catalog else "none")
        return (f"https://images.scrydex.com/pokemon/{exp}-{num}/large", "scrydex")

    if franchise == "mtg":
        if setc not in MTG_SETS or not num:
            return (catalog or None, "catalog" if catalog else "none")
        return (f"https://images.scrydex.com/magicthegathering/{setc}-{num}/large", "scrydex")

    if franchise == "onepiece":
        raw = str(number or "").split("/")[0].strip()
        # Prefer full OPTCG collector id when present.
        full = re.match(
            r"^((?:OP|ST|EB|PRB)-?\d+)-(\d{1,3}[A-Za-z]?)$", raw, re.I
        )
        if full:
            set_part = full.group(1).upper().replace("-", "") if full.group(1).upper().startswith("PRB") else full.group(1).upper()
            if set_part.startswith("PRB") and "-" in full.group(1):
                set_part = full.group(1).upper().replace("-", "")
            body = full.group(2)
            dm = re.match(r"^(\d+)([A-Za-z]?)$", body)
            if dm:
                padded = f"{dm.group(1).zfill(3)}{dm.group(2).upper()}"
                cid = f"{set_part}-{padded}"
                return (f"https://images.scrydex.com/onepiece/{cid}/large", "scrydex")
        set_norm = setc.replace("-", "")
        if set_norm not in OP_SETS and setc not in OP_SETS:
            return (catalog or None, "catalog" if catalog else "none")
        if not num:
            return (catalog or None, "catalog" if catalog else "none")
        m = re.match(r"^(\d+)([A-Za-z]?)$", str(num))
        if m:
            padded = f"{m.group(1).zfill(3)}{m.group(2).upper()}"
            cid = f"{set_norm}-{padded}"
            return (f"https://images.scrydex.com/onepiece/{cid}/large", "scrydex")
        return (catalog or None, "catalog" if catalog else "none")

    return (catalog or None, "catalog" if catalog else "none")


def audit_franchise(name: str, path: Path) -> dict:
    cards = load_cards(path)
    print(f"\n=== {name} ({len(cards)} cards) ===")

    jobs = []
    for c in cards:
        url, kind = resolve_url(name.lower(), c)
        jobs.append((c, url, kind))

    scry_ok = scry_fail = cat_ok = cat_fail = asset_ok = none_count = 0
    fails: list[tuple] = []

    # Local asset overrides count as OK without HTTP.
    for c, url, kind in jobs:
        if kind == "asset" and url:
            path = ROOT / url
            if path.is_file():
                asset_ok += 1
            else:
                fails.append(("missing_asset", c.get("name"), c.get("number"), url))

    to_head = [(c, url, kind) for c, url, kind in jobs if url and kind != "asset"]

    def check(item):
        c, url, kind = item
        st = head(url)
        return st, c, url, kind

    with ThreadPoolExecutor(28) as ex:
        futs = [ex.submit(check, item) for item in to_head]
        for fut in as_completed(futs):
            st, c, url, kind = fut.result()
            ok = st == 200
            if kind == "scrydex":
                if ok:
                    scry_ok += 1
                else:
                    scry_fail += 1
                    cat = c.get("imageUrl") or ""
                    if cat.startswith("assets/") and (ROOT / cat).is_file():
                        asset_ok += 1
                        fails.append(("scry404_asset_ok", c.get("name"), c.get("number"), url))
                    elif cat and head(cat) == 200:
                        cat_ok += 1
                        fails.append(("scry404_but_catalog_ok", c.get("name"), c.get("number"), url))
                    else:
                        fails.append((st, c.get("name"), c.get("number"), url, "no_catalog"))
            else:
                if ok:
                    cat_ok += 1
                else:
                    cat_fail += 1
                    fails.append((st, c.get("name"), c.get("number"), url, "catalog_fail"))

    for c, url, kind in jobs:
        if url is None:
            none_count += 1
            fails.append(("none", c.get("name"), c.get("number"), None))

    hard_fails = [
        f
        for f in fails
        if f[0] not in ("scry404_but_catalog_ok", "scry404_asset_ok")
    ]
    soft = [f for f in fails if f[0] in ("scry404_but_catalog_ok", "scry404_asset_ok")]

    print(f"  scrydex OK: {scry_ok}")
    print(f"  scrydex FAIL: {scry_fail} (recovered via catalog/asset: {len(soft)})")
    print(f"  catalog OK: {cat_ok}")
    print(f"  asset OK: {asset_ok}")
    print(f"  catalog FAIL: {cat_fail}")
    print(f"  no URL: {none_count}")
    print(f"  HARD failures: {len(hard_fails)}")
    for row in hard_fails[:25]:
        print("   HARD", row)
    if len(hard_fails) > 25:
        print(f"   ... {len(hard_fails) - 25} more")

    return {
        "total": len(cards),
        "scry_ok": scry_ok,
        "scry_fail": scry_fail,
        "cat_ok": cat_ok,
        "asset_ok": asset_ok,
        "cat_fail": cat_fail,
        "none": none_count,
        "hard": hard_fails,
        "soft": soft,
    }


def main() -> None:
    results = {}
    results["riftbound"] = audit_franchise("riftbound", ROOT / "assets/data/riftbound_catalog.json")
    results["pokemon"] = audit_franchise("pokemon", ROOT / "assets/data/pokemon_catalog.json")
    results["mtg"] = audit_franchise("mtg", ROOT / "assets/data/mtg_catalog.json")
    results["onepiece"] = audit_franchise("onepiece", ROOT / "assets/data/onepiece_catalog.json")

    print("\n======== SUMMARY ========")
    total = sum(r["total"] for r in results.values())
    hard = sum(len(r["hard"]) for r in results.values())
    soft = sum(len(r["soft"]) for r in results.values())
    for k, r in results.items():
        print(
            f"{k}: total={r['total']} scry_ok={r['scry_ok']} "
            f"cat_ok={r['cat_ok']} asset_ok={r.get('asset_ok', 0)} "
            f"hard={len(r['hard'])} soft={len(r['soft'])}"
        )
    print(f"ALL: total={total} hard_failures={hard} soft={soft}")

    # Write soft fails for fixing
    out = ROOT / "tools/art_audit_soft_fails.json"
    payload = {
        k: [
            {"name": s[1], "number": s[2], "url": s[3]}
            for s in r["soft"]
        ]
        + [
            {"hard": True, "detail": list(h)}
            for h in r["hard"]
        ]
        for k, r in results.items()
    }
    out.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    print(f"Wrote {out}")


if __name__ == "__main__":
    main()
