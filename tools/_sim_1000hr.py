"""1000hr Bindora economy probe — A+ balance knobs applied."""
from __future__ import annotations

import json
import random
import statistics
from pathlib import Path

random.seed(42)

HARD_PITY = 12
CANDY_PER_USD = 100
CHASE_PCT = 0.95  # was 0.48 → 0.58 → 0.72


def daily_claim(streak: int) -> int:
    s = max(1, min(7, streak))
    return 240 + s * 90


def pity_boost(dry: int) -> float:
    return 1.0 + min(1.15, dry * 0.115)


def chase_threshold(price: float) -> float:
    return max(12.0, price * CHASE_PCT)


def ev_exp(price: float) -> float:
    if price <= 10:
        return 1.18
    if price <= 50:
        return 1.22
    if price <= 130:
        return 1.38
    if price <= 260:
        return 1.48
    if price <= 400:
        return 1.58
    return 1.70


def floor_chance(price: float) -> float:
    if price < 100:
        return 0.0
    return min(0.50, max(0.16, 0.16 + price / 500 * 0.34))


def near_miss_chance(price: float) -> float:
    if price >= 100:
        return 0.40
    if price >= 20:
        return 0.32
    return 0.24


def exchange_rate(fair: float) -> float:
    if fair < 2:
        return 0.45
    if fair < 15:
        return 0.58
    return 0.74


def make_tier_catalog(pack_price: float, n: int = 600) -> list[float]:
    prices: list[float] = []
    if pack_price < 10:
        bands = [(0.62, (0.10, 1.2)), (0.88, (1.2, 4)), (0.97, (4, 12)), (1.0, (12, 28))]
    elif pack_price < 40:
        bands = [(0.55, (0.15, 2)), (0.82, (2, 8)), (0.94, (8, 25)), (1.0, (25, 70))]
    elif pack_price < 150:
        bands = [(0.50, (0.2, 3)), (0.78, (3, 15)), (0.92, (15, 55)), (1.0, (55, 180))]
    else:
        bands = [(0.45, (0.3, 4)), (0.72, (4, 20)), (0.90, (20, 90)), (1.0, (90, 400))]

    for _ in range(n):
        u = random.random()
        for cut, (lo, hi) in bands:
            if u <= cut:
                prices.append(round(random.uniform(lo, hi), 2))
                break
    return sorted(prices)


def soft_pity_chance(price: float) -> float:
    if price >= 200:
        return 0.20
    if price >= 100:
        return 0.14
    return 0.08


def weighted_highlight(catalog: list[float], pack_price: float, dry: int) -> float:
    ranked = sorted(catalog, reverse=True)
    thr = chase_threshold(pack_price)
    if dry >= HARD_PITY and ranked:
        return random.choice(ranked[:3])

    if 7 <= dry < HARD_PITY and random.random() < soft_pity_chance(pack_price):
        over = [p for p in ranked[:12] if p >= thr]
        return random.choice(over[:4] if over else ranked[:3])

    if dry >= 3 and random.random() < near_miss_chance(pack_price):
        under = [p for p in ranked if p < thr]
        if len(under) >= 2:
            return random.choice(under[:6])
        pool = ranked[2:8] or ranked[:8]
        under2 = [p for p in pool if p < thr] or pool
        return random.choice(under2)

    fc = floor_chance(pack_price)
    if fc > 0 and random.random() < fc:
        floor = pack_price * 0.75
        elig = [p for p in catalog if floor <= p < thr] or [
            p for p in ranked if p < thr
        ][:20] or ranked[:20]
        return random.choice(elig)

    exp = ev_exp(pack_price)
    boost = pity_boost(dry)
    sample = random.sample(catalog, min(140, len(catalog)))
    weights = []
    for p in sample:
        w = p**exp
        if p >= thr * 0.7:
            w *= boost
        if pack_price >= 100 and p < 3:
            w *= 1.35
        weights.append(w)
    total = sum(weights) or 1.0
    r = random.random() * total
    acc = 0.0
    for p, w in zip(sample, weights):
        acc += w
        if acc >= r:
            return p
    return sample[-1]


def rip(catalog: list[float], pack_price: float, dry: int) -> dict:
    cheap = catalog[: max(40, int(len(catalog) * 0.55))]
    fillers = [random.choice(cheap) for _ in range(5)]
    if pack_price >= 50:
        fillers = [
            min(f, random.uniform(0.2, 3.5)) if random.random() < 0.5 else f for f in fillers
        ]
    highlight = weighted_highlight(catalog, pack_price, dry)
    cards = fillers + [highlight]
    max_fair = max(cards)
    cleared = max_fair >= chase_threshold(pack_price)
    recovered = sum(c * exchange_rate(c) for c in cards)
    return {
        "max_fair": max_fair,
        "highlight": highlight,
        "recovered": recovered,
        "net": recovered - pack_price,
        "cleared": cleared,
        "heat": min(100, round(dry / HARD_PITY * 100)),
    }


def sim(
    name: str,
    pack_price: float,
    hours: int = 1000,
    rips_per_hour: int = 16,
    keep_rate: float = 0.12,
    use_rentals: bool = False,
) -> dict:
    catalog = make_tier_catalog(pack_price)
    candy = 8000
    cash = 300.0
    dry = 0
    nets: list[float] = []
    wallet: list[float] = []
    dry_at_clear: list[int] = []
    heat_hist = [0] * 13
    clears = 0
    rips = 0
    candy_in = 0
    candy_out = 0
    chase_fairs: list[float] = []
    dry_stretch_max = 0
    hours_done = 0
    rips_h = 0
    cost_c = int(round(pack_price * CANDY_PER_USD))
    topups = 0.0
    hard_pity_hits = 0

    while hours_done < hours:
        if rips_h == 0:
            claim = daily_claim(1 + (hours_done % 7))
            # heated / 1-away bonuses ~half the time once grind is going
            if hours_done > 10 and dry >= 5:
                claim += 200
            if hours_done > 40 and random.random() < 0.25:
                claim += 150
            goals = 950
            candy += claim + goals
            candy_in += claim + goals
            if use_rentals and hours_done >= 24:
                rent = int(80 + min(350, hours_done * 0.12))
                candy += rent
                candy_in += rent

        if candy < cost_c:
            need = cost_c - candy
            need_usd = need / CANDY_PER_USD
            if cash >= need_usd:
                cash -= need_usd
                candy += need
            else:
                topups += need_usd - cash
                candy += need
                cash = 0.0
            candy_in += need

        candy -= cost_c
        candy_out += cost_c
        if dry >= HARD_PITY:
            hard_pity_hits += 1
        result = rip(catalog, pack_price, dry)
        rips += 1
        heat_hist[min(12, dry)] += 1
        dry_stretch_max = max(dry_stretch_max, dry)

        if result["cleared"]:
            clears += 1
            dry_at_clear.append(dry)
            chase_fairs.append(result["max_fair"])
            dry = 0
        else:
            dry += 1

        recovered = result["recovered"]
        economic_net = result["net"]
        if result["cleared"] and random.random() < keep_rate:
            recovered = max(
                0.0,
                recovered - result["highlight"] * exchange_rate(result["highlight"]),
            )
            cash_gain = result["highlight"] * 0.78
            cash += cash_gain
            economic_net = recovered + cash_gain - pack_price

        add = int(round(recovered * CANDY_PER_USD))
        candy += add
        candy_in += add
        nets.append(economic_net)

        rips_h += 1
        if rips_h >= rips_per_hour:
            hours_done += 1
            rips_h = 0
            wallet.append(round(candy / CANDY_PER_USD + cash, 2))

    nets_s = sorted(nets)
    return {
        "name": name,
        "packPrice": pack_price,
        "hours": hours,
        "rips": rips,
        "pityClears": clears,
        "clearRatePct": round(clears / max(1, rips) * 100, 2),
        "hardPityStartPct": round(hard_pity_hits / max(1, rips) * 100, 2),
        "avgNetPerRip": round(statistics.mean(nets), 3),
        "medianNet": round(statistics.median(nets), 3),
        "p10Net": round(nets_s[int(len(nets_s) * 0.1)], 3),
        "p90Net": round(nets_s[min(len(nets_s) - 1, int(len(nets_s) * 0.9))], 3),
        "avgDryAtClear": round(statistics.mean(dry_at_clear), 2) if dry_at_clear else None,
        "maxDrySeen": dry_stretch_max,
        "chaseAvgFair": round(statistics.mean(chase_fairs), 2) if chase_fairs else None,
        "endWalletUsd": wallet[-1] if wallet else 0,
        "externalTopupUsd": round(topups, 2),
        "walletEvery50h": wallet[49::50][:20],
        "heatVisits": heat_hist,
        "netCandyFlow": candy_in - candy_out,
        "chaseThreshold": round(chase_threshold(pack_price), 2),
    }


def main() -> None:
    players = [
        sim("Budget $6 packs", 5.99, rips_per_hour=18, keep_rate=0.08),
        sim("Mid $25 packs", 24.99, rips_per_hour=16, keep_rate=0.20, use_rentals=True),
        sim("Whale $130 packs", 129.99, rips_per_hour=12, keep_rate=0.55, use_rentals=True),
        sim("YGO $250 packs", 249.99, rips_per_hour=10, keep_rate=0.60, use_rentals=True),
    ]

    daily_max = daily_claim(7) + 950 + 200 + 150
    out = {
        "label": "post-A+-knobs",
        "assumptions": {
            "playHours": 1000,
            "chasePct": CHASE_PCT,
            "exchange": "tiered 50/62/72",
            "nearMissFromDry": 3,
            "premiumFloor": "0.14 + price/500*0.36",
        },
        "players": players,
        "dailyMaxCandy": daily_max,
        "freePacksPerDay": {
            "budget6": round(daily_max / 599, 2),
            "mid25": round(daily_max / 2499, 2),
            "whale130": round(daily_max / 12999, 2),
            "ygo250": round(daily_max / 24999, 2),
        },
    }
    path = Path(__file__).with_name("_sim_1000hr_out.json")
    path.write_text(json.dumps(out, indent=2), encoding="utf-8")
    print(path)
    for p in players:
        print(
            f"{p['name']}: clear={p['clearRatePct']}% avgNet={p['avgNetPerRip']} "
            f"p10={p['p10Net']} maxDry={p['maxDrySeen']} hardPityStarts={p['hardPityStartPct']}% "
            f"end={p['endWalletUsd']} topup={p['externalTopupUsd']} bar={p['chaseThreshold']}"
        )


if __name__ == "__main__":
    main()
