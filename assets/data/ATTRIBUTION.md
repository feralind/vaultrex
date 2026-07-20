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
- **Pokémon + Riftbound card scan art (runtime)**: [Scrydex](https://scrydex.com)
  image CDN (`images.scrydex.com/{pokemon|riftbound}/{id}/…`) and expansion
  logos (`…/riftbound/{SET}-logo/logo`). Metadata/pricing API requires a
  Scrydex key (not bundled).
