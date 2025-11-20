import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/shared/widgets/buttons/slide_to_confirm_button.dart';
import 'package:mooze_mobile/features/wallet/presentation/widgets/fee_speed_selector.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/selected_asset_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/amount_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/address_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/drain_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/fee_speed_provider.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/prepared_psbt_provider.dart';

class ReviewOnchainTransactionScreen extends ConsumerStatefulWidget {
  const ReviewOnchainTransactionScreen({super.key});

  @override
  ConsumerState<ReviewOnchainTransactionScreen> createState() =>
      _ReviewOnchainTransactionScreenState();
}

class _ReviewOnchainTransactionScreenState
    extends ConsumerState<ReviewOnchainTransactionScreen> {
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleConfirm() async {
    if (_isConfirming) return;

    setState(() {
      _isConfirming = true;
    });

    try {
      final walletController = await ref.read(walletControllerProvider.future);
      final psbt = ref.read(preparedPsbtProvider);

      if (psbt == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro: Transação não encontrada'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await walletController.match(
        (error) async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (controller) async {
          final txResult =
              await controller.confirmTransaction(psbt: psbt).run();

          await txResult.match(
            (error) async {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao enviar transação: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            (transaction) async {
              if (mounted) {
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 64,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Transação Enviada!',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sua transação foi transmitida com sucesso para a rede Bitcoin.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[400]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TXID:',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[500],
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    transaction.id,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  context.go('/home');
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Concluir'),
                              ),
                            ),
                          ],
                        ),
                      ),
                );
              }
            },
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = ref.watch(selectedAssetProvider);
    final finalAmount = ref.watch(finalAmountProvider);
    final amount = BigInt.from(finalAmount);
    final isDrainTransaction = ref.watch(isDrainTransactionProvider);
    final destination = ref.watch(addressStateProvider);
    final psbt = ref.watch(preparedPsbtProvider);

    final amountBtc = amount.toDouble() / 100000000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisar Transação'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        child:
            psbt == null
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao preparar transação',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Transação não encontrada',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[400]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
                : _buildReviewContent(
                  context,
                  asset,
                  amountBtc,
                  isDrainTransaction,
                  destination,
                  psbt.networkFees,
                ),
      ),
    );
  }

  Widget _buildReviewContent(
    BuildContext context,
    Asset asset,
    double amountBtc,
    bool isDrainTransaction,
    String destination,
    BigInt networkFee,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTransactionSummary(
                  context,
                  asset,
                  amountBtc,
                  isDrainTransaction,
                  destination,
                  networkFee,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                _buildFeeSpeedInfo(context),
                const SizedBox(height: 16),
                Text(
                  'A taxa foi calculada com base na velocidade selecionada.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SlideToConfirmButton(
            text: _isConfirming ? 'Enviando...' : 'Deslizar para confirmar',
            isLoading: _isConfirming,
            onSlideComplete: _isConfirming ? () {} : _handleConfirm,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionSummary(
    BuildContext context,
    Asset asset,
    double amountBtc,
    bool isDrain,
    String destination,
    BigInt networkFee,
  ) {
    final feeBtc = networkFee.toDouble() / 100000000;
    final totalBtc = isDrain ? amountBtc : amountBtc + feeBtc;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(asset.iconPath, width: 24, height: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDrain ? 'Enviar Tudo' : 'Enviar ${asset.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Bitcoin On-chain',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valor',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
              ),
              Text(
                '${amountBtc.toStringAsFixed(8)} BTC',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Taxa de rede',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
              ),
              Text(
                '${feeBtc.toStringAsFixed(8)} BTC',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isDrain) ...[
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${totalBtc.toStringAsFixed(8)} BTC',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Destino',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            destination,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFeeSpeedInfo(BuildContext context) {
    final selectedSpeed = ref.watch(feeSpeedProvider);

    String speedLabel;
    String speedDescription;
    Color speedColor;
    IconData speedIcon;

    switch (selectedSpeed) {
      case FeeSpeed.low:
        speedLabel = 'Econômica';
        speedDescription = 'Confirmação mais lenta, taxa menor';
        speedColor = Colors.blue;
        speedIcon = Icons.schedule;
        break;
      case FeeSpeed.medium:
        speedLabel = 'Normal';
        speedDescription = 'Equilíbrio entre velocidade e custo';
        speedColor = Colors.orange;
        speedIcon = Icons.speed;
        break;
      case FeeSpeed.fast:
        speedLabel = 'Prioritária';
        speedDescription = 'Confirmação mais rápida, taxa maior';
        speedColor = Colors.green;
        speedIcon = Icons.flash_on;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: speedColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: speedColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: speedColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(speedIcon, color: speedColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Velocidade: $speedLabel',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: speedColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  speedDescription,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
