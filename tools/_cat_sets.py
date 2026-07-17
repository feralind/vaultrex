import json
from collections import Counter
cat_path = r"C:\Users\Tom\AndroidStudioProjects\cardflip\assets\data\pokemon_catalog.json"
cat = json.load(open(cat_path, encoding="utf-8-sig"))
print("setCodes:", cat.get("setCodes"))
codes = ["MEW","OBF","PAL","TWM","SSP","PRE"]
for c in codes:
    cards = [x for x in cat["cards"] if x.get("setCode")==c or x.get("set")==c]
    if cards:
        names = Counter(x.get("setName") or x.get("setTitle") for x in cards)
        print(c, "count", len(cards), "names", dict(names))
