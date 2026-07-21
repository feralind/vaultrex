#!/usr/bin/env python3
from pathlib import Path
import re

OUT = Path(r"C:/Users/Tom/AppData/Local/Temp/rc_js")

keywords = [
    "mp4", "webm", "m3u8", "video/", "HTMLVideo", "createElement(\"video",
    "createElement('video", "MuxPlayer", "media-chrome", ".riv", "rive",
    "lottie", "dotlottie", "three", "babylon", "spline", "canvas",
    "peel", "foil", "packOpen", "PackOpen", "pack_open", "instant_pack",
    "demo/rip", "RipExperience", "scrub", "seekTo", "requestVideoFrame",
    "cloudflarestream", "videodelivery", "cdn.rarecandy", "assets.rarecandy",
    "media.rarecandy", "pack-rip", "packRip", "hold to", "Hold to",
]

for p in sorted(OUT.glob("*.js"), key=lambda x: -x.stat().st_size):
    t = p.read_text(encoding="utf-8", errors="replace")
    found = [k for k in keywords if k.lower() in t.lower()]
    if not found:
        continue
    print(f"\n==== {p.name} ({p.stat().st_size}) {found}")
    for k in found:
        for m in re.finditer(re.escape(k), t, re.I):
            start = max(0, m.start() - 80)
            end = min(len(t), m.end() + 120)
            snip = t[start:end].replace("\n", " ")
            print(f"  [{k}] ...{snip}...")
            break

# Also extract URL-like strings containing media hints
print("\n==== MEDIA-LIKE URLS ====")
for p in OUT.glob("*.js"):
    t = p.read_text(encoding="utf-8", errors="replace")
    for m in re.finditer(r"https?://[^\s\"'`]{10,200}", t):
        u = m.group(0)
        if re.search(r"mp4|webm|m3u8|video|stream|mux|cdn|media|rip|peel|pack", u, re.I):
            print(p.name, u[:220])
