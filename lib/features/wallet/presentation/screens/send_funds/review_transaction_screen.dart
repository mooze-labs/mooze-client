import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fpdart/fpdart.dart';

import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/domain/entities/partially_signed_transaction.dart';
import 'package:mooze_mobile/features/wallet/domain/enums/blockchain.dart';

import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/amount_provider.dart';
import '../../providers/send_funds/network_detection_provider.dart';
import '../../providers/send_funds/send_validation_controller.dart';
import '../../providers/send_funds/partially_signed_transaction_provider.dart';
import '../../providers/send_funds/bitcoin_price_provider.dart';
import '../../providers/send_funds/drain_provider.dart';
import '../../providers/balance_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/send_funds/network_indicator_widget.dart';

class ReviewTransactionScreen extends ConsumerStatefulWidget {
  const ReviewTransactionScreen({super.key});

  @override
  ConsumerState<ReviewTransactionScreen> createState() =>
      _ReviewTransactionScreenState();
}

class _ReviewTransactionScreenState
    extends ConsumerState<ReviewTransactionScreen> {
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    final psbtAsyncValue = ref.watch(psbtProvider);
    final bitcoinPrice = ref.watch(bitcoinPriceProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final validationState = ref.watch(sendValidationControllerProvider);
    final isDrainTransaction = ref.watch(isDrainTransactionProvider);

    return psbtAsyncValue.when(
      data:
          (psbtEither) => psbtEither.fold(
            (error) {
              return _buildErrorScreen(context, error);
            },
            (psbt) {
              return _buildSuccessScreen(
                context,
                psbt,
                bitcoinPrice,
                currencySymbol,
                validationState,
                isDrainTransaction,
              );
            },
          ),
      loading: () {
        return _buildLoadingScreen(context, isDrainTransaction);
      },
      error: (error, stackTrace) {
        return _buildErrorScreen(context, error.toString());
      },
    );
  }

  Widget _buildLoadingScreen(
    BuildContext context, [
    bool isDrainTransaction = false,
  ]) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDrainTransaction ? "Revisar Envio Total" : "Revisar Transação",
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              isDrainTransaction
                  ? 'Calculando envio total de fundos...'
                  : 'Preparando transação...',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Revisar Transação"),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Erro ao preparar transação',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(
    BuildContext context,
    PartiallySignedTransaction psbt,
    AsyncValue<double> bitcoinPrice,
    String currencySymbol,
    SendValidationState validationState,
    bool isDrainTransaction,
  ) {
    NetworkType networkType;
    switch (psbt.blockchain) {
      case Blockchain.bitcoin:
        networkType = NetworkType.bitcoin;
        break;
      case Blockchain.lightning:
        networkType = NetworkType.lightning;
        break;
      case Blockchain.liquid:
        networkType = NetworkType.liquid;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDrainTransaction ? "Revisar Envio Total" : "Revisar Transação",
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drain transaction info banner
              if (isDrainTransaction) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Enviando todos os fundos disponíveis. As taxas serão deduzidas automaticamente do valor total.",
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SvgPicture.asset(
                        psbt.asset.iconPath,
                        width: 32,
                        height: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            psbt.asset.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Consumer(
                            builder: (context, ref, _) {
                              if (isDrainTransaction &&
                                  (psbt.asset == Asset.btc ||
                                      psbt.asset == Asset.lbtc)) {
                                return ref
                                    .watch(balanceProvider(psbt.asset))
                                    .when(
                                      data:
                                          (balanceEither) => balanceEither.fold(
                                            (error) => Text(
                                              'Erro ao calcular valor',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                            (balance) {
                                              final actualDrainAmount =
                                                  balance - psbt.networkFees;
                                              return bitcoinPrice.when(
                                                data:
                                                    (btcPrice) => Text(
                                                      _formatAmount(
                                                        actualDrainAmount,
                                                        psbt.asset,
                                                        btcPrice,
                                                        currencySymbol,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.grey[400],
                                                      ),
                                                    ),
                                                loading:
                                                    () => Text(
                                                      'Carregando preço...',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.grey[400],
                                                      ),
                                                    ),
                                                error:
                                                    (error, _) => Text(
                                                      _formatAmount(
                                                        actualDrainAmount,
                                                        psbt.asset,
                                                        null,
                                                        currencySymbol,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.grey[400],
                                                      ),
                                                    ),
                                              );
                                            },
                                          ),
                                      loading:
                                          () => Text(
                                            'Calculando valor...',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                      error:
                                          (error, _) => Text(
                                            'Erro ao calcular valor',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                    );
                              }

                              return bitcoinPrice.when(
                                data:
                                    (btcPrice) => Text(
                                      _formatAmount(
                                        psbt.satoshi,
                                        psbt.asset,
                                        btcPrice,
                                        currencySymbol,
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                loading:
                                    () => Text(
                                      'Carregando preço...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                error:
                                    (error, _) => Text(
                                      _formatAmount(
                                        psbt.satoshi,
                                        psbt.asset,
                                        null,
                                        currencySymbol,
                                      ),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Icon(
                    Icons.hub_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Rede de Destino',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const NetworkIndicatorWidget(),
              const SizedBox(height: 24),

              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Endereço de Destino',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CopyButton(textToCopy: psbt.destination),

              const SizedBox(height: 24),

              Row(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Detalhes das Taxas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFeeDetails(
                context,
                psbt.asset,
                networkType,
                psbt.satoshi,
                psbt.networkFees,
              ),

              if (validationState.errors.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Há problemas com esta transação. Verifique os dados.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 20),

              SlideToConfirmButton(
                text: "Confirmar",
                onSlideComplete: () => _confirmTransaction(context, ref, psbt),
                isLoading: _isConfirming,
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeeDetails(
    BuildContext context,
    Asset asset,
    NetworkType networkType,
    BigInt amount,
    BigInt networkFees,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildFeeRow(
            context,
            'Taxa da Rede',
            _formatNetworkFee(networkFees, asset),
          ),
          const SizedBox(height: 12),
          _buildFeeRow(context, 'Taxa de Serviço', _getServiceFee(asset)),
          const SizedBox(height: 12),
          Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          _buildFeeRow(
            context,
            'Total das Taxas',
            _formatNetworkFee(networkFees, asset),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }

  String _getServiceFee(Asset asset) {
    switch (asset) {
      case Asset.btc || Asset.lbtc:
        return "Gratuito";
      case Asset.usdt:
      case Asset.depix:
        return "Gratuito";
    }
  }

  String _formatAmount(
    BigInt amountInSats,
    Asset asset,
    double? bitcoinPrice,
    String currencySymbol,
  ) {
    if (asset != Asset.btc && asset != Asset.lbtc) {
      final value = amountInSats.toDouble() / 100000000;
      return "${value.toStringAsFixed(2)} ${asset.ticker}";
    }

    final btcAmount = amountInSats.toDouble() / 100000000;
    final satText = amountInSats == BigInt.one ? 'sat' : 'sats';

    String result = "${btcAmount.toStringAsFixed(8)} BTC";
    result += " ($amountInSats $satText)";

    if (bitcoinPrice != null && bitcoinPrice > 0) {
      final fiatValue = btcAmount * bitcoinPrice;
      result += "\n≈ $currencySymbol ${fiatValue.toStringAsFixed(2)}";
    }

    return result;
  }

  String _formatNetworkFee(BigInt networkFees, Asset asset) {
    if (asset == Asset.btc || asset == Asset.lbtc) {
      if (networkFees == BigInt.zero) {
        return "Gratuito";
      }
      final satText = networkFees == BigInt.one ? 'sat' : 'sats';
      return "$networkFees $satText";
    } else {
      if (networkFees == BigInt.zero) {
        return "Gratuito";
      }
      final lbtcAmount = networkFees.toDouble() / 100000000;
      return "${lbtcAmount.toStringAsFixed(8)} L-BTC";
    }
  }

  void _confirmTransaction(
    BuildContext context,
    WidgetRef ref,
    PartiallySignedTransaction psbt,
  ) async {
    if (_isConfirming) return;

    setState(() {
      _isConfirming = true;
    });

    try {
      final walletControllerResult = await ref.read(
        walletControllerProvider.future,
      );

      final result = await walletControllerResult.fold(
        (error) async => left<String, dynamic>(
          "Erro ao acessar carteira: ${error.description}",
        ),
        (controller) async => await controller.confirmTransaction(psbt).run(),
      );

      result.fold(
        (error) => _showErrorDialog(context, error),
        (transaction) => _showSuccessDialog(context, ref, psbt.destination),
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, "Erro inesperado: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.error_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                const Text('Erro na Transação'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Não foi possível enviar a transação:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    error,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Verifique os dados e tente novamente.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showSuccessDialog(
    BuildContext context,
    WidgetRef ref,
    String destinationAddress,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text('Transação Enviada'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sua transação foi enviada com sucesso!',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Endereço de destino:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      CopyButton(
                        textToCopy: destinationAddress,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        borderRadius: 6,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        iconSize: 12,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Você pode acompanhar o status na seção de histórico.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ref.read(addressStateProvider.notifier).state = '';
                  ref.read(amountStateProvider.notifier).state = 0;
                  ref
                      .read(sendValidationControllerProvider.notifier)
                      .clearValidation();
                  context.go('/home');
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
