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

  test('Scrydex leaves MTG on catalog CDN', () {
    final mtg = CardDef(
      id: 'mtg_FDN_1',
      productId: 1,
      setCode: 'FDN',
      setName: 'Foundations',
      name: 'Island',
      rarity: Rarity.common,
      marketPrice: 0.1,
      imageUrl: 'https://tcgplayer-cdn.tcgplayer.com/product/1_in_1000x1000.jpg',
      imageUrlSmall: 'https://tcgplayer-cdn.tcgplayer.com/product/1_200w.jpg',
      imageKey: 'k',
      number: '1',
    );
    expect(ScrydexArt.imageUrl(mtg), isNull);
    expect(mtg.displayArtUrl, startsWith('https://tcgplayer-cdn'));
  });
}
