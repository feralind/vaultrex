#!/usr/bin/env python3
import re
import urllib.request
from pathlib import Path

OUT = Path(r"C:/Users/Tom/AppData/Local/Temp/rc_market_js")
OUT.mkdir(exist_ok=True)
BASE = "https://rarecandy.com"
UA = {"User-Agent": "Mozilla/5.0"}

html = urllib.request.urlopen(
    urllib.request.Request(BASE + "/", headers=UA), timeout=40
).read().decode("utf-8", "replace")
(OUT / "index.html").write_text(html, encoding="utf-8")

# media in html
print("HTML media:")
for m in re.findall(r"https?://[^\"'\s>]+\.(?:mp4|webm|m3u8|mov)(?:\?[^\"'\s>]*)?", html, re.I):
    print(" ", m)
for m in re.findall(r"/_next/static/[^\"']+\.(?:mp4|webm)", html, re.I):
    print(" ", m)

chunks = re.findall(r"/_next/static/chunks/[^\"']+\.js", html)
print("chunks", len(chunks))
for c in sorted(set(chunks)):
    url = BASE + c
    name = c.rsplit("/", 1)[-1]
    try:
        data = urllib.request.urlopen(
            urllib.request.Request(url, headers=UA), timeout=40
        ).read()
        (OUT / name).write_bytes(data)
        text = data.decode("utf-8", "replace")
        hits = []
        for k in ["mp4", "webm", "m3u8", "HTMLVideo", "video/", "Mux", "cloudflarestream", "peel", "rip", "instapack", "Instapack", "hold"]:
            if k.lower() in text.lower():
                hits.append(k)
        if hits:
            print("HIT", name, hits, len(data))
            for m in re.finditer(r"[\"']([^\"']+\.(?:mp4|webm|m3u8)[^\"']*)[\"']", text, re.I):
                print("  FILE", m.group(1)[:220])
            for m in re.finditer(r"https?://[^\"'\s]{10,200}", text):
                u = m.group(0)
                if re.search(r"mp4|webm|video|stream|mux|cdn|cloudfront|media", u, re.I):
                    print("  URL", u[:220])
        else:
            print("ok", name, len(data))
    except Exception as e:
        print("fail", name, e)
