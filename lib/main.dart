import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/onboarding.dart';
import 'theme/app_theme.dart';
import 'ui/collection_screen.dart';
import 'ui/discover_settings.dart';
import 'ui/instapacks_screen.dart';
import 'ui/market_screen.dart';
import 'ui/onboarding_flow.dart';

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

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 3; // land on Instapacks like RC after collect choose

  static const _pages = [
    DiscoverScreen(),
    CollectionScreen(),
    MarketScreen(),
    InstapacksScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CC.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < _pages.length; i++)
              IgnorePointer(
                ignoring: _index != i,
                child: AnimatedOpacity(
                  opacity: _index == i ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: TickerMode(
                    enabled: _index == i,
                    child: _pages[i],
                  ),
                ),
              ),
          ],
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
