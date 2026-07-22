# Market price data attribution

- **Spot prices** (`riftbound_catalog.json` `marketPrice` / `foilMarketPrice`):
  [TCGCSV](https://tcgcsv.com) nightly mirror of TCGplayer category **89**
  (Riftbound), groups OGS/OGN/SFD/UNL. Rebuilt via `tools/build_catalog.ps1`.
- **Chase cross-check (Jul 2026)**: PriceCharting Origins/Spiritforged guides
  and CardsRealm “most expensive” list (signatures: Ahri Inquisitive, Kai'Sa,
  Irelia Fervent, etc.). Catalog spots track TCGCSV within typical market swing.
- **`price_history.json`**: daily closes for UI charts. TCGplayer does not
  publish a free historical series; paths are mean-reverting around the
  researched spot (±realistic secondary-market volatility), ending at spot.
- **Pokémon + Riftbound + MTG + One Piece card scan art (runtime)**: [Scrydex](https://scrydex.com)
  image CDN (`images.scrydex.com/{pokemon|riftbound|magicthegathering|onepiece}/{id}/…`),
  expansion logos (`…/{game}/{id}-logo/logo`), and set symbols for Pokémon/MTG/OP
  (`…/{game}/{id}-symbol/symbol`). Metadata/pricing API requires a Scrydex key
  (not bundled).
- **One Piece spots** (`onepiece_catalog.json`): TCGCSV category **68**, groups
  OP01/OP02/OP05/OP09/OP13/PRB-01. Rebuilt via `tools/build_onepiece_catalog.py`.
- **Yu-Gi-Oh! spots** (`yugioh_catalog.json`): TCGCSV category **2**, groups
  LOB/RA04/RA05/DOOD/PHRE/BPRO/BLZD. Card art is **rehosted locally** under
  `assets/card_art/yugioh/` (sourced from [YGOPRODeck](https://ygoprodeck.com);
  their CDN forbids hotlinking and lacks CORS). Rebuild catalog with
  `tools/build_yugioh_catalog.py`, then `tools/cache_yugioh_art.py`.
