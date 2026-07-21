"""Verify Riftbound signature (*) numbers resolve on Scrydex as {num}s."""
from __future__ import annotations

import json
import re
import urllib.error
import urllib.request

CATALOG = r"assets/data/riftbound_catalog.json"


def normalize(raw: str) -> str:
    n = raw.split("/")[0].strip()
    if "//" in n:
        n = n.split("//")[0].strip()
    is_sig = "*" in n
    n = n.replace("*", "").strip()
    tok = re.match(r"^[Tt]0*([0-9]+)$", n)
    if tok:
        return f"T{tok.group(1).zfill(2)}"
    m = re.match(r"^0*([0-9]+[a-zA-Z]?)$", n)
    if not m:
        return n
    base = m.group(1)
    return f"{base}s" if is_sig else base


def head_ok(url: str) -> bool:
    req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": "Bindora/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            return 200 <= r.status < 300
    except urllib.error.HTTPError:
        return False
    except Exception:
        return False


def main() -> None:
    with open(CATALOG, encoding="utf-8") as f:
        data = json.load(f)
    cards = data if isinstance(data, list) else data.get("cards", [])

    starred = [c for c in cards if "*" in str(c.get("number", ""))]
    print(f"starred numbers: {len(starred)}")
    ok = fail = 0
    for c in starred:
        set_code = c["setCode"]
        num = normalize(c["number"])
        url = f"https://images.scrydex.com/riftbound/{set_code}-{num}/large"
        if head_ok(url):
            ok += 1
        else:
            fail += 1
            print("FAIL", c["name"], c["number"], "->", f"{set_code}-{num}")
    print(f"ok={ok} fail={fail}")


if __name__ == "__main__":
    main()
