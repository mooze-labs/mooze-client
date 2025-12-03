import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/pix/presentation/providers.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_indicator.dart';
import 'package:mooze_mobile/shared/connectivity/widgets/offline_price_info_overlay.dart';
import 'package:mooze_mobile/shared/widgets.dart';
import '../../providers.dart';
import '../../widgets.dart';

class ReceivePixScreen extends ConsumerStatefulWidget {
  const ReceivePixScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ReceivePixScreenState();
}

class _ReceivePixScreenState extends ConsumerState<ReceivePixScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _circleController;
  late Animation<double> _circleAnimation;

  @override
  void dispose() {
    _circleController.dispose();
    super.dispose();
  }

  bool _showOverlay = false;
  bool _showLoadingText = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _circleController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _circleAnimation = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeOutCubic),
    );
  }

  void _onSlideComplete(BuildContext context) async {
    setState(() {
      _showOverlay = true;
      _showLoadingText = true;
    });
    _circleController.forward();

    final controller = await ref.read(pixDepositControllerProvider.future);
    final depositAmount = ref.read(depositAmountProvider);
    final selectedAsset = ref.read(selectedAssetProvider);

    final amountInCents = (depositAmount * 100).toInt();

    final minAnimationTime = Future.delayed(Duration(milliseconds: 1500));

    controller.fold(
      (err) async {
        await minAnimationTime;
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(err)));
          setState(() {
            _showOverlay = false;
            _showLoadingText = false;
          });
          _circleController.reset();
        }
      },
      (controller) async {
        final result =
            await controller.newDeposit(amountInCents, selectedAsset).run();

        await minAnimationTime;

        result.fold(
          (err) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(err)));
              setState(() {
                _showOverlay = false;
                _showLoadingText = false;
              });
              _circleController.reset();
            }
          },
          (deposit) {
            ref.read(depositAmountProvider.notifier).state = 0.0;
            ref.invalidate(feeRateProvider);
            ref.invalidate(feeAmountProvider);
            ref.invalidate(discountedFeesDepositProvider);
            ref.invalidate(assetQuoteProvider);

            context.go("/pix/payment/${deposit.depositId}");
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text('Receber PIX'),
              centerTitle: true,
              actions: [
                OfflineIndicator(
                  onTap: () => OfflinePriceInfoOverlay.show(context),
                ),
              ],
            ),
            resizeToAvoidBottomInset: true,
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(child: _buildBody(context)),
            ),
          ),
          if (_showOverlay)
            LoadingOverlayWidget(
              circleController: _circleController,
              circleAnimation: _circleAnimation,
              showLoadingText: _showLoadingText,
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionText(BuildContext context) {
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
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final depositAmount = ref.watch(depositAmountProvider);
    final validation = ref.watch(depositValidationProvider);

    final isButtonEnabled = depositAmount > 0 && validation.isValid;

    return Padding(
      padding: EdgeInsets.only(right: 8, left: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInstructionText(context),
          SizedBox(height: 10),
          AssetSelectorWidget(),
          SizedBox(height: 10),
          PixValueInputWidget(),
          SizedBox(height: 16),
          TransactionDisplayWidget(),
          SizedBox(height: 16),
          PrimaryButton(
            onPressed: isButtonEnabled ? () => _onSlideComplete(context) : null,
            isEnabled: isButtonEnabled,
            text: 'Gerar QR Code',
          ),
          SizedBox(height: 120),
        ],
      ),
    );
  }
}
