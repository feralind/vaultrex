#!/usr/bin/env python3
import re
import urllib.request

UA = {"User-Agent": "Mozilla/5.0"}
html = urllib.request.urlopen(
    urllib.request.Request("https://rarecandy.com/videos/", headers=UA), timeout=20
).read().decode("utf-8", "replace")
print("len", len(html))
print(html[:1200])
print("media", re.findall(r"[^\s\"']+\.(?:mp4|webm|m3u8)", html, re.I)[:40])
