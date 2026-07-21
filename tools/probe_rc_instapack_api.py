#!/usr/bin/env python3
from pathlib import Path
import re
import urllib.request
import json

OUT = Path(r"C:/Users/Tom/AppData/Local/Temp/rc_market_js")
UA = {"User-Agent": "Mozilla/5.0"}

# Deep scan marketing JS for Instapack / video / rip UX copy
for name in [
    "_app-f216a714f47b1971.js",
    "index-b3900b859785f8e2.js",
    "6324-3c75ebd4a224bca5.js",
    "9311-c8effbb7d8970948.js",
]:
    p = OUT / name
    if not p.exists():
        continue
    t = p.read_text(encoding="utf-8", errors="replace")
    print(f"\n==== {name} ====")
    for pat in [
        r".{0,60}Instapack.{0,120}",
        r".{0,60}instapack.{0,120}",
        r".{0,80}Hold to .{0,80}",
        r".{0,80}hold to .{0,80}",
        r".{0,60}packs\.rarecandy\.com[^\"']{0,80}",
        r".{0,60}/packs/demo[^\"']{0,80}",
        r".{0,80}Rip\.[^\"]{0,40}",
        r"children:\"[^\"]{0,40}[Rr]ip[^\"]{0,60}\"",
    ]:
        ms = list(re.finditer(pat, t))
        if not ms:
            continue
        print(f" pattern {pat!r} hits={len(ms)}")
        for m in ms[:8]:
            print("  ", m.group(0).replace("\n", " ")[:220])

# Probe packs GraphQL / public APIs
print("\n==== API probes ====")
endpoints = [
    "https://packs.rarecandy.com/api/graphql",
    "https://packs.rarecandy.com/graphql",
    "https://api.rarecandy.com/graphql",
    "https://packs.rarecandy.com/api/health",
    "https://packs.rarecandy.com/api/v1/packs",
    "https://packs.rarecandy.com/packs/demo/rip.txt",
]
for u in endpoints:
    try:
        req = urllib.request.Request(u, headers=UA, method="GET")
        with urllib.request.urlopen(req, timeout=20) as r:
            body = r.read(300)
            print(u, r.status, r.getheader("content-type"), body[:120])
    except Exception as e:
        code = getattr(e, "code", None)
        print(u, "ERR", code or type(e).__name__, str(e)[:100])

# Try POST introspection lightly
try:
    data = json.dumps({"query": "{ __typename }"}).encode()
    req = urllib.request.Request(
        "https://packs.rarecandy.com/api/graphql",
        data=data,
        headers={**UA, "Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=20) as r:
        print("gql typename", r.read(300))
except Exception as e:
    print("gql ERR", getattr(e, "code", None), e)
