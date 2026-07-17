import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/onboarding.dart';
import 'game/game_controller.dart';
import 'theme/app_theme.dart';
import 'ui/collection_screen.dart';
import 'ui/discover_settings.dart';
import 'ui/instapacks_screen.dart';
import 'ui/market_screen.dart';
import 'ui/onboarding_flow.dart';
import 'widgets/pack_theater.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: VaultrexApp()));
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class VaultrexApp extends StatelessWidget {
  const VaultrexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vaultrex',
      debugShowCheckedModeBanner: false,
      theme: CC.dark(),
      scrollBehavior: AppScrollBehavior(),
      home: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool? _ready;
  bool _onboarded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final done = await OnboardingStore.isDone();
    if (!mounted) return;
    setState(() {
      _onboarded = done;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_ready != true) {
      return const Scaffold(
        backgroundColor: CC.bg,
        body: Center(child: CircularProgressIndicator(color: CC.accent)),
      );
    }
    if (!_onboarded) {
      return OnboardingFlow(
        onDone: () => setState(() => _onboarded = true),
      );
    }
    return const HomeShell();
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _index = 3; // land on Instapacks like RC after collect choose
  bool _lastRipPrompted = false;
  bool _lastRipDialogOpen = false;
  final _kept = <int, Widget>{};

  static Widget _create(int i) => switch (i) {
        0 => const DiscoverScreen(),
        1 => const CollectionScreen(),
        2 => const MarketScreen(),
        3 => const InstapacksScreen(),
        4 => const SettingsScreen(),
        _ => throw ArgumentError.value(i, 'i', 'Unknown tab index'),
      };

  Widget _pageFor(int i) {
    if (i == 1 || i == 3) {
      return _kept.putIfAbsent(i, () => _create(i));
    }
    return _create(i);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptLastRip());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(gameProvider.notifier).catchUpOnlineSales();
    }
  }

  void _maybePromptLastRip() {
    if (!mounted || _lastRipDialogOpen) return;
    final state = ref.read(gameProvider);
    if (!state.ready) return;
    _showLastRipDialogIfNeeded(state);
  }

  void _showLastRipDialogIfNeeded(GameState state) {
    if (_lastRipDialogOpen) return;
    if (state.lastRip?.isNotEmpty != true) {
      _lastRipPrompted = false;
      return;
    }
    if (_lastRipPrompted) return;
    _lastRipPrompted = true;
    _lastRipDialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Unfinished rip'),
        content: const Text('You still have cards from an open pack.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(gameProvider.notifier)
                  .finalizeRip(keepRemaining: true);
              _lastRipDialogOpen = false;
              _lastRipPrompted = false;
            },
            child: const Text('Keep all'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _lastRipDialogOpen = false;
              // Keep prompted while theater is active; clear if rip ends empty.
              showPackTheater(context, ref, alreadyOpened: true).whenComplete(() {
                if (!mounted) return;
                final still = ref.read(gameProvider).lastRip?.isNotEmpty == true;
                _lastRipPrompted = still;
              });
            },
            child: const Text('Resume'),
          ),
        ],
      ),
    ).whenComplete(() {
      _lastRipDialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GameState>(gameProvider, (prev, next) {
      final had = prev?.lastRip?.isNotEmpty == true;
      final has = next.lastRip?.isNotEmpty == true;
      if (!has) {
        _lastRipPrompted = false;
      } else if (!had && has) {
        _lastRipPrompted = false;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _maybePromptLastRip());
      }
      final msg = next.message;
      if (msg != null &&
          msg != prev?.message &&
          msg.startsWith('While you were away:')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        });
      }
    });

    final ready = ref.watch(gameProvider.select((s) => s.ready));
    if (ready && !_lastRipPrompted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptLastRip());
    }

    // Active + any keep-alive tabs (1 Collection, 3 Instapacks).
    final toShow = <int>{_index, ..._kept.keys};
    if (_index == 1 || _index == 3) {
      _pageFor(_index);
    }
    final ordered = toShow.toList()..sort();

    final stackChildren = <Widget>[
      for (final i in ordered)
        IgnorePointer(
          ignoring: _index != i,
          child: AnimatedOpacity(
            opacity: _index == i ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: TickerMode(
              enabled: _index == i,
              child: _pageFor(i),
            ),
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: CC.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: stackChildren,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: CC.bgElevated,
          border: Border(top: BorderSide(color: CC.line)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Discover',
            ),
            const NavigationDestination(
              icon: Icon(Icons.style_outlined),
              selectedIcon: Icon(Icons.style),
              label: 'Collection',
            ),
            NavigationDestination(
              icon: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CC.scan, width: 2),
                ),
                child: const Icon(Icons.storefront_outlined, color: CC.scan),
              ),
              selectedIcon: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CC.scan, width: 2),
                  color: CC.scan.withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.storefront, color: CC.scan),
              ),
              label: 'Market',
            ),
            const NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Instapacks',
            ),
            const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
