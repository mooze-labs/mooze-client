import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/infra/sync/wallet_data_manager.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/transaction_monitor_provider.dart';
import 'package:mooze_mobile/shared/infra/lwk/utils/cache_manager.dart';
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
      duration: const Duration(seconds: 15),
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

  Future<void> _startImportProcess() async {
    try {
      _progressController.forward();

      final transactionMonitor = ref.read(transactionMonitorServiceProvider);
      transactionMonitor.startImporting();
      debugPrint(
        '[ImportLoading] Modo importação ativado no TransactionMonitor',
      );

      await _showMessage('Processando...');
      await Future.delayed(const Duration(milliseconds: 500));

      await _showMessage('Verificando dados...');

      try {
        await LwkCacheManager.clearLwkDatabase();
        debugPrint('✅ LWK database cleared before import');
      } catch (e) {
        debugPrint('⚠️ Failed to clear LWK database: $e');
      }

      final walletDataManager = ref.read(walletDataManagerProvider.notifier);
      walletDataManager.invalidateAllWalletProviders();
      await Future.delayed(const Duration(milliseconds: 800));

      await _showMessage('Autorizando...');
      setState(() => _hasInitialized = true);
      await Future.delayed(const Duration(milliseconds: 600));

      debugPrint('[ImportLoading] Iniciando wallet...');
      walletDataManager.initializeWallet();

      await Future.delayed(const Duration(seconds: 15));

      if (mounted && _hasInitialized && !_hasError && !_isCompleted) {
        debugPrint(
          '[ImportLoading] Timeout atingido, verificando estado manualmente',
        );
        final currentStatus = ref.read(walletDataManagerProvider);
        if (currentStatus.isSuccess) {
          await _handleWalletSuccess();
        } else if (currentStatus.hasError) {
          final errorMsg =
              currentStatus.errorMessage ?? 'Timeout na inicialização';
          await _showMessage(errorMsg, hasError: true);
          setState(() {
            _hasError = true;
            _errorMessage = errorMsg;
          });
        }
      }
    } catch (e) {
      debugPrint('[ImportLoading] Erro capturado: $e');
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
      await Future.delayed(const Duration(milliseconds: 200));
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
    await Future.delayed(const Duration(milliseconds: 300));
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('mnemonic')) {
      return 'Erro ao carregar dados ✗';
    } else if (errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return 'Erro de conexão ✗';
    } else if (errorStr.contains('datasource')) {
      return 'Erro ao inicializar ✗';
    }

    return 'Erro na importação ✗';
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

  Future<void> _handleWalletSuccess() async {
    if (_isCompleted || _isHandlingSuccess) return;

    setState(() => _isHandlingSuccess = true);
    debugPrint('[ImportLoading] Iniciando _handleWalletSuccess');

    await _showMessage('Carregando saldo...');

    final maxWaitTime = DateTime.now().add(const Duration(seconds: 5));
    bool dataLoaded = false;

    while (DateTime.now().isBefore(maxWaitTime) && !dataLoaded) {
      await Future.delayed(const Duration(milliseconds: 300));
      final status = ref.read(walletDataManagerProvider);

      if (status.lastSync != null) {
        debugPrint(
          '[ImportLoading] Dados carregados, lastSync: ${status.lastSync}',
        );
        dataLoaded = true;
        break;
      }
    }

    if (!dataLoaded) {
      debugPrint(
        '[ImportLoading] Timeout aguardando carregamento de dados, prosseguindo...',
      );
    }

    debugPrint(
      '[ImportLoading] Marcando transações existentes como conhecidas...',
    );
    final transactionMonitor = ref.read(transactionMonitorServiceProvider);
    await transactionMonitor.markExistingTransactionsAsKnown();

    await Future.delayed(const Duration(milliseconds: 800));

    await _showMessage('Importação concluída ✓', isCompleted: true);
    await _checkBounceController.forward();
    await Future.delayed(const Duration(milliseconds: 1200));

    transactionMonitor.finishImporting();
    debugPrint(
      '[ImportLoading] Modo importação desativado no TransactionMonitor',
    );

    setState(() => _isCompleted = true);
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      debugPrint('[ImportLoading] Navegando para /home');
      context.go("/home");
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WalletDataStatus>(walletDataManagerProvider, (
      previous,
      next,
    ) async {
      debugPrint(
        '[ImportLoading] Estado mudou - hasInitialized: $_hasInitialized, hasError: $_hasError, isCompleted: $_isCompleted',
      );
      debugPrint(
        '[ImportLoading] WalletState: ${next.state}, isSuccess: ${next.isSuccess}, hasError: ${next.hasError}',
      );

      if (_hasInitialized && !_hasError && !_isCompleted) {
        if (next.isSuccess) {
          debugPrint(
            '[ImportLoading] Sucesso detectado, chamando _handleWalletSuccess',
          );
          await _handleWalletSuccess();
        } else if (next.hasError) {
          debugPrint('[ImportLoading] Erro detectado: ${next.errorMessage}');
          final errorMsg = next.errorMessage ?? 'Erro desconhecido';
          await _showMessage(errorMsg, hasError: true);
          setState(() {
            _hasError = true;
            _errorMessage = errorMsg;
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _errorMessage ?? 'Ocorreu um erro',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextButton(
                      onPressed: _retry,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 18,
                        ),
                        backgroundColor: Colors.white.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Tentar Novamente',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
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
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.6),
                  Colors.white.withOpacity(0.3),
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
                      color: Colors.white.withOpacity(
                        0.1 * _glowController.value,
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
                      color: Colors.white.withOpacity(0.15),
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
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
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
                      color: Colors.white.withOpacity(0.2),
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
                              color: Colors.white.withOpacity(0.7),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.4),
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
                  color: Colors.white.withOpacity(
                    0.15 + (_pulseController.value * 0.1),
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(
                      0.4 + (_pulseController.value * 0.2),
                    ),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(
                        0.2 * _pulseController.value,
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
                    color: Colors.white.withOpacity(0.3),
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
                          ? Colors.red.withOpacity(0.1)
                          : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        message.hasError
                            ? Colors.red.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
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
                                    color: Colors.white.withOpacity(
                                      0.3 * value,
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
                    ] else if (!message.hasError) ...[
                      Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                    Text(
                      message.text,
                      style: TextStyle(
                        color:
                            message.hasError ? Colors.red[300] : Colors.white,
                        fontSize: 16,
                        fontWeight:
                            message.isCompleted
                                ? FontWeight.w600
                                : FontWeight.w400,
                        letterSpacing: 0.3,
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
