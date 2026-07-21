#!/usr/bin/env python3
import re
import urllib.request
from pathlib import Path

OUT = Path(r"C:/Users/Tom/AppData/Local/Temp/rc_js")
UA = {"User-Agent": "Mozilla/5.0"}


def fetch(url: str) -> bytes:
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=40) as r:
        return r.read()


for u in [
    "https://rarecandy.com/",
    "https://www.rarecandy.com/",
    "https://app.rarecandy.com/",
]:
    try:
        data = fetch(u)
        print(u, "len", len(data))
        text = data.decode("utf-8", "replace")
        name = u.split("//")[1].split("/")[0].replace(".", "_")
        (OUT / f"{name}.html").write_text(text, encoding="utf-8")
        for m in re.findall(r"https?://[^\"']+\.(?:mp4|webm|m3u8)", text, re.I):
            print(" MEDIA", m)
        for m in re.findall(r"/_next/static/chunks/[^\"']+\.js", text)[:20]:
            print(" chunk", m)
        for m in re.findall(r"https?://[^\"']+(?:cdn|media|video|cloudfront|mux)[^\"']*", text, re.I)[:20]:
            print(" CDN", m[:200])
    except Exception as e:
        print("fail", u, e)
