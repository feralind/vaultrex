import 'package:flutter_test/flutter_test.dart';
import 'package:bindora/data/scrydex_art.dart';
import 'package:bindora/models/enums.dart';
import 'package:bindora/models/models.dart';

CardDef _pkm({
  required String setCode,
  required String number,
  String name = 'Test',
}) {
  return CardDef(
    id: 'pkm_${setCode}_$number',
    productId: 1,
    setCode: setCode,
    setName: 'Set',
    name: name,
    rarity: Rarity.common,
    marketPrice: 1,
    imageUrl: 'https://example.com/a.jpg',
    imageUrlSmall: 'https://example.com/a_s.jpg',
    imageKey: 'k',
    number: number,
  );
}

CardDef _rb({
  required String setCode,
  required String number,
  String name = 'Test',
  String? cardType,
  String? domain,
}) {
  return CardDef(
    id: 'rb_$number',
    productId: 1,
    setCode: setCode,
    setName: 'Set',
    name: name,
    rarity: Rarity.common,
    marketPrice: 1,
    imageUrl: 'https://tcgplayer-cdn.tcgplayer.com/x.jpg',
    imageUrlSmall: 'https://tcgplayer-cdn.tcgplayer.com/x_s.jpg',
    imageKey: 'k',
    number: number,
    cardType: cardType,
    domain: domain,
  );
}

CardDef _mtg({
  required String setCode,
  required String number,
  String name = 'Test',
}) {
  return CardDef(
    id: 'mtg_${setCode}_$number',
    productId: 1,
    setCode: setCode,
    setName: 'Foundations',
    name: name,
    rarity: Rarity.common,
    marketPrice: 0.1,
    imageUrl: 'https://tcgplayer-cdn.tcgplayer.com/product/1_in_1000x1000.jpg',
    imageUrlSmall: 'https://tcgplayer-cdn.tcgplayer.com/product/1_200w.jpg',
    imageKey: 'k',
    number: number,
  );
}

CardDef _op({
  required String setCode,
  required String number,
  String name = 'Test',
}) {
  return CardDef(
    id: 'op_${setCode}_$number',
    productId: 1,
    setCode: setCode,
    setName: 'Romance Dawn',
    name: name,
    rarity: Rarity.common,
    marketPrice: 1,
    imageUrl: 'https://tcgplayer-cdn.tcgplayer.com/product/1_in_1000x1000.jpg',
    imageUrlSmall: 'https://tcgplayer-cdn.tcgplayer.com/product/1_200w.jpg',
    imageKey: 'k',
    number: number,
  );
}

void main() {
  test('Scrydex maps Pokémon set codes to expansion art URLs', () {
    final bulba = _pkm(setCode: 'MEW', number: '001/165');
    expect(ScrydexArt.cardIdFor(bulba), 'sv3pt5-1');
    expect(
      ScrydexArt.imageUrl(bulba, size: 'large'),
      'https://images.scrydex.com/pokemon/sv3pt5-1/large',
    );
    expect(bulba.displayArtUrl, contains('images.scrydex.com'));
  });

  test('Scrydex maps Pokémon logos and symbols', () {
    final bulba = _pkm(setCode: 'MEW', number: '001/165');
    expect(
      ScrydexArt.expansionLogoUrl(bulba),
      'https://images.scrydex.com/pokemon/sv3pt5-logo/logo',
    );
    expect(
      ScrydexArt.expansionSymbolUrl(bulba),
      'https://images.scrydex.com/pokemon/sv3pt5-symbol/symbol',
    );
    expect(ScrydexArt.displaySetLine(bulba), contains('sv3pt5'));
    expect(ScrydexArt.displaySetName(bulba), 'Scarlet & Violet 151');
  });

  test('Scrydex maps Riftbound OGS/SFD/UNL art + logos', () {
    final annie = _rb(
      setCode: 'OGS',
      number: '001/024',
      name: 'Annie - Fiery',
      cardType: 'Unit',
      domain: 'Fury',
    );
    expect(ScrydexArt.cardIdFor(annie), 'OGS-1');
    expect(
      ScrydexArt.imageUrl(annie),
      'https://images.scrydex.com/riftbound/OGS-1/large',
    );
    expect(ScrydexArt.expansionLogoUrl(annie), contains('OGS-logo'));
    expect(ScrydexArt.expansionSymbolUrl(annie), isNull);
    expect(ScrydexArt.printedNumberLabel(annie), '#001/024');
    expect(ScrydexArt.riftboundExpansion('SFD')?.name, 'Spiritforged');
    expect(ScrydexArt.riftboundExpansion('UNL')?.name, 'Unleashed');
  });

  test('Scrydex token numbers keep T-padding', () {
    final gold = _rb(setCode: 'SFD', number: 'T03/221', name: 'Gold');
    expect(ScrydexArt.cardIdFor(gold), 'SFD-T03');
    expect(
      ScrydexArt.imageUrl(gold),
      'https://images.scrydex.com/riftbound/SFD-T03/large',
    );
  });

  test('Scrydex signature star numbers use s suffix (not overnumbered art)', () {
    final teemoSig = _rb(
      setCode: 'OGN',
      number: '307*/298',
      name: 'Teemo - Swift Scout (Signature)',
    );
    final teemoOver = _rb(
      setCode: 'OGN',
      number: '307/298',
      name: 'Teemo - Swift Scout (Overnumbered)',
    );
    expect(ScrydexArt.normalizeNumber('307*/298'), '307s');
    expect(ScrydexArt.cardIdFor(teemoSig), 'OGN-307s');
    expect(
      ScrydexArt.imageUrl(teemoSig),
      'https://images.scrydex.com/riftbound/OGN-307s/large',
    );
    expect(ScrydexArt.cardIdFor(teemoOver), 'OGN-307');
    expect(ScrydexArt.printedNumberLabel(teemoSig), '#307*/298');
    expect(teemoSig.displayArtUrl, contains('OGN-307s'));
    expect(teemoOver.displayArtUrl, contains('OGN-307/'));
  });

  test('Scrydex alternate-art letter suffixes stay intact', () {
    final alt = _rb(
      setCode: 'OGN',
      number: '121a/298',
      name: 'Teemo - Strategist (Alternate Art)',
    );
    expect(ScrydexArt.cardIdFor(alt), 'OGN-121a');
    expect(
      ScrydexArt.imageUrl(alt),
      'https://images.scrydex.com/riftbound/OGN-121a/large',
    );
  });

  test('Runes and oversized prefer catalog art; tokens use Scrydex when present', () {
    final rune = _rb(setCode: 'SFD', number: 'R01', name: 'Fury Rune');
    final oversized = _rb(
      setCode: 'OGS',
      number: '279/298',
      name: 'Fortified Position (Oversized)',
    );
    final token = _rb(
      setCode: 'UNL',
      number: 'T01 // T05',
      name: 'Baron Pit // Gold',
    );
    expect(ScrydexArt.preferCatalogArt(rune), isTrue);
    expect(ScrydexArt.preferCatalogArt(oversized), isTrue);
    expect(ScrydexArt.preferCatalogArt(token), isFalse);
    expect(ScrydexArt.imageUrl(rune), isNull);
    expect(ScrydexArt.cardIdFor(token), 'UNL-T05');
    expect(
      ScrydexArt.imageUrl(token),
      'https://images.scrydex.com/riftbound/UNL-T05/large',
    );
    expect(rune.displayArtUrl, contains('tcgplayer'));
  });

  test('Scrydex maps MTG art + logos + symbols', () {
    final elves = _mtg(setCode: 'FDN', number: '227', name: 'Llanowar Elves');
    expect(ScrydexArt.cardIdFor(elves), 'FDN-227');
    expect(
      ScrydexArt.imageUrl(elves),
      'https://images.scrydex.com/magicthegathering/FDN-227/large',
    );
    expect(elves.displayArtUrl, contains('magicthegathering/FDN-227'));
    expect(
      ScrydexArt.expansionLogoUrl(elves),
      'https://images.scrydex.com/magicthegathering/FDN-logo/logo',
    );
    expect(
      ScrydexArt.expansionSymbolUrl(elves),
      'https://images.scrydex.com/magicthegathering/FDN-symbol/symbol',
    );
    expect(ScrydexArt.printedNumberLabel(elves), '#227/291');
    expect(ScrydexArt.displaySetName(elves), 'Foundations');
  });

  test('Scrydex strips MTG dual-face left number', () {
    final tok = _mtg(setCode: 'BLB', number: '3 // 7', name: 'Rabbit // Fish');
    expect(ScrydexArt.cardIdFor(tok), 'BLB-3');
    expect(
      ScrydexArt.imageUrl(tok),
      'https://images.scrydex.com/magicthegathering/BLB-3/large',
    );
  });

  test('Scrydex maps One Piece OP01-001 style ids', () {
    final luffy = _op(setCode: 'OP01', number: '001', name: 'Monkey.D.Luffy');
    expect(ScrydexArt.cardIdFor(luffy), 'OP01-001');
    expect(
      ScrydexArt.imageUrl(luffy),
      'https://images.scrydex.com/onepiece/OP01-001/large',
    );
    expect(luffy.isOnePieceCard, isTrue);
    expect(luffy.franchiseId, 'onepiece');
    expect(
      ScrydexArt.expansionLogoUrl(luffy),
      'https://images.scrydex.com/onepiece/OP01-logo/logo',
    );
    expect(ScrydexArt.displaySetName(luffy), 'Romance Dawn');
  });

  test('Scrydex pads One Piece bare collector numbers', () {
    final zoro = _op(setCode: 'OP01', number: '6', name: 'Roronoa Zoro');
    expect(ScrydexArt.cardIdFor(zoro), 'OP01-006');
    expect(
      ScrydexArt.imageUrl(zoro),
      'https://images.scrydex.com/onepiece/OP01-006/large',
    );
  });

  test('Scrydex accepts full One Piece number OP05-119', () {
    final gear5 = _op(setCode: 'OP05', number: 'OP05-119', name: 'Luffy');
    expect(ScrydexArt.normalizeNumber('OP05-119'), '119');
    expect(ScrydexArt.cardIdFor(gear5), 'OP05-119');
    expect(
      ScrydexArt.imageUrl(gear5),
      'https://images.scrydex.com/onepiece/OP05-119/large',
    );
  });

  test('One Piece displayArtUrl prefers catalog over Scrydex', () {
    final zoro = _op(setCode: 'OP01', number: 'OP01-001', name: 'Zoro');
    expect(zoro.displayArtUrl, zoro.imageUrl);
    expect(zoro.displayArtUrl.contains('scrydex'), isFalse);
    final local = CardDef(
      id: 'op_local',
      productId: 1,
      setCode: 'OP01',
      setName: 'Romance Dawn',
      name: 'Zoro',
      rarity: Rarity.epic,
      marketPrice: 1,
      imageUrl: 'assets/card_art/onepiece/op_local.webp',
      imageUrlSmall: 'assets/card_art/onepiece/op_local.webp',
      imageKey: 'k',
      number: 'OP01-001',
    );
    expect(local.displayArtUrl, 'assets/card_art/onepiece/op_local.webp');
  });

  test('Yu-Gi-Oh! catalog art is preferred and franchise tags resolve', () {
    final dm = CardDef(
      id: 'ygo_123',
      productId: 123,
      setCode: 'RA05',
      setName: 'Rarity Collection 5',
      name: 'Dark Magician',
      rarity: Rarity.epic,
      marketPrice: 10,
      imageUrl: 'assets/card_art/yugioh/pc_46986414.webp',
      imageUrlSmall: 'assets/card_art/yugioh/pc_46986414.webp',
      imageKey: 'ygo_123',
      number: 'RA05-EN001',
    );
    expect(dm.isYugiohCard, isTrue);
    expect(dm.franchiseId, 'yugioh');
    expect(dm.franchiseDisplayName, 'Yu-Gi-Oh!');
    expect(dm.displayArtUrl, 'assets/card_art/yugioh/pc_46986414.webp');
    expect(dm.thumbArtUrl, 'assets/card_art/yugioh/pc_46986414.webp');
  });
}
