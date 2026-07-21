import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/engagement_defs.dart';
import 'data/onboarding.dart';
import 'game/game_controller.dart';
import 'services/bindora_feel.dart';
import 'services/startup_preload.dart';
import 'theme/app_theme.dart';
import 'ui/collection_screen.dart';
import 'ui/discover_settings.dart';
import 'ui/engagement/engagement_hub.dart';
import 'ui/instapacks_screen.dart';
import 'ui/market_screen.dart';
import 'ui/onboarding_flow.dart';
import 'ui/startup_splash.dart';
import 'widgets/home_bottom_nav.dart';
import 'widgets/pack_theater_v2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BindoraSounds.init();
  runApp(const ProviderScope(child: BindoraApp()));
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

class BindoraApp extends StatelessWidget {
  const BindoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bindora',
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
  bool _bootDone = false;
  bool _onboarded = false;
  double _preloadProgress = 0;
  String _preloadStatus = 'Starting…';

  @override
  void initState() {
    super.initState();
    // Precache needs a mounted [BuildContext] with an ImageConfiguration.
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    final onboardedFuture = OnboardingStore.isDone();
    final gameIdFuture = OnboardingStore.selectedGame();
    var listening = true;

    try {
      final gameId = await gameIdFuture;
      if (!mounted) return;
      await StartupPreload.run(
        context: context,
        gameId: gameId,
        onProgress: (p) {
          if (!mounted || !listening) return;
          setState(() {
            _preloadProgress = p.fraction;
            _preloadStatus = p.status;
          });
        },
      );
    } catch (e) {
      debugPrint('Startup preload failed: $e');
    } finally {
      listening = false;
    }

    final done = await onboardedFuture;
    if (!mounted) return;
    setState(() {
      _onboarded = done;
      _bootDone = true;
      _preloadProgress = 1;
      _preloadStatus = 'Ready';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_bootDone) {
      return StartupSplash(
        progress: _preloadProgress,
        status: _preloadStatus,
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
    // Keep Discover too so enter animation / cat state survive tab switches.
    if (i == 0 || i == 1 || i == 3) {
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
      final notifier = ref.read(gameProvider.notifier);
      final now = DateTime.now().millisecondsSinceEpoch;
      final last = ref.read(gameProvider).lastPlayedAtMs;
      notifier.catchUpGameDays(nowMs: now, fromMs: last);
      notifier.catchUpOnlineSales(nowMs: now, fromMs: last);
      notifier.catchUpGrading();
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
              showPackTheaterV2(context, ref, alreadyOpened: true).whenComplete(() {
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

      final resume = next.engagement.pendingResumeMessage;
      if (resume != null &&
          resume != prev?.engagement.pendingResumeMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resume)),
          );
          await ref.read(gameProvider.notifier).clearResumeMessage();
        });
      }

      final pending = next.engagement.pendingAchievementIds;
      if (pending.isNotEmpty &&
          pending != prev?.engagement.pendingAchievementIds) {
        final id = pending.first;
        final def = achievementById(id);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await BindoraHaptics.success();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                def == null
                    ? 'Achievement unlocked!'
                    : 'Achievement: ${def.title}',
              ),
              action: SnackBarAction(
                label: 'View',
                onPressed: () => openEngagementHub(context),
              ),
            ),
          );
          await ref.read(gameProvider.notifier).clearPendingAchievements();
        });
      }
    });

    final ready = ref.watch(gameProvider.select((s) => s.ready));
    if (ready && !_lastRipPrompted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptLastRip());
    }

    // Active + keep-alive tabs (0 Discover, 1 Collection, 3 Instapacks).
    final toShow = <int>{_index, ..._kept.keys};
    if (_index == 0 || _index == 1 || _index == 3) {
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
      bottomNavigationBar: HomeBottomNav(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
