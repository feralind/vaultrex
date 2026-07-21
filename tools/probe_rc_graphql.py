#!/usr/bin/env python3
import json
import re
import urllib.request
from pathlib import Path

UA = {
    "User-Agent": "Mozilla/5.0",
    "Content-Type": "application/json",
    "Accept": "application/json",
}


def post(url: str, payload: dict) -> tuple[int, bytes]:
    data = json.dumps(payload).encode()
    req = urllib.request.Request(url, data=data, headers=UA, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()


queries = [
    {"query": "{ __typename }"},
    {
        "query": "{ __schema { queryType { name } mutationType { name } types { name kind } } }"
    },
    {
        "query": """
        {
          __type(name: "Query") {
            fields { name description }
          }
        }
        """
    },
]

for url in [
    "https://api.rarecandy.com/graphql",
    "https://packs.rarecandy.com/api/graphql",
]:
    print("====", url)
    for q in queries:
        code, body = post(url, q)
        text = body.decode("utf-8", "replace")
        print(" status", code, "len", len(body))
        print(" ", text[:500].replace("\n", " "))
        print("---")

# List public instapack images / videos on marketing site
OUT = Path(r"C:/Users/Tom/AppData/Local/Temp/rc_market_js")
html = (OUT / "index.html").read_text(encoding="utf-8", errors="replace")
print("\n==== asset refs in homepage ====")
for m in sorted(
    set(
        re.findall(
            r"/[^\s\"']+(?:instapack|pack|rip|peel|video)[^\s\"']*\.(?:png|jpg|webp|mp4|webm|gif)",
            html,
            re.I,
        )
    )
):
    print(m)

# Also from index chunk
idx = (OUT / "index-b3900b859785f8e2.js").read_text(encoding="utf-8", errors="replace")
print("\n==== asset refs in index chunk ====")
for m in sorted(
    set(
        re.findall(
            r"/[^\s\"']+\.(?:png|jpg|webp|mp4|webm|gif)",
            idx,
            re.I,
        )
    )
):
    if re.search(r"instapack|pack|rip|peel|video|blob", m, re.I):
        print(m)
