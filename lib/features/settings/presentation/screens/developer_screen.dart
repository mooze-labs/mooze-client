import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/settings/domain/entities/export_method.dart';
import 'package:mooze_mobile/shared/widgets/app_snackbar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/services/debug_header.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/developer/developer_info_card.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/developer/sdk_versions.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/developer/developer_action_grid.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/developer/balance_overview_card.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/developer/sync_progress_card.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/export_logs_dialog.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/clear_logs_dialog.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/logs_viewer_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/transaction_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_id_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/refund/refund_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/refund/get_refund_screen.dart';
import 'package:mooze_mobile/app/di/v2_providers.dart';
import 'package:mooze_mobile/domain/entities/balance.dart';
import 'package:mooze_mobile/domain/entities/transaction.dart';
import 'package:mooze_mobile/features/sync/domain/sync_strategy.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

class DeveloperScreen extends ConsumerStatefulWidget {
  const DeveloperScreen({super.key});

  @override
  ConsumerState<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends ConsumerState<DeveloperScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Screen state
  String _appVersion = 'Loading…';
  String _buildNumber = '';

  DeveloperOperation? _activeOperation;

  int? _bitcoinTip;
  Balance? _balance;
  bool _refreshingBalance = false;
  int _totalLogs = 0;
  int _dbLogs = 0;
  int _retentionDays = -1;

  // Logger instance and stream subscription
  late final AppLoggerService _logger;
  StreamSubscription<LogEntry>? _logStreamSubscription;
  Timer? _dbStatsDebounceTimer;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _entryController.forward();

    // Initialize logger once in initState to avoid accessing ref after dispose
    _logger = ref.read(appLoggerProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadAppInfo();
      _updateLogCount();

      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        _loadWalletInfo();
        _updateDbLogStats();
      });
    });

    _logStreamSubscription = _logger.logStream.listen((_) {
      if (!mounted) return;
      _updateLogCount();
      _dbStatsDebounceTimer?.cancel();
      _dbStatsDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) _updateDbLogStats();
      });
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _logStreamSubscription?.cancel();
    _dbStatsDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAppInfo() async {
    if (!mounted) return;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
        });
      }
      _logger.info(
        'DeveloperScreen',
        'App info loaded: $_appVersion ($_buildNumber)',
      );
    } catch (e) {
      _logger.error('DeveloperScreen', 'Error loading app info', error: e);
      if (mounted) {
        setState(() {
          _appVersion = 'Error';
          _buildNumber = 'N/A';
        });
      }
    }
  }

  Future<void> _loadWalletInfo() async {
    if (!mounted) return;
    setState(() => _refreshingBalance = true);

    try {
      final repo = await ref.read(walletRepositoryProvider.future);
      if (!mounted) return;

      final balanceResult = await repo.aggregateBalance();
      final btcTipResult = await repo.getCurrentBitcoinBlockHeight();
      if (!mounted) return;

      final balance = balanceResult.getOrElse((_) => Balance.empty());
      final btcTip = btcTipResult.getOrElse((_) => 0);

      setState(() {
        _bitcoinTip = btcTip;
        _balance = balance;
        _refreshingBalance = false;
      });

      _logger.info('DeveloperScreen', 'Wallet info loaded successfully');
    } catch (e) {
      _logger.error('DeveloperScreen', 'Error loading wallet info', error: e);
      if (mounted) {
        setState(() {
          _bitcoinTip = null;
          _refreshingBalance = false;
        });
      }
    }
  }

  void _updateLogCount() {
    if (mounted) {
      setState(() {
        _totalLogs = _logger.logs.length;
      });
    }
  }

  Future<void> _updateDbLogStats() async {
    if (!mounted) return;
    try {
      final stats = await _logger.getDatabaseStats();
      if (mounted) {
        setState(() {
          _dbLogs = stats['total'] ?? 0;
          _retentionDays = _logger.config.retentionDays;
        });
      }
    } catch (e) {
      _logger.error('DeveloperScreen', 'Error loading DB log stats', error: e);
      if (mounted) {
        setState(() {
          _dbLogs = 0;
          _retentionDays = -1;
        });
      }
    }
  }

  Future<void> _runSync({
    required DeveloperOperation operation,
    required SyncStrategy strategy,
    required String successMessage,
    required String Function(String) errorBuilder,
    Future<void> Function()? onComplete,
  }) async {
    _setOperation(operation);
    _logger.info(
      'DeveloperScreen',
      'Starting ${strategy.name} sync (${operation.name})…',
    );

    try {
      final refreshUseCase = await ref.read(refreshWalletProvider.future);
      final result = await refreshUseCase(strategy: strategy);

      await result.match(
        (failure) async => throw Exception(failure.toString()),
        (_) async {},
      );

      if (!mounted) return;
      _showSuccessMessage(successMessage);
      await _loadWalletInfo();
      await onComplete?.call();
      _logger.info('DeveloperScreen', '${operation.name} completed');
    } catch (e, stackTrace) {
      _logger.error(
        'DeveloperScreen',
        '${operation.name} failed',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) _showErrorMessage(errorBuilder(e.toString()));
    } finally {
      if (mounted) _setOperation(null);
    }
  }

  Future<void> _syncWallet() {
    final t = AppLocalizations.of(context);
    return _runSync(
      operation: DeveloperOperation.lightSync,
      strategy: SyncStrategy.light,
      successMessage: t.developer_sync_light_success,
      errorBuilder: t.developer_sync_light_error,
    );
  }

  Future<void> _fullSyncWallet() {
    final t = AppLocalizations.of(context);
    return _runSync(
      operation: DeveloperOperation.fullSync,
      strategy: SyncStrategy.full,
      successMessage: t.developer_sync_full_success,
      errorBuilder: t.developer_sync_full_error,
    );
  }

  Future<void> _rescanSwaps() {
    final t = AppLocalizations.of(context);
    return _runSync(
      operation: DeveloperOperation.rescan,
      strategy: SyncStrategy.full,
      successMessage: t.developer_rescan_success,
      errorBuilder: t.developer_rescan_error,
      onComplete: () async {
        if (!mounted) return;
        _invalidateWalletProviders();
        await _checkRefundables();
      },
    );
  }

  /// Invalidates wallet-related providers to force data refresh
  void _invalidateWalletProviders() {
    _logger.info('DeveloperScreen', 'Invalidating wallet providers…');
    ref.invalidate(balanceControllerProvider);
    ref.invalidate(balanceCacheProvider);
    ref.invalidate(transactionControllerProvider);
    ref.invalidate(transactionHistoryProvider);
    ref.invalidate(transactionHistoryCacheProvider);
    ref.invalidate(refundProvider);
    _logger.info('DeveloperScreen', 'Wallet providers invalidated');
  }

  /// Checks for refundable swaps and navigates to refund screen if any exist
  Future<void> _checkRefundables() async {
    try {
      final repo = await ref.read(walletRepositoryProvider.future);
      final result = await repo.listRefundableSwaps();
      final refundables = result.getOrElse((_) => const []);

      _logger.info(
        'DeveloperScreen',
        'Found ${refundables.length} refundable swap(s)',
      );

      if (refundables.isNotEmpty && mounted) {
        final t = AppLocalizations.of(context);
        final shouldNavigate = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(t.developer_refundables_title),
                  ],
                ),
                content: Text(
                  t.developer_refundables_message(refundables.length),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(t.developer_later),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(t.developer_view_now),
                  ),
                ],
              ),
        );

        if (shouldNavigate == true && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GetRefundScreen()),
          );
        }
      }
    } catch (e) {
      _logger.error('DeveloperScreen', 'Error checking refundables', error: e);
    }
  }

  Future<void> _exportLogs() async {
    final exportMethod = await ExportLogsDialog.show(context);
    if (exportMethod == null) return;

    _setOperation(DeveloperOperation.exportLogs);
    _logger.info('DeveloperScreen', 'Exporting logs…');

    try {
      final walletId = await ref.read(walletIdProvider.future);
      final userId = await _resolveUserId();
      final txStore = await ref.read(transactionStoreProvider.future);
      final txResult = await txStore.list();
      final v2Txs = txResult.fold((failure) {
        _logger.warning(
          'DeveloperScreen',
          'V2 transaction store unavailable for export: ${failure.message}',
        );
        return const <Transaction>[];
      }, (list) => list);

      final zipPath = await _logger.exportLogs(
        walletId: walletId,
        v2Transactions: v2Txs,
        debugHeader: _buildDebugHeader(userId: userId, walletId: walletId),
      );

      if (!mounted) return;
      if (exportMethod == ExportMethod.email) {
        await _sendLogsViaEmail(zipPath);
      } else {
        await _shareLogsFile(zipPath);
      }
      _logger.info('DeveloperScreen', 'Logs exported successfully: $zipPath');
    } catch (e, stackTrace) {
      _logger.error(
        'DeveloperScreen',
        'Failed to export logs',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showErrorMessage(
          AppLocalizations.of(context).developer_export_error(e.toString()),
        );
      }
    } finally {
      if (mounted) _setOperation(null);
    }
  }

  Future<void> _sendLogsViaEmail(String zipPath) async {
    try {
      final file = File(zipPath);
      if (!await file.exists()) {
        throw Exception('Arquivo ZIP não encontrado: $zipPath');
      }
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Arquivo ZIP está vazio');
      }
      _logger.info(
        'DeveloperScreen',
        'Sharing ZIP file: $zipPath ($fileSize bytes)',
      );

      final Email email = Email(
        recipients: ['suporte@mooze.app'],
        subject: 'Logs do App Mooze',
        body:
            'Segue em anexo os logs do aplicativo.\n\nDescreva aqui o problema que você está enfrentando:',
        attachmentPaths: [zipPath],
        isHTML: false,
      );
      await FlutterEmailSender.send(email);

      if (mounted) {
        _showSuccessMessage(AppLocalizations.of(context).developer_email_ready);
      }
    } catch (e) {
      _logger.error(
        'DeveloperScreen',
        'Failed to share logs via email',
        error: e,
      );
      if (mounted) {
        _showErrorMessage(
          AppLocalizations.of(context).developer_share_logs_error(e.toString()),
        );
      }
    }
  }

  Future<void> _shareLogsFile(String zipPath) async {
    try {
      final file = File(zipPath);
      if (!await file.exists()) {
        throw Exception('Arquivo ZIP não encontrado: $zipPath');
      }
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Arquivo ZIP está vazio');
      }

      _logger.info(
        'DeveloperScreen',
        'Sharing ZIP file: $zipPath ($fileSize bytes)',
      );
      final ShareParams shareParams = ShareParams(
        title: 'Logs do App Mooze',
        subject: 'Logs do App Mooze',
        files: <XFile>[XFile(zipPath)],
      );
      await SharePlus.instance.share(shareParams);

      if (mounted) {
        _showSuccessMessage(
          AppLocalizations.of(context).developer_share_logs_success,
        );
      }
    } catch (e) {
      _logger.error('DeveloperScreen', 'Failed to share logs', error: e);
      if (mounted) {
        _showErrorMessage(
          AppLocalizations.of(context).developer_share_logs_error(e.toString()),
        );
      }
    }
  }

  Future<void> _viewLogs() async {
    _logger.info('DeveloperScreen', 'Opening logs viewer');
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LogsViewerScreen(logger: _logger),
        ),
      );
    }
  }

  Future<void> _onRefund() async {
    context.push('/transactions/refund');
  }

  Future<void> _clearLogs() async {
    final clearOption = await ClearLogsDialog.show(
      context,
      totalLogs: _totalLogs,
      dbLogs: _dbLogs,
    );
    if (clearOption == null) return;
    if (!mounted) return;

    _setOperation(DeveloperOperation.clearLogs);
    final t = AppLocalizations.of(context);
    try {
      switch (clearOption) {
        case 'memory':
          _logger.clearLogs();
          _showSuccessMessage(t.developer_clear_memory_success);
          _logger.info('DeveloperScreen', 'Memory logs cleared');
          break;
        case 'database':
          await _logger.clearDatabaseLogs();
          _showSuccessMessage(t.developer_clear_db_success);
          _logger.info('DeveloperScreen', 'Database logs cleared');
          break;
        case 'all':
          _logger.clearLogs();
          await _logger.clearLogFiles();
          await _logger.clearDatabaseLogs();
          _showSuccessMessage(t.developer_clear_all_success);
          _logger.info('DeveloperScreen', 'All logs cleared');
          break;
      }
      _updateLogCount();
      await _updateDbLogStats();
    } catch (e) {
      _logger.error('DeveloperScreen', 'Error clearing logs', error: e);
      _showErrorMessage(t.developer_clear_error(e.toString()));
    } finally {
      if (mounted) _setOperation(null);
    }
  }

  DebugHeader _buildDebugHeader({String? userId, String? walletId}) {
    final btcEquivalentSats =
        _balance == null
            ? 0
            : _balance!.assets.fold<int>(0, (sum, a) => sum + a.amountSat);
    final sdkVersions =
        ref.read(sdkVersionsProvider).valueOrNull ?? SdkVersions.unavailable;

    return DebugHeader(
      appVersion: _appVersion,
      buildNumber: _buildNumber,
      lwkVersion: sdkVersions.lwk,
      bdkVersion: sdkVersions.bdk,
      breezVersion: sdkVersions.breez,
      bitcoinTip: _bitcoinTip,
      totalSats: btcEquivalentSats,
      totalLogsMemory: _totalLogs,
      totalLogsDatabase: _dbLogs,
      logRetentionDays: _retentionDays,
      userId: userId,
      walletId: walletId,
    );
  }

  /// Best-effort fetch of the backend-issued user id. Returns null on
  /// any error (no auth session, network down, decode failure) so the
  /// export can still proceed with `userId: null` and the header just
  /// renders "unavailable" — support tooling falls back to walletId.
  Future<String?> _resolveUserId() async {
    try {
      final userService = ref.read(userServiceProvider);
      final result = await userService.getUser().run();
      return result.fold((_) => null, (user) => user.id);
    } catch (e) {
      _logger.warning(
        'DeveloperScreen',
        'resolveUserId failed: $e — exporting with userId=null',
      );
      return null;
    }
  }

  Future<void> _copyDebugInfo() async {
    final userId = await _resolveUserId();
    final walletId = await ref.read(walletIdProvider.future);
    if (!mounted) return;
    await Clipboard.setData(
      ClipboardData(
        text: _buildDebugHeader(userId: userId, walletId: walletId).format(),
      ),
    );
    if (!mounted) return;
    _showSuccessMessage(AppLocalizations.of(context).developer_debug_copied);
    _logger.info('DeveloperScreen', 'Debug info copied to clipboard');
  }

  void _setOperation(DeveloperOperation? op) {
    if (mounted) setState(() => _activeOperation = op);
  }

  void _showSuccessMessage(String message) =>
      AppSnackBar.success(context, message);

  void _showErrorMessage(String message) => AppSnackBar.error(context, message);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final sdkVersions =
        ref.watch(sdkVersionsProvider).valueOrNull ?? SdkVersions.loading;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(t.developer_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: t.developer_copy_debug_tooltip,
            onPressed: _copyDebugInfo,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BalanceOverviewCard(
                  balance: _balance,
                  loading: _balance == null,
                  refreshing: _refreshingBalance,
                ),
                const SizedBox(height: 16),
                DeveloperInfoCard(
                  appVersion: _appVersion,
                  buildNumber: _buildNumber,
                  lwkVersion: sdkVersions.lwk,
                  bdkVersion: sdkVersions.bdk,
                  breezVersion: sdkVersions.breez,
                  bitcoinTip: _bitcoinTip,
                  totalLogs: _totalLogs,
                  dbLogs: _dbLogs,
                  logRetention:
                      _retentionDays >= 0
                          ? t.developer_log_retention_days(_retentionDays)
                          : 'N/A',
                  onViewLogs: _viewLogs,
                ),
                const SizedBox(height: 16),
                AnimatedSize(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child:
                      _activeOperation == null
                          ? const SizedBox.shrink()
                          : Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: SyncProgressCard(
                              operation: _activeOperation!,
                            ),
                          ),
                ),
                DeveloperActionGrid(
                  activeOperation: _activeOperation,
                  onSync: _syncWallet,
                  onFullSync: _fullSyncWallet,
                  onRescan: _rescanSwaps,
                  onViewLogs: _viewLogs,
                  onExportLogs: _exportLogs,
                  onClearLogs: _clearLogs,
                  onRefund: _onRefund,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
