import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';
import 'package:mooze_mobile/providers/wallet/wallet_sync_provider.dart';
import 'package:mooze_mobile/screens/pin/verify_pin.dart';
import 'package:mooze_mobile/services/auth.dart';
import 'package:mooze_mobile/utils/store_mode.dart';

class LifecycleManager extends ConsumerStatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const LifecycleManager({
    Key? key,
    required this.child,
    required this.navigatorKey,
  }) : super(key: key);

  @override
  ConsumerState<LifecycleManager> createState() => _LifecycleManagerState();
}

class _LifecycleManagerState extends ConsumerState<LifecycleManager>
    with WidgetsBindingObserver {
  final AuthenticationService _authService = AuthenticationService();
  final StoreModeHandler _storeModeHandler = StoreModeHandler();
  bool _needsVerification = false;
  bool _isLocked = false;
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("App lifecycle state changed to: $state");

    final syncService = ref.read(walletSyncServiceProvider.notifier);
    final sideswap = ref.read(sideswapRepositoryProvider);

    switch (state) {
      case AppLifecycleState.resumed:
        syncService.startPeriodicSync();
        syncService.syncNow();
        _isRunning = true;

        sideswap.ensureConnection();

        _checkAuthStatus();
        break;

      case AppLifecycleState.inactive:
        break;

      case AppLifecycleState.paused:
        // _invalidateSessionIfNeeded();
        _isRunning = false;
        sideswap.stopQuotes();
        break;

      case AppLifecycleState.detached:
        syncService.stopPeriodicSync();
        sideswap.stopQuotes();
        _isRunning = false;
        break;

      default:
        break;
    }
  }

  Future<void> _invalidateSessionIfNeeded() async {
    bool isStoreMode = await _storeModeHandler.isStoreMode();

    if (isStoreMode) {
      _needsVerification = false;
      return;
    }

    await _authService.invalidateSession();
    _needsVerification = true;
  }

  Future<void> _checkAuthStatus() async {
    if (_isLocked) return;
    if (_isRunning) return;

    bool isStoreMode = await _storeModeHandler.isStoreMode();
    if (isStoreMode) {
      return;
    }

    bool hasValidSession = await _authService.hasValidSession();
    if (hasValidSession) {
      return;
    }

    if (!mounted) return;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == '/verify_pin') {
      return;
    }

    setState(() => _isLocked = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.navigatorKey.currentState?.push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder:
              (context) => PopScope(
                canPop: false,
                child: VerifyPinScreen(
                  onPinConfirmed: () {
                    setState(() {
                      _needsVerification = false;
                      _isLocked = false;
                    });
                    widget.navigatorKey.currentState?.pop();
                  },
                  isAppResuming: true,
                ),
              ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
