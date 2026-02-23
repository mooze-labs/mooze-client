import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/infra/boot/boot_orchestrator.dart';
import 'package:mooze_mobile/shared/infra/sync/wallet_data_manager.dart';
import 'package:mooze_mobile/shared/infra/sync/sync_event_stream.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/transaction_monitor_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/balance_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/cached_data_provider.dart';
import 'package:mooze_mobile/features/wallet/di/providers/wallet_repository_provider.dart';
import 'package:mooze_mobile/shared/infra/breez/providers.dart';
import 'package:mooze_mobile/shared/infra/lwk/utils/cache_manager.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'dart:math' as math;

class ImportMessage {
  final String text;
  final bool isCompleted;
  final bool hasError;

  const ImportMessage({
    required this.text,
    this.isCompleted = false,
    this.hasError = false,
  });
}

class WalletImportLoadingScreen extends ConsumerStatefulWidget {
  const WalletImportLoadingScreen({super.key});

  @override
  ConsumerState<WalletImportLoadingScreen> createState() =>
      _WalletImportLoadingScreenState();
}

class _WalletImportLoadingScreenState
    extends ConsumerState<WalletImportLoadingScreen>
    with TickerProviderStateMixin {
  final List<ImportMessage> _messages = [];
  int _currentMessageIndex = -1;
  bool _isCompleted = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasInitialized = false;
  bool _isHandlingSuccess = false;

  final _requiredDatasources = {'liquid', 'bdk', 'breez'};
  final _completedDatasources = <String>{};
  bool _allSyncsCompleted = false;
  StreamSubscription<SyncEvent>? _syncEventSubscription;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _checkBounceController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _orbitalController;
  late AnimationController _progressController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _checkBounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _orbitalController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _progressController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startImportProcess();
    });
  }

  @override
  void dispose() {
    _syncEventSubscription?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _checkBounceController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _orbitalController.dispose();
    _progressController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _listenToSyncEvents() {
    final controller = ref.read(syncEventControllerProvider);

    final alreadyCompleted = controller.completedDatasources;

    if (alreadyCompleted.isNotEmpty) {
      for (final datasource in alreadyCompleted) {
        if (_requiredDatasources.contains(datasource)) {
          _completedDatasources.add(datasource);
        }
      }

      if (_completedDatasources.containsAll(_requiredDatasources)) {
        _allSyncsCompleted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _handleAllSyncsCompleted();
          }
        });
      }
    }

    _syncEventSubscription = controller.stream.listen((event) {
      if (event.isCompleted) {
        if (!_completedDatasources.contains(event.datasource)) {
          _completedDatasources.add(event.datasource);

          _showMessage(
            '${_getDatasourceName(event.datasource)} sincronizado ✓',
          ).then((_) {
            if (_completedDatasources.containsAll(_requiredDatasources)) {
              _allSyncsCompleted = true;
              _handleAllSyncsCompleted();
            }
          });
        }
      } else if (event.isFailed) {
        if (!_completedDatasources.contains(event.datasource)) {
          _completedDatasources.add(event.datasource);
          _showMessage(
            '${_getDatasourceName(event.datasource)} - erro, continuando...',
          ).then((_) {
            if (_completedDatasources.containsAll(_requiredDatasources)) {
              _allSyncsCompleted = true;
              _handleAllSyncsCompleted();
            }
          });
        }
      }
    }, onError: (_) {});
  }

  String _getDatasourceName(String datasource) {
    switch (datasource) {
      case 'liquid':
        return 'Liquid Network';
      case 'bdk':
        return 'Bitcoin';
      case 'breez':
        return 'Lightning';
      default:
        return datasource;
    }
  }

  Future<void> _handleAllSyncsCompleted() async {
    if (_isCompleted || _isHandlingSuccess) return;

    setState(() => _isHandlingSuccess = true);

    await _showMessage('Carregando saldos...');

    await _refreshBalances();

    await _showMessage('Carregando transações...');
    await Future.delayed(const Duration(milliseconds: 500));

    final transactionMonitor = ref.read(transactionMonitorServiceProvider);
    await transactionMonitor.markExistingTransactionsAsKnown();

    await _showMessage('Importação concluída ✓', isCompleted: true);
    await _checkBounceController.forward();

    transactionMonitor.finishImporting();

    setState(() => _isCompleted = true);

    if (mounted) {
      context.go("/home");
    }
  }

  Future<void> _refreshBalances() async {
    try {
      ref.read(balanceCacheProvider.notifier).reset();
    } catch (_) {}

    try {
      final breezResult = await ref.read(breezClientProvider.future);
      breezResult.fold((error) {
        ref.invalidate(breezClientProvider);
      }, (client) {});
    } catch (_) {
      ref.invalidate(breezClientProvider);
    }

    await Future.delayed(const Duration(milliseconds: 500));

    ref.invalidate(walletRepositoryProvider);

    ref.invalidate(allBalancesProvider);

    final assetsToRefresh = [Asset.lbtc, Asset.btc, Asset.usdt, Asset.depix];
    for (final asset in assetsToRefresh) {
      ref.invalidate(balanceProvider(asset));
    }

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      await ref.read(allBalancesProvider.future);
    } catch (_) {}
  }

  Future<void> _startImportProcess() async {
    try {
      _progressController.forward();

      final transactionMonitor = ref.read(transactionMonitorServiceProvider);
      transactionMonitor.startImporting();

      await _showMessage('Processando...');

      await _showMessage('Verificando dados...');

      try {
        await LwkCacheManager.clearLwkDatabase();
      } catch (_) {}

      _completedDatasources.clear();
      _allSyncsCompleted = false;

      await _syncEventSubscription?.cancel();
      _syncEventSubscription = null;

      final syncController = ref.read(syncEventControllerProvider);
      syncController.reset();

      ref.invalidate(walletDataManagerProvider);

      try {
        ref.invalidate(bootOrchestratorProvider);
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 200));

      final freshWalletDataManager = ref.read(
        walletDataManagerProvider.notifier,
      );

      freshWalletDataManager.invalidateAllWalletProviders();

      _listenToSyncEvents();

      await _showMessage('Inicializando carteira...');
      setState(() => _hasInitialized = true);

      await freshWalletDataManager.initializeWallet(
        skipInitialSync: false,
        runSyncInBackground: true,
      );

      final alreadyCompleted = syncController.completedDatasources;

      if (alreadyCompleted.isNotEmpty) {
        for (final datasource in alreadyCompleted) {
          if (_requiredDatasources.contains(datasource) &&
              !_completedDatasources.contains(datasource)) {
            _completedDatasources.add(datasource);
            await _showMessage(
              '${_getDatasourceName(datasource)} sincronizado ✓',
            );
          }
        }

        if (_completedDatasources.containsAll(_requiredDatasources)) {
          _allSyncsCompleted = true;
          await _handleAllSyncsCompleted();
        }
      }
    } catch (e) {
      final errorMsg = _getErrorMessage(e);
      await _showMessage(errorMsg, hasError: true);
      setState(() {
        _hasError = true;
        _errorMessage = errorMsg;
      });
    }
  }

  Future<void> _showMessage(
    String text, {
    bool isCompleted = false,
    bool hasError = false,
  }) async {
    if (_currentMessageIndex >= 0 && _currentMessageIndex < _messages.length) {
      setState(() {
        _messages[_currentMessageIndex] = ImportMessage(
          text: _messages[_currentMessageIndex].text,
          isCompleted: true,
          hasError: _messages[_currentMessageIndex].hasError,
        );
      });
    }

    setState(() {
      _messages.add(
        ImportMessage(text: text, isCompleted: isCompleted, hasError: hasError),
      );
      _currentMessageIndex = _messages.length - 1;
    });

    _fadeController.reset();
    _slideController.reset();
    await Future.wait([_fadeController.forward(), _slideController.forward()]);
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('tentando reconectar') ||
        errorStr.contains('tentativas')) {
      return 'Tentando reconectar...';
    } else if (errorStr.contains('mnemonic')) {
      return 'Erro ao carregar dados';
    } else if (errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return 'Erro de conexão';
    } else if (errorStr.contains('datasource')) {
      return 'Erro ao conectar servidores';
    } else if (errorStr.contains('nenhum datasource')) {
      return 'Servidores indisponíveis';
    }

    return 'Erro na importação';
  }

  String _getUserFriendlyErrorMessage(String? errorMessage) {
    if (errorMessage == null) return 'Ocorreu um erro';

    final errorStr = errorMessage.toLowerCase();

    if (errorStr.contains('tentando reconectar') ||
        errorStr.contains('tentativas')) {
      final match = RegExp(r'\((\d+)/(\d+)\)').firstMatch(errorMessage);
      if (match != null) {
        return 'Reconectando (${match.group(1)}/${match.group(2)})';
      }
      return 'Tentando reconectar aos servidores...';
    } else if (errorStr.contains('nenhum datasource')) {
      return 'Não foi possível conectar aos servidores.\nVerifique sua conexão e tente novamente.';
    } else if (errorStr.contains('datasource')) {
      return 'Erro ao conectar aos servidores.\nTente novamente.';
    } else if (errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return 'Erro de conexão.\nVerifique sua internet.';
    } else if (errorStr.contains('mnemonic')) {
      return 'Erro ao carregar dados da carteira.';
    }

    return errorMessage;
  }

  void _retry() {
    setState(() {
      _messages.clear();
      _currentMessageIndex = -1;
      _hasError = false;
      _errorMessage = null;
      _isCompleted = false;
      _hasInitialized = false;
      _isHandlingSuccess = false;
    });
    _progressController.reset();
    _startImportProcess();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WalletDataStatus>(walletDataManagerProvider, (
      previous,
      next,
    ) async {
      if (_hasInitialized && !_hasError && !_isCompleted && next.hasError) {
        final errorMsg = next.errorMessage ?? 'Erro desconhecido';

        final isRetrying =
            errorMsg.toLowerCase().contains('tentando reconectar') ||
            errorMsg.toLowerCase().contains('tentativas');

        if (isRetrying) {
          await _showMessage(_getErrorMessage(errorMsg), hasError: false);
        } else {
          await _showMessage(_getErrorMessage(errorMsg), hasError: true);
          setState(() {
            _hasError = true;
            _errorMessage = _getUserFriendlyErrorMessage(errorMsg);
          });
        }
      }
    });

    return AnimatedOpacity(
      opacity: _isCompleted ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            ...List.generate(20, (index) => _buildParticle(index)),

            if (!_hasError) _buildOrbitalAnimation(),

            if (!_hasError) _buildProgressBar(),

            Positioned(
              left: 24,
              bottom: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < _messages.length; i++)
                    _buildMessageItem(_messages[i], i),
                ],
              ),
            ),

            if (_hasError)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.cloud_off_outlined,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _errorMessage ?? 'Ocorreu um erro',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _retry,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Tentar Novamente',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.6),
                  Colors.white.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
                stops: [0.0, 0.4, 0.5, 0.6, 1.0],
                begin: Alignment(-1.0 + (_progressController.value * 2), 0),
                end: Alignment(1.0 + (_progressController.value * 2), 0),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrbitalAnimation() {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _orbitalController,
          _pulseController,
          _glowController,
        ]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200 + (_glowController.value * 20),
                height: 200 + (_glowController.value * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(
                        alpha: 0.1 * _glowController.value,
                      ),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              Transform.rotate(
                angle: _orbitalController.value * 2 * math.pi,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Transform.rotate(
                angle: -_orbitalController.value * 2 * math.pi * 1.5,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 40 + (_pulseController.value * 10),
                height: 40 + (_pulseController.value * 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.15 + (_pulseController.value * 0.1),
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.4 + (_pulseController.value * 0.2),
                    ),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(
                        alpha: 0.2 * _pulseController.value,
                      ),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParticle(int index) {
    final random = math.Random(index);
    final startX = random.nextDouble();
    final startY = random.nextDouble();
    final duration = 3000 + random.nextInt(4000);
    final size = 2.0 + random.nextDouble() * 3;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: duration),
      builder: (context, double value, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * startX,
          top: MediaQuery.of(context).size.height * (startY - value * 0.3) % 1,
          child: Opacity(
            opacity: (0.3 + (math.sin(value * math.pi * 2) * 0.3)).clamp(
              0.0,
              0.6,
            ),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageItem(ImportMessage message, int index) {
    final isCurrentMessage = index == _currentMessageIndex;

    final isRetryMessage =
        message.text.toLowerCase().contains('reconect') ||
        message.text.toLowerCase().contains('tentando');

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeController, _slideController]),
      builder: (context, child) {
        final fadeValue = isCurrentMessage ? _fadeController.value : 1.0;
        final slideValue = isCurrentMessage ? _slideController.value : 1.0;
        final offset = (1 - slideValue) * 20.0;

        return Opacity(
          opacity: fadeValue * (message.hasError ? 1.0 : 0.85),
          child: Transform.translate(
            offset: Offset(-offset, 0),
            child: IntrinsicWidth(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      message.hasError
                          ? Colors.red.withValues(alpha: 0.1)
                          : isRetryMessage
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        message.hasError
                            ? Colors.red.withValues(alpha: 0.3)
                            : isRetryMessage
                            ? Colors.orange.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.isCompleted && !message.hasError) ...[
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: 28,
                              height: 28,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(
                                      alpha: 0.3 * value,
                                    ),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.black,
                                size: 18,
                              ),
                            ),
                          );
                        },
                      ),
                    ] else if (isRetryMessage) ...[
                      Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ] else if (!message.hasError) ...[
                      Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                    Flexible(
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color:
                              message.hasError
                                  ? Colors.red[300]
                                  : isRetryMessage
                                  ? Colors.orange[300]
                                  : Colors.white,
                          fontSize: 16,
                          fontWeight:
                              message.isCompleted
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
