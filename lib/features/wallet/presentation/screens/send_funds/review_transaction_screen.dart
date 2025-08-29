import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

import '../../providers/send_funds/address_provider.dart';
import '../../providers/send_funds/amount_provider.dart';
import '../../providers/send_funds/selected_asset_provider.dart';
import '../../providers/send_funds/network_detection_provider.dart';
import '../../providers/send_funds/send_validation_controller.dart';
import '../../providers/send_funds/partially_signed_transaction_provider.dart';
import '../../providers/send_funds/transaction_loading_provider.dart';
import '../../providers/send_funds/bitcoin_price_provider.dart';
import '../../widgets/send_funds/network_indicator_widget.dart';

class ReviewTransactionScreen extends ConsumerStatefulWidget {
  const ReviewTransactionScreen({super.key});

  @override
  ConsumerState<ReviewTransactionScreen> createState() =>
      _ReviewTransactionScreenState();
}

class _ReviewTransactionScreenState
    extends ConsumerState<ReviewTransactionScreen> {
  bool _isCopied = false;

  @override
  Widget build(BuildContext context) {
    final address = ref.watch(addressStateProvider);
    final amount = ref.watch(amountStateProvider);
    final asset = ref.watch(selectedAssetProvider);
    final networkType = ref.watch(networkDetectionProvider(address));
    final bitcoinPrice = ref.watch(bitcoinPriceProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final validationState = ref.watch(sendValidationControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Revisar Transação"),
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
              const Text(
                'Resumo da Transação',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
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
                        asset.iconPath,
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
                            asset.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          bitcoinPrice.when(
                            data:
                                (btcPrice) => Text(
                                  _formatAmount(
                                    amount,
                                    asset,
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
                                    amount,
                                    asset,
                                    null,
                                    currencySymbol,
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[400],
                                  ),
                                ),
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
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _copyAddressToClipboard(context, address),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color:
                            _isCopied
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isCopied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _copyAddressToClipboard(context, address),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              _isCopied
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          _isCopied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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
              _buildFeeDetails(context, asset, networkType, amount),

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
                onSlideComplete: () => _confirmTransaction(context, ref),
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
    int amount,
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
            _getNetworkFee(networkType, asset),
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
            _getTotalFees(networkType, asset),
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

  // TODO: Implementar taxas
  String _getNetworkFee(NetworkType networkType, Asset asset) {
    switch (networkType) {
      case NetworkType.bitcoin:
        return "~500-2000 sats";
      case NetworkType.lightning:
        return "~1-10 sats";
      case NetworkType.liquid:
        if (asset == Asset.btc) {
          return "~100 sats";
        } else {
          return "~0.1 L-BTC";
        }
      case NetworkType.unknown:
        return "Taxa não disponível";
    }
  }

  String _getServiceFee(Asset asset) {
    switch (asset) {
      case Asset.btc:
        return "Gratuito";
      case Asset.usdt:
      case Asset.depix:
        return "Gratuito";
    }
  }

  String _getTotalFees(NetworkType networkType, Asset asset) {
    switch (networkType) {
      case NetworkType.bitcoin:
        return "~500-2000 sats";
      case NetworkType.lightning:
        return "~1-10 sats";
      case NetworkType.liquid:
        if (asset == Asset.btc) {
          return "~100 sats";
        } else {
          return "~0.1 L-BTC";
        }
      case NetworkType.unknown:
        return "Taxa não disponível";
    }
  }

  String _formatAmount(
    int amountInSats,
    Asset asset,
    double? bitcoinPrice,
    String currencySymbol,
  ) {
    if (asset != Asset.btc) {
      final value = amountInSats / 100000000;
      return "${value.toStringAsFixed(2)} ${asset.ticker}";
    }

    final btcAmount = amountInSats / 100000000;
    final satText = amountInSats == 1 ? 'sat' : 'sats';

    String result = "${btcAmount.toStringAsFixed(8)} BTC";
    result += " ($amountInSats $satText)";

    if (bitcoinPrice != null && bitcoinPrice > 0) {
      final fiatValue = btcAmount * bitcoinPrice;
      result += "\n≈ $currencySymbol ${fiatValue.toStringAsFixed(2)}";
    }

    return result;
  }

  void _confirmTransaction(BuildContext context, WidgetRef ref) async {
    await ref
        .read(sendValidationControllerProvider.notifier)
        .validateTransaction();
    final finalValidation = ref.read(sendValidationControllerProvider);

    if (!finalValidation.canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não é possível enviar a transação. Verifique os dados.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    ref.read(transactionLoadingProvider.notifier).state = true;

    try {
      final psbtAsyncValue = await ref.read(psbtProvider.future);

      psbtAsyncValue.fold(
        (error) {
          _showErrorDialog(context, 'Erro ao criar transação: $error');
        },
        (psbt) {
          _showSuccessDialog(context, ref, psbt.destination);
        },
      );
    } catch (error) {
      _showErrorDialog(context, 'Erro inesperado: ${error.toString()}');
    } finally {
      ref.read(transactionLoadingProvider.notifier).state = false;
    }
  }

  void _copyAddressToClipboard(BuildContext context, String address) async {
    await Clipboard.setData(ClipboardData(text: address));

    setState(() {
      _isCopied = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  void _showErrorDialog(BuildContext context, String message) {
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
            content: Text(message),
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
                    color: Theme.of(context).colorScheme.surfaceVariant,
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
                      Text(
                        destinationAddress,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
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
                  Navigator.of(context).pop();
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
