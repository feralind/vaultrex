# Builds assets/data/riftbound_catalog.json + sealed_products.json from TCGCSV raw dumps.
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$raw = Join-Path $PSScriptRoot "raw"
$outDir = Join-Path $root "assets\data"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$sets = @(
  @{ code = "OGS"; name = "Origins: Proving Grounds"; groupId = 24439 },
  @{ code = "OGN"; name = "Origins"; groupId = 24344 },
  @{ code = "SFD"; name = "Spiritforged"; groupId = 24519 },
  @{ code = "UNL"; name = "Unleashed"; groupId = 24560 }
)

function Get-Ext($extended, $key) {
  if (-not $extended) { return $null }
  foreach ($e in $extended) {
    if ($e.name -eq $key -or $e.displayName -eq $key) { return [string]$e.value }
  }
  return $null
}

function Normalize-Rarity([string]$r) {
  if (-not $r) { return "Common" }
  $t = $r.Trim()
  switch -Regex ($t) {
    '^(C|Common)$' { return "Common" }
    '^(U|Uncommon)$' { return "Uncommon" }
    '^(R|Rare)$' { return "Rare" }
    '^(E|Epic)$' { return "Epic" }
    'Showcase|Alternate|Alt Art' { return "Showcase" }
    'Overnumbered|Over.?number' { return "Overnumbered" }
    'Signature|Signed' { return "Signature" }
    'Ultimate' { return "Ultimate" }
    'Token|Rune' { return "Token" }
    default { return $t }
  }
}

$cards = New-Object System.Collections.Generic.List[object]
$sealed = New-Object System.Collections.Generic.List[object]
$priceMap = @{}

foreach ($s in $sets) {
  $prices = (Get-Content (Join-Path $raw "prices_$($s.code).json") -Raw | ConvertFrom-Json).results
  foreach ($pr in $prices) {
    $prodId = [string]$pr.productId
    $mp = $pr.marketPrice
    if ($null -eq $mp) { $mp = $pr.midPrice }
    if ($null -eq $mp) { $mp = $pr.lowPrice }
    if ($null -eq $mp) { $mp = 0 }
    $priceMap["$prodId|$($pr.subTypeName)"] = [double]$mp
    if (-not $priceMap.ContainsKey($prodId)) {
      $priceMap[$prodId] = [double]$mp
    } elseif ([double]$mp -gt $priceMap[$prodId]) {
      $priceMap[$prodId] = [double]$mp
    }
  }
}

foreach ($s in $sets) {
  $products = (Get-Content (Join-Path $raw "products_$($s.code).json") -Raw | ConvertFrom-Json).results
  foreach ($p in $products) {
    $name = [string]$p.name
    # Sealed / non-singles: packs, boxes, kits, promo packs, bulk runes, etc.
    # Kits (Pre-Rift Event Kit) must NEVER enter the card singles catalog.
    $isSealed = $name -match 'Booster Pack|Booster Display|Display Case|Champion Deck|Sleeved Booster|Bundle|Box|Pre-Rift|Event Kit|\bKit\b|Promo Pack|Bulk Runes|Art Bundle'
    $rarity = Normalize-Rarity (Get-Ext $p.extendedData "Rarity")
    $number = Get-Ext $p.extendedData "Number"
    $cardType = Get-Ext $p.extendedData "Card Type"
    $domain = Get-Ext $p.extendedData "Domain"
    $prodId = [int]$p.productId
    $img = [string]$p.imageUrl
    # TCGPlayer CDN sizes: _200w (thumb), _400w (medium), _in_1000x1000 (largest public).
    if ($img -match '_200w\.jpg$') {
      $imgSmall = $img
      $imgHi = $img -replace '_200w\.jpg$', '_in_1000x1000.jpg'
    } elseif ($img -match '_400w\.jpg$') {
      $imgSmall = $img -replace '_400w\.jpg$', '_200w.jpg'
      $imgHi = $img -replace '_400w\.jpg$', '_in_1000x1000.jpg'
    } elseif ($img -match '_in_\d+x\d+\.jpg$') {
      $imgHi = $img
      $imgSmall = $img -replace '_in_\d+x\d+\.jpg$', '_200w.jpg'
    } else {
      $imgHi = $img
      $imgSmall = $img
    }
    $market = 0.0
    if ($priceMap.ContainsKey("$prodId|Normal")) { $market = $priceMap["$prodId|Normal"] }
    elseif ($priceMap.ContainsKey([string]$prodId)) { $market = $priceMap[[string]$prodId] }

    $foilMarket = $null
    if ($priceMap.ContainsKey("$prodId|Foil")) { $foilMarket = $priceMap["$prodId|Foil"] }
    elseif ($priceMap.ContainsKey("$prodId|Holofoil")) { $foilMarket = $priceMap["$prodId|Holofoil"] }

    # No collector number + sealed-like name, or explicit sealed match → sealed SKU.
    if ($isSealed -or (-not $number -and -not $rarity) -or (-not $number -and $name -match 'Pack|Kit|Case|Display|Deck|Bundle|Runes')) {
      $kind = "other"
      if ($name -match 'Booster Display(?! Case)') { $kind = "box" }
      elseif ($name -match 'Booster Pack|Sleeved Booster Pack$') { $kind = "pack" }
      elseif ($name -match 'Champion Deck') { $kind = "deck" }
      elseif ($name -match 'Display Case') { $kind = "displayCase" }
      elseif ($name -match 'Pre-Rift|Event Kit|\bKit\b') { $kind = "other" }

      $sealedPrice = $market
      foreach ($k in @("$prodId|Normal", "$prodId|", [string]$prodId)) {
        if ($priceMap.ContainsKey($k) -and $priceMap[$k] -gt 0) { $sealedPrice = $priceMap[$k]; break }
      }

      $sealed.Add([ordered]@{
        id = "sku_$prodId"
        productId = $prodId
        setCode = $s.code
        setName = $s.name
        name = $name
        kind = $kind
        marketPrice = [math]::Round([double]$sealedPrice, 2)
        imageUrl = $imgHi
        imageUrlSmall = $imgSmall
        packsPerBox = $(if ($kind -eq "box") { 24 } else { $null })
      }) | Out-Null
      continue
    }

    # Singles must have a collector number (e.g. 039/298 or 227*/221).
    if (-not $number) { continue }
    if ($name -match 'Booster|Display|Deck|Bundle|Kit|Promo Pack|Bulk Runes') { continue }

    $cards.Add([ordered]@{
      id = "rb_$prodId"
      productId = $prodId
      setCode = $s.code
      setName = $s.name
      name = $name
      number = $number
      rarity = $rarity
      cardType = $cardType
      domain = $domain
      marketPrice = [math]::Round([double]$market, 2)
      foilMarketPrice = $(if ($null -ne $foilMarket) { [math]::Round([double]$foilMarket, 2) } else { $null })
      imageUrl = $imgHi
      imageUrlSmall = $imgSmall
      imageKey = "rb_$prodId"
    }) | Out-Null
  }
}

# Deduplicate by id
$cardMap = @{}
foreach ($c in $cards) { $cardMap[$c.id] = $c }
$cardList = @($cardMap.Values | Sort-Object { $_.setCode }, { $_.number }, { $_.name })

$sealedMap = @{}
foreach ($c in $sealed) { $sealedMap[$c.id] = $c }
$sealedList = @($sealedMap.Values | Sort-Object { $_.setCode }, { $_.kind }, { $_.name })

$catalog = [ordered]@{
  generatedAt = (Get-Date).ToUniversalTime().ToString("o")
  source = "tcgcsv.com category 89"
  setCodes = @("OGS", "OGN", "SFD", "UNL")
  cardCount = $cardList.Count
  cards = $cardList
}
$sealedOut = [ordered]@{
  generatedAt = (Get-Date).ToUniversalTime().ToString("o")
  source = "tcgcsv.com category 89"
  productCount = $sealedList.Count
  products = $sealedList
}

$catalogPath = Join-Path $outDir "riftbound_catalog.json"
$sealedPath = Join-Path $outDir "sealed_products.json"
[System.IO.File]::WriteAllText($catalogPath, ($catalog | ConvertTo-Json -Depth 8 -Compress))
[System.IO.File]::WriteAllText($sealedPath, ($sealedOut | ConvertTo-Json -Depth 8 -Compress))

Write-Host "Cards: $($cardList.Count)"
Write-Host "Sealed: $($sealedList.Count)"
Write-Host "Wrote $catalogPath"
Write-Host "Wrote $sealedPath"
$cardList | Group-Object rarity | Sort-Object Count -Descending | ForEach-Object { Write-Host ("  {0}: {1}" -f $_.Name, $_.Count) }
$sealedList | Group-Object kind | ForEach-Object { Write-Host ("  sealed {0}: {1}" -f $_.Name, $_.Count) }
