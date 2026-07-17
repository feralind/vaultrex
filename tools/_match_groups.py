import json
groups_path = r"C:\Users\Tom\.cursor\projects\c-Users-Tom-AndroidStudioProjects-cardflip\agent-tools\e1f0fe5e-3b1f-4a39-93b9-2fd9e9ebaf4c.txt"
cat_path = r"C:\Users\Tom\AndroidStudioProjects\cardflip\assets\data\pokemon_catalog.json"
groups = json.load(open(groups_path, encoding="utf-8"))["results"]
cat = json.load(open(cat_path, encoding="utf-8-sig"))
sn = cat.get("setNames") or {}
print("setNames from catalog:")
for code in ["MEW","OBF","PAL","TWM","SSP","PRE"]:
    print(f"  {code}: {sn.get(code)!r}")

print("\nExact abbreviation matches:")
for code in ["MEW","OBF","PAL","TWM","SSP","PRE"]:
    for g in groups:
        if (g.get("abbreviation") or "").upper() == code:
            print(f"  {code}: groupId={g['groupId']} name={g['name']}")

print("\nFuzzy name/abbr matches:")
keywords = {
    "MEW": ["151", "mew"],
    "OBF": ["obsidian", "obf"],
    "PAL": ["paldea", "pal"],
    "TWM": ["twilight", "twm", "masquerade"],
    "SSP": ["surging", "ssp", "sparks"],
    "PRE": ["prismatic", "pre"],
}
for g in groups:
    name = (g.get("name") or "").lower()
    abbr = (g.get("abbreviation") or "").lower()
    hay = f"{name} {abbr}"
    hits = []
    for code, pats in keywords.items():
        if any(p in hay for p in pats):
            hits.append(code)
    if hits:
        print(f"  hits={hits} id={g['groupId']} abbr={g.get('abbreviation')} name={g.get('name')}")
