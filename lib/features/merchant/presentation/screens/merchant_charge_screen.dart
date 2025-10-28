import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/merchant/presentation/providers/cart_provider.dart';
import 'package:mooze_mobile/features/pix/presentation/providers.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/receive/providers.dart';
import 'package:mooze_mobile/features/pix/presentation/screens/receive/widgets.dart';
import 'package:mooze_mobile/shared/widgets/buttons/slide_to_confirm_button.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/shared/user/providers/levels_provider.dart';

class MerchantChargeScreen extends ConsumerStatefulWidget {
  final double totalAmount;
  final List<CartItem> items;

  const MerchantChargeScreen({
    super.key,
    required this.totalAmount,
    required this.items,
  });

  @override
  ConsumerState<MerchantChargeScreen> createState() =>
      _MerchantChargeScreenState();
}

class _MerchantChargeScreenState extends ConsumerState<MerchantChargeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _circleController;
  late Animation<double> _circleAnimation;

  bool _showOverlay = false;
  bool _showLoadingText = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(depositAmountProvider.notifier).state = widget.totalAmount;
    });
  }

  void _initializeControllers() {
    _circleController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _circleAnimation = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _circleController.dispose();
    super.dispose();
  }

  void _onSlideComplete() async {
    setState(() {
      _showOverlay = true;
      _showLoadingText = true;
    });
    _circleController.forward();

    final controller = await ref.read(pixDepositControllerProvider.future);
    final depositAmount = ref.read(depositAmountProvider);
    final selectedAsset = ref.read(selectedAssetProvider);

    final amountInCents = (depositAmount * 100).toInt();

    controller.fold(
      (err) {
        if (mounted) {
          setState(() {
            _showOverlay = false;
            _showLoadingText = false;
          });
          _circleController.reset();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
        }
      },
      (controller) async => await controller
          .newDeposit(amountInCents, selectedAsset)
          .run()
          .then(
            (maybeDeposit) => maybeDeposit.fold((err) {
              if (mounted) {
                setState(() {
                  _showOverlay = false;
                  _showLoadingText = false;
                });
                _circleController.reset();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(err)));
              }
            }, (deposit) => context.go("/pix/payment/${deposit.depositId}")),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEA1E63), Color(0xFF841138)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                        ).copyWith(top: 20),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInstructionText(),
                              SizedBox(height: 20),
                              AssetSelectorWidget(),
                              SizedBox(height: 20),
                              _buildLimitsInfo(),
                              SizedBox(height: 20),
                              _buildItemsList(),
                              SizedBox(height: 20),
                              _buildTransactionData(),
                              SizedBox(height: 20),
                              SlideToConfirmButton(
                                onSlideComplete: _onSlideComplete,
                                text: 'Gerar QR Code',
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showOverlay)
          LoadingOverlayWidget(
            circleController: _circleController,
            circleAnimation: _circleAnimation,
            showLoadingText: _showLoadingText,
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Text(
                'Receber',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 48),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'R\$${widget.totalAmount.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          // TODO: Put BTC value here
        ],
      ),
    );
  }

  Widget _buildInstructionText() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: 'Escolha o ativo que deseja receber na ',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          children: [
            TextSpan(
              text: 'Mooze',
              style: TextStyle(
                color: Color(0xFFE91E63),
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitsInfo() {
    return Consumer(
      builder: (context, ref, child) {
        final levelsData = ref.watch(levelsProvider);

        return levelsData.when(
          data:
              (data) => Column(
                children: [
                  _buildLimitRow(
                    'Limite diário',
                    'R\$ ${data.allowedSpending.toStringAsFixed(2)}',
                  ),
                  SizedBox(height: 8),
                  _buildLimitRow(
                    'Limite restante',
                    'R\$ ${data.remainingLimit.toStringAsFixed(2)}',
                  ),
                  SizedBox(height: 8),
                  _buildLimitRow(
                    'Valor mínimo',
                    'R\$ ${data.absoluteMinLimit.toStringAsFixed(2)}',
                  ),
                ],
              ),
          loading:
              () => Column(
                children: [
                  _buildLimitRow('Limite diário', 'Carregando...'),
                  SizedBox(height: 8),
                  _buildLimitRow('Limite restante', 'Carregando...'),
                  SizedBox(height: 8),
                  _buildLimitRow('Valor mínimo', 'Carregando...'),
                ],
              ),
          error:
              (error, stack) => Column(
                children: [
                  _buildLimitRow('Limite diário', 'R\$ 250.00'),
                  SizedBox(height: 8),
                  _buildLimitRow('Limite restante', 'R\$ 250.00'),
                  SizedBox(height: 8),
                  _buildLimitRow('Valor mínimo', 'R\$ 20.00'),
                ],
              ),
        );
      },
    );
  }

  Widget _buildLimitRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Itens',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        ...widget.items.map((item) => _buildItemRow(item)).toList(),
      ],
    );
  }

  Widget _buildItemRow(CartItem item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nome,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'R\$ ${item.preco.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Text(
            'x${item.quantidade}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionData() {
    final totalAmount = widget.totalAmount;
    ref.watch(selectedAssetProvider);
    final feeAmount = ref.watch(feeAmountProvider(totalAmount));
    final feeRate = ref.watch(feeRateProvider(totalAmount));
    final discountedDeposit = ref.watch(
      discountedFeesDepositProvider(totalAmount),
    );

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dados da transação',
            style: TextStyle(
              color: Color(0xFFE91E63),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          feeAmount.when(
            data: (data) {
              return (totalAmount < 55)
                  ? _buildTransactionRow(
                    'Taxa Mooze',
                    'R\$ 1,00 + taxas de rede',
                    null,
                  )
                  : _buildTransactionRow(
                    'Taxa Mooze',
                    'R\$ ${data.toStringAsFixed(2)}',
                    null,
                  );
            },
            error:
                (error, stackTrace) =>
                    _buildTransactionRow('Taxa Mooze', 'Erro', null),
            loading:
                () => _buildTransactionRow('Taxa Mooze', 'Carregando...', null),
          ),
          SizedBox(height: 8),
          feeRate.when(
            data: (data) {
              return (totalAmount < 55)
                  ? _buildTransactionRow('Percentual', 'R\$ 1,00 (FIXO)', null)
                  : _buildTransactionRow(
                    'Percentual',
                    '${data.toStringAsFixed(2)}%',
                    null,
                  );
            },
            error:
                (error, stackTrace) =>
                    _buildTransactionRow('Percentual', 'Erro', null),
            loading:
                () => _buildTransactionRow('Percentual', 'Carregando...', null),
          ),
          SizedBox(height: 8),
          _buildTransactionRow('Taxa da processadora', 'R\$ 1,00', null),
          SizedBox(height: 8),
          discountedDeposit.when(
            data:
                (data) => _buildTransactionRow(
                  'Valor final',
                  'R\$ ${data.toStringAsFixed(2)}',
                  null,
                ),
            error:
                (error, stackTrace) =>
                    _buildTransactionRow('Valor final', 'Erro', null),
            loading:
                () =>
                    _buildTransactionRow('Valor final', 'Carregando...', null),
          ),
          SizedBox(height: 8),
          Consumer(
            builder: (context, ref, child) {
              final selectedAsset = ref.watch(selectedAssetProvider);
              final assetQuote = ref.watch(assetQuoteProvider(selectedAsset));

              return assetQuote.when(
                data:
                    (data) => data.fold(
                      (error) => _buildTransactionRow(
                        'Valor em ${selectedAsset.ticker}',
                        'Erro na cotação',
                        null,
                      ),
                      (val) => val.fold(
                        () => _buildTransactionRow(
                          'Valor em ${selectedAsset.ticker}',
                          'Cotação indisponível',
                          null,
                        ),
                        (quote) => discountedDeposit.when(
                          data: (finalAmount) {
                            final cryptoAmount = finalAmount / quote;
                            return _buildTransactionRow(
                              'Valor em ${selectedAsset.ticker}',
                              '${cryptoAmount.toStringAsFixed(8)} ${selectedAsset.ticker}',
                              null,
                            );
                          },
                          error:
                              (error, stackTrace) => _buildTransactionRow(
                                'Valor em ${selectedAsset.ticker}',
                                'Erro no cálculo',
                                null,
                              ),
                          loading:
                              () => _buildTransactionRow(
                                'Valor em ${selectedAsset.ticker}',
                                'Calculando...',
                                null,
                              ),
                        ),
                      ),
                    ),
                error:
                    (error, stackTrace) => _buildTransactionRow(
                      'Valor em ${selectedAsset.ticker}',
                      'Erro na cotação',
                      null,
                    ),
                loading:
                    () => _buildTransactionRow(
                      'Valor em ${selectedAsset.ticker}',
                      'Carregando cotação...',
                      null,
                    ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(String label, String value, String? subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white, fontSize: 14)),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(color: Color(0xFFE91E63), fontSize: 12),
              ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
