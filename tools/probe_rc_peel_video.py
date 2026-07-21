#!/usr/bin/env python3
from pathlib import Path
import re

OUT = Path(r"C:/Users/Tom/AppData/Local/Temp/rc_market_js")

p = OUT / "9093-9c85b6674008b9c1.js"
t = p.read_text(encoding="utf-8", errors="replace")
print("==== 9093 size", len(t))
for m in re.finditer(r".{0,220}videos/[^\"']+.{0,220}", t):
    print(m.group(0)[:450])
    print("---")

p = OUT / "_app-f216a714f47b1971.js"
t = p.read_text(encoding="utf-8", errors="replace")
print("==== _app size", len(t))
files = sorted(
    set(
        re.findall(
            r"[\"']([^\"']+\.(?:mp4|webm|m3u8|mov)(?:\?[^\"']*)?)[\"']",
            t,
            re.I,
        )
    )
)
print("media files", len(files))
for f in files:
    print(" ", f)

print("\ncounts:")
for k in [
    "peel",
    "hold",
    "currentTime",
    "playbackRate",
    "HTMLVideoElement",
    "createElement(\"video\"",
    "createElement('video'",
    "<video",
    ".mp4",
    "webm",
    "Instapack",
    "pack opening",
    "scrub",
]:
    print(f"  {k}: {len(re.findall(re.escape(k), t, re.I))}")

print("\n==== peel samples ====")
count = 0
for m in re.finditer(r".{0,120}peel.{0,160}", t, re.I):
    print(m.group(0).replace("\n", " ")[:300])
    print("---")
    count += 1
    if count >= 25:
        break

print("\n==== currentTime near video samples ====")
count = 0
for m in re.finditer(r".{0,80}currentTime.{0,120}", t):
    snip = m.group(0).replace("\n", " ")
    if re.search(r"video|mp4|peel|rip|hold|scrub|seek", snip, re.I):
        print(snip[:300])
        print("---")
        count += 1
        if count >= 20:
            break

print("\n==== hold to / hold-to samples ====")
count = 0
for m in re.finditer(r".{0,80}hold[^\n]{0,40}(?:rip|peel|open|pack).{0,100}", t, re.I):
    print(m.group(0).replace("\n", " ")[:280])
    print("---")
    count += 1
    if count >= 20:
        break

print("\n==== Instapack / pack theater related identifiers ====")
for pat in [
    r"PackTheater",
    r"PackRip",
    r"RipExperience",
    r"PeelVideo",
    r"peelVideo",
    r"RipVideo",
    r"holdToRip",
    r"HoldToRip",
    r"interactiveVideo",
    r"scrubVideo",
    r"videoProgress",
]:
    ms = list(re.finditer(pat, t))
    if ms:
        print(pat, "count", len(ms))
        s = ms[0].start()
        print(" ", t[max(0, s - 60) : s + 120].replace("\n", " "))
