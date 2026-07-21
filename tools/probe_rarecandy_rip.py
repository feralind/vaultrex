#!/usr/bin/env python3
"""Probe Rare Candy packs frontend for video vs interactive rip tech."""

from __future__ import annotations

import json
import re
import urllib.request
from pathlib import Path

OUT = Path(r"C:/Users/Tom/AppData/Local/Temp/rc_js")
OUT.mkdir(exist_ok=True)
BASES = [
    "https://packs.rarecandy.com",
    "https://auth.rarecandy.com",
]
UA = {"User-Agent": "Mozilla/5.0"}


def fetch(url: str) -> bytes:
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=45) as r:
        return r.read()


def main() -> None:
    all_chunks: set[str] = set()
    for base in BASES:
        try:
            html = fetch(base + "/").decode("utf-8", "replace")
            (OUT / f"{base.split('//')[1].split('.')[0]}_home.html").write_text(
                html, encoding="utf-8"
            )
            chunks = re.findall(r"/_next/static/chunks/[^\"']+\.js", html)
            print(base, "html", len(html), "chunks", len(chunks))
            for c in chunks:
                all_chunks.add(base + c)
        except Exception as e:
            print("fail home", base, e)

    # Also try demo rip route HTML (may redirect)
    for path in ["/packs/demo/rip", "/packs/demo", "/packs"]:
        url = "https://packs.rarecandy.com" + path
        try:
            data = fetch(url)
            text = data.decode("utf-8", "replace")
            (OUT / f"route_{path.strip('/').replace('/', '_') or 'root'}.html").write_text(
                text, encoding="utf-8"
            )
            chunks = re.findall(r"/_next/static/chunks/[^\"']+\.js", text)
            print("route", path, "len", len(data), "chunks", len(chunks))
            for c in chunks:
                all_chunks.add("https://packs.rarecandy.com" + c)
        except Exception as e:
            print("fail route", path, e)

    patterns = {
        "mp4": r"\.mp4",
        "webm": r"\.webm",
        "m3u8": r"\.m3u8",
        "video_tag": r"HTMLVideoElement|createElement\([\"']video[\"']\)|<video",
        "mux": r"mux\.|stream\.mux|@mux",
        "cfstream": r"cloudflarestream|videodelivery",
        "peel": r"peel",
        "rip": r"\brip\b|packRip|pack_rip|ripPack",
        "currentTime": r"currentTime",
        "playbackRate": r"playbackRate",
        "lottie": r"lottie|dotlottie",
        "rive": r"@rive|rive-app|\.riv\b",
        "three": r"three\.js|from [\"']three[\"']",
        "gsap": r"gsap|ScrollTrigger",
        "scrub": r"scrub",
        "canvas": r"getContext\([\"'](?:2d|webgl)",
        "cdn_media": r"https?://[^\"'\s]+\.(?:mp4|webm|m3u8)",
        "media_url": r"https?://[^\"'\s]*(?:video|media|rip|peel|pack)[^\"'\s]*",
    }

    summary = []
    media_urls: set[str] = set()
    for url in sorted(all_chunks):
        name = url.rsplit("/", 1)[-1]
        try:
            data = fetch(url)
            (OUT / name).write_bytes(data)
            text = data.decode("utf-8", "replace")
            found = {}
            for key, pat in patterns.items():
                ms = re.findall(pat, text, re.I)
                if ms:
                    found[key] = len(ms)
                    if key in {"cdn_media", "media_url"}:
                        media_urls.update(ms[:20])
            if found:
                summary.append({"file": name, "size": len(data), "hits": found})
                print("HIT", name, found)
            else:
                print("ok", name, len(data))
        except Exception as e:
            print("fail chunk", name, e)

    # Grep interesting string literals around video
    print("\n=== SAMPLE STRINGS ===")
    for p in OUT.glob("*.js"):
        text = p.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(
            r"[\"']([^\"']{8,180}\.(?:mp4|webm|m3u8|riv|json)(?:\?[^\"']*)?)[\"']",
            text,
            re.I,
        ):
            print(p.name, "->", m.group(1)[:200])
        for m in re.finditer(
            r"[\"'](https?://[^\"']+(?:video|stream|mux|cloudflare|cdn)[^\"']+)[\"']",
            text,
            re.I,
        ):
            print(p.name, "URL->", m.group(1)[:220])

    report = {
        "chunks_scanned": len(all_chunks),
        "files_with_hits": summary,
        "media_urls": sorted(media_urls)[:100],
    }
    (OUT / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("\nWrote", OUT / "report.json")


if __name__ == "__main__":
    main()
