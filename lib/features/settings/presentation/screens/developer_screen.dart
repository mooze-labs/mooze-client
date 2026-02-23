import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';
import 'package:mooze_mobile/services/providers/app_logger_provider.dart';
import 'package:mooze_mobile/shared/infra/breez/providers.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/developer_info_card.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/developer_action_grid.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/logs_viewer_screen.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/transaction_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/refund/refund_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/screens/refund/get_refund_screen.dart';
import 'package:mooze_mobile/shared/infra/sync/wallet_data_manager.dart';

enum ExportMethod { email, share }

/// Developer tools screen with debugging and diagnostic features
class DeveloperScreen extends ConsumerStatefulWidget {
  const DeveloperScreen({super.key});

  @override
  ConsumerState<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends ConsumerState<DeveloperScreen> {
  // Screen state
  String _appVersion = 'Loading...';
  String _buildNumber = '';
  bool _isLoading = false;

  // SDK/Wallet information
  String _sdkVersion = 'N/A';
  String _walletBalance = '0';
  String _pendingBalance = '0';
  int _totalLogs = 0;
  int _dbLogs = 0;
  String _logRetention = 'N/A';

  // Logger instance and stream subscription
  late final AppLoggerService _logger;
  StreamSubscription<LogEntry>? _logStreamSubscription;
  Timer? _dbStatsDebounceTimer;

  @override
  void initState() {
    super.initState();

    // Initialize logger once in initState to avoid accessing ref after dispose
    _logger = ref.read(appLoggerProvider);

    // Load data after frame is built to avoid blocking navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAppInfo();
        _updateLogCount();

        // Load heavy operations with a slight delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _loadWalletInfo();
            _updateDbLogStats();
          }
        });
      }
    });

    // Listen to log changes with proper subscription management
    _logStreamSubscription = _logger.logStream.listen((_) {
      if (mounted) {
        _updateLogCount();

        // Debounce DB stats update to avoid too many queries
        _dbStatsDebounceTimer?.cancel();
        _dbStatsDebounceTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            _updateDbLogStats();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // Cancel stream subscription to prevent memory leaks
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

    try {
      final breezClientResult = await ref.read(breezClientProvider.future);

      if (!mounted) return;

      await breezClientResult.fold(
        (error) async {
          _logger.warning(
            'DeveloperScreen',
            'Breez client not available: $error',
          );
          if (mounted) {
            setState(() {
              _sdkVersion = 'SDK not connected';
              _walletBalance = 'N/A';
              _pendingBalance = 'N/A';
            });
          }
        },
        (breezSdk) async {
          try {
            final info = await breezSdk.getInfo();

            if (mounted) {
              setState(() {
                _sdkVersion =
                    'Breez SDK Liquid ${info.blockchainInfo.liquidTip}';
                _walletBalance = info.walletInfo.balanceSat.toString();
                _pendingBalance =
                    (info.walletInfo.pendingReceiveSat +
                            info.walletInfo.pendingSendSat)
                        .toString();
              });
            }

            _logger.info('DeveloperScreen', 'Wallet info loaded successfully');
          } catch (e) {
            _logger.error(
              'DeveloperScreen',
              'Error getting wallet info',
              error: e,
            );
            if (mounted) {
              setState(() {
                _sdkVersion = 'Error loading SDK';
                _walletBalance = 'N/A';
                _pendingBalance = 'N/A';
              });
            }
          }
        },
      );
    } catch (e) {
      _logger.error('DeveloperScreen', 'Error loading wallet info', error: e);
      if (mounted) {
        setState(() {
          _sdkVersion = 'Error';
          _walletBalance = 'N/A';
          _pendingBalance = 'N/A';
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
          _logRetention = '${_logger.config.retentionDays} dias';
        });
      }
    } catch (e) {
      _logger.error('DeveloperScreen', 'Error loading DB log stats', error: e);
      if (mounted) {
        setState(() {
          _dbLogs = 0;
          _logRetention = 'N/A';
        });
      }
    }
  }

  Future<void> _syncWallet() async {
    _setLoading(true);
    _logger.info('DeveloperScreen', 'Starting light wallet sync...');

    try {
      final walletDataManager = ref.read(walletDataManagerProvider.notifier);
      await walletDataManager.lightSync();

      // Wait a bit to allow the state to propagate
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _showSuccessMessage('Light sync completed!');
        await _loadWalletInfo();
        _logger.info('DeveloperScreen', 'Light sync completed successfully');
      }
    } catch (e, stackTrace) {
      _logger.error(
        'DeveloperScreen',
        'Failed to light sync wallet',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showErrorMessage('Failed to light sync: $e');
      }
    } finally {
      if (mounted) {
        _setLoading(false);
      }
    }
  }

  Future<void> _fullSyncWallet() async {
    _setLoading(true);
    _logger.info('DeveloperScreen', 'Starting FULL wallet sync...');

    try {
      final walletDataManager = ref.read(walletDataManagerProvider.notifier);
      await walletDataManager.fullSyncWalletData();

      // Wait a bit to allow the state to propagate
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _showSuccessMessage('Full sync completed!');
        await _loadWalletInfo();
        _logger.info('DeveloperScreen', 'Full sync completed successfully');
      }
    } catch (e, stackTrace) {
      _logger.error(
        'DeveloperScreen',
        'Failed to full sync wallet',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showErrorMessage('Failed to full sync: $e');
      }
    } finally {
      if (mounted) {
        _setLoading(false);
      }
    }
  }

  Future<void> _rescanSwaps() async {
    _setLoading(true);
    _logger.info('DeveloperScreen', 'Starting onchain swaps rescan...');

    try {
      final breezClientResult = await ref.read(breezClientProvider.future);

      await breezClientResult.fold(
        (error) async {
          throw Exception('Breez client not available: $error');
        },
        (breezSdk) async {
          await breezSdk.rescanOnchainSwaps();

          // Check if still mounted before invalidating providers
          if (!mounted) return;

          // Invalidate providers to force refresh
          _invalidateWalletProviders();

          // Check for refundable swaps
          await _checkRefundables(breezSdk);

          if (mounted) {
            _showSuccessMessage('Onchain swaps rescanned successfully!');
            _logger.info(
              'DeveloperScreen',
              'Onchain swaps rescanned successfully',
            );
          }
        },
      );
    } catch (e, stackTrace) {
      _logger.error(
        'DeveloperScreen',
        'Failed to rescan swaps',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showErrorMessage('Failed to rescan swaps: $e');
      }
    } finally {
      if (mounted) {
        _setLoading(false);
      }
    }
  }

  /// Invalidates wallet-related providers to force data refresh
  void _invalidateWalletProviders() {
    _logger.info('DeveloperScreen', 'Invalidating wallet providers...');

    // Invalidate balance providers
    ref.invalidate(balanceControllerProvider);
    ref.invalidate(balanceCacheProvider);

    // Invalidate transaction providers
    ref.invalidate(transactionControllerProvider);
    ref.invalidate(transactionHistoryProvider);
    ref.invalidate(transactionHistoryCacheProvider);

    // Invalidate refund provider
    ref.invalidate(refundProvider);

    _logger.info('DeveloperScreen', 'Wallet providers invalidated');
  }

  /// Checks for refundable swaps and navigates to refund screen if any exist
  Future<void> _checkRefundables(dynamic breezSdk) async {
    try {
      final refundables = await breezSdk.listRefundables();

      _logger.info(
        'DeveloperScreen',
        'Found ${refundables.length} refundable swap(s)',
      );

      if (refundables.isNotEmpty && mounted) {
        // Show dialog asking if user wants to view refundables
        final shouldNavigate = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Text('Refundables Found'),
                  ],
                ),
                content: Text(
                  'Found ${refundables.length} pending transaction(s) that can be refunded.\n\n'
                  'Would you like to view them now?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Later'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('View Now'),
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
    // Show dialog to choose export method
    final exportMethod = await _showExportLogsDialog();

    if (exportMethod == null) return; // User cancelled

    _setLoading(true);
    _logger.info('DeveloperScreen', 'Exporting logs...');

    try {
      final zipPath = await _logger.exportLogs();

      if (mounted) {
        if (exportMethod == ExportMethod.email) {
          // Send via email
          await _sendLogsViaEmail(zipPath);
        } else {
          // Share/Save file
          await _shareLogsFile(zipPath);
        }

        _logger.info('DeveloperScreen', 'Logs exported successfully: $zipPath');
      }
    } catch (e, stackTrace) {
      _logger.error(
        'DeveloperScreen',
        'Failed to export logs',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showErrorMessage('Failed to export logs: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<ExportMethod?> _showExportLogsDialog() async {
    return await showDialog<ExportMethod>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFF1C1C1C),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryColor.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.file_download,
                    size: 40,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Exportar Logs',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Os logs do aplicativo ajudam nossa equipe a resolver problemas. Como você gostaria de compartilhar?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Enviar por E-mail',
                  onPressed: () {
                    Navigator.of(context).pop(ExportMethod.email);
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop(ExportMethod.share);
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: BorderSide(color: Colors.grey[700]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Salvar/Compartilhar',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Future<void> _sendLogsViaEmail(String zipPath) async {
  //   try {
  //     // Verifica se o arquivo existe
  //     final file = File(zipPath);
  //     if (!await file.exists()) {
  //       throw Exception('Arquivo ZIP não encontrado: $zipPath');
  //     }

  //     // Verifica se o arquivo tem conteúdo
  //     final fileSize = await file.length();
  //     if (fileSize == 0) {
  //       throw Exception('Arquivo ZIP está vazio');
  //     }

  //     _logger.info(
  //       'DeveloperScreen',
  //       'Sharing ZIP file: $zipPath (${fileSize} bytes)',
  //     );

  //     // Create mailto URI
  //     final Uri emailUri = Uri(
  //       scheme: 'mailto',
  //       path: 'suporte@mooze.app',
  //       query: Uri.encodeQueryComponent(
  //         'subject=Logs do App Mooze&body=Segue em anexo os logs do aplicativo.\n\nDescreva aqui o problema que você está enfrentando:',
  //       ).replaceAll('+', '%20'),
  //     );

  //     // Try to launch email app
  //     if (await canLaunchUrl(emailUri)) {
  //       await launchUrl(emailUri);
  //     }

  //     // Share the file with email apps using new API
  //     final ShareParams shareParams = ShareParams(
  //       title: 'Logs do App Mooze',
  //       subject: 'Logs do App Mooze',
  //       files: <XFile>[XFile(zipPath)],
  //     );
  //     await SharePlus.instance.share(shareParams);

  //     _showSuccessMessage('Arquivo pronto para enviar por e-mail!');
  //   } catch (e) {
  //     _logger.error(
  //       'DeveloperScreen',
  //       'Failed to share logs via email',
  //       error: e,
  //     );
  //     _showErrorMessage('Erro ao compartilhar logs: $e');
  //   }
  // }

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
        'Sharing ZIP file: $zipPath (${fileSize} bytes)',
      );

      // Create email with attachment
      final Email email = Email(
        recipients: ['suporte@mooze.app'],
        subject: 'Logs do App Mooze',
        body:
            'Segue em anexo os logs do aplicativo.\n\nDescreva aqui o problema que você está enfrentando:',
        attachmentPaths: [zipPath],
        isHTML: false,
      );

      // Send email
      await FlutterEmailSender.send(email);

      _showSuccessMessage('Email pronto para envio!');
    } catch (e) {
      _logger.error(
        'DeveloperScreen',
        'Failed to share logs via email',
        error: e,
      );
      _showErrorMessage('Erro ao compartilhar logs: $e');
    }
  }

  Future<void> _shareLogsFile(String zipPath) async {
    try {
      // Verifica se o arquivo existe
      final file = File(zipPath);
      if (!await file.exists()) {
        throw Exception('Arquivo ZIP não encontrado: $zipPath');
      }

      // Verifica se o arquivo tem conteúdo
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Arquivo ZIP está vazio');
      }

      _logger.info(
        'DeveloperScreen',
        'Sharing ZIP file: $zipPath (${fileSize} bytes)',
      );

      // Share using new API
      final ShareParams shareParams = ShareParams(
        title: 'Logs do App Mooze',
        subject: 'Logs do App Mooze',
        files: <XFile>[XFile(zipPath)],
      );
      await SharePlus.instance.share(shareParams);

      _showSuccessMessage('Logs compartilhados com sucesso!');
    } catch (e) {
      _logger.error('DeveloperScreen', 'Failed to share logs', error: e);
      _showErrorMessage('Erro ao compartilhar logs: $e');
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
    final clearOption = await _showClearLogsDialog();

    if (clearOption == null) return; // User cancelled

    _setLoading(true);
    try {
      switch (clearOption) {
        case 'memory':
          _logger.clearLogs();
          _showSuccessMessage('Logs da memória limpos com sucesso!');
          _logger.info('DeveloperScreen', 'Memory logs cleared');
          break;
        case 'database':
          await _logger.clearDatabaseLogs();
          _showSuccessMessage('Logs do banco limpos com sucesso!');
          _logger.info('DeveloperScreen', 'Database logs cleared');
          break;
        case 'all':
          _logger.clearLogs();
          await _logger.clearLogFiles();
          await _logger.clearDatabaseLogs();
          _showSuccessMessage('Todos os logs limpos com sucesso!');
          _logger.info('DeveloperScreen', 'All logs cleared');
          break;
      }
      _updateLogCount();
      await _updateDbLogStats();
    } catch (e) {
      _logger.error('DeveloperScreen', 'Error clearing logs', error: e);
      _showErrorMessage('Erro ao limpar logs: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> _showClearLogsDialog() async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFF1C1C1C),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.delete_sweep,
                    size: 40,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Limpar Logs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Escolha o que deseja limpar:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
                const SizedBox(height: 24),
                _buildClearOption(
                  context,
                  'Memória',
                  'Limpar apenas logs em memória ($_totalLogs logs)',
                  Icons.memory,
                  'memory',
                ),
                const SizedBox(height: 12),
                _buildClearOption(
                  context,
                  'Banco de Dados',
                  'Limpar apenas logs do banco ($_dbLogs logs)',
                  Icons.storage,
                  'database',
                ),
                const SizedBox(height: 12),
                _buildClearOption(
                  context,
                  'Todos',
                  'Limpar memória, arquivos e banco',
                  Icons.delete_forever,
                  'all',
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClearOption(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    String value,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _copyDebugInfo() async {
    final debugInfo = '''
Mooze App - Debug Info
======================
App Version: $_appVersion
Build Number: $_buildNumber
SDK Version: $_sdkVersion
Wallet Balance: $_walletBalance sats
Pending Balance: $_pendingBalance sats
Total Logs (Memory): $_totalLogs
Total Logs (Database): $_dbLogs
Log Retention: $_logRetention
Generated: ${DateTime.now().toIso8601String()}
''';

    await Clipboard.setData(ClipboardData(text: debugInfo));
    _showSuccessMessage('Debug information copied!');
    _logger.info('DeveloperScreen', 'Debug info copied to clipboard');
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() => _isLoading = loading);
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Copiar infos de sistema'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            tooltip: 'Copy debug info',
            onPressed: _copyDebugInfo,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryColor,
                  ),
                ),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DeveloperInfoCard(
                        appVersion: _appVersion,
                        buildNumber: _buildNumber,
                        sdkVersion: _sdkVersion,
                        walletBalance: _walletBalance,
                        pendingBalance: _pendingBalance,
                        totalLogs: _totalLogs,
                        dbLogs: _dbLogs,
                        logRetention: _logRetention,
                        onViewLogs: _viewLogs,
                      ),
                      const SizedBox(height: 20),
                      DeveloperActionGrid(
                        isLoading: _isLoading,
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
    );
  }
}
