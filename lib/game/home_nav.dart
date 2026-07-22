import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Request HomeShell to switch tabs (e.g. resume toast → Collection).
/// HomeShell consumes and clears.
class HomeTabRequest extends Notifier<int?> {
  @override
  int? build() => null;

  void request(int tab) => state = tab;

  void clear() => state = null;
}

final homeTabRequestProvider =
    NotifierProvider<HomeTabRequest, int?>(HomeTabRequest.new);

abstract final class HomeTabs {
  static const discover = 0;
  static const collection = 1;
  static const market = 2;
  static const instapacks = 3;
  static const settings = 4;
}
