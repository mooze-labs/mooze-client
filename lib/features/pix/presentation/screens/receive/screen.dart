import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mooze_mobile/features/pix/presentation/providers.dart';

import 'package:mooze_mobile/shared/widgets.dart';
import 'package:mooze_mobile/themes/theme_base.dart';

import 'providers.dart';
import 'widgets.dart';

class ReceivePixScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ReceivePixScreenState();
}

class _ReceivePixScreenState extends ConsumerState<ReceivePixScreen>
  with SingleTickerProviderStateMixin {

  late AnimationController _circleController;
  late Animation<double> _circleAnimation;

  bool _showOverlay = false;
  bool _showLoadingText = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _circleController = AnimationController(duration: Duration(milliseconds: 800), vsync: this);
    _circleAnimation = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeOutCubic)
    );
  }

  void _onSlideComplete(BuildContext context) async {
    setState(() {
      _showOverlay = true;
      _showLoadingText = true;
    });
    _circleController.forward();

    // Wait for payment details to be ready
    final paymentDetailsResult = await ref.read(paymentDetailsProvider.future);
    
    await paymentDetailsResult.fold(
      (error) async {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Falha ao gerar dados de pagamento: $error"))
          );
        }
      },
      (paymentDetails) async {
        final controller = await ref.read(pixDepositControllerProvider.future);
        final amountInCents = (paymentDetails.depositAmount * 100.0).toInt();
        final asset = ref.read(selectedAssetProvider);

        return await controller.fold(
          (err) async {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Falha ao gerar QR code: conexão falhou."))
              );
            }
          },
          (controller) async {
            final deposit = await controller.newDeposit(amountInCents, asset).run();
            return deposit.fold(
              (err) async {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Falha ao gerar QR code: $err."))
                  );
                }
              },
              (deposit) => context.go("/pix/payment")
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: _buildAppBar(context),
          resizeToAvoidBottomInset: false,
          body: GestureDetector(onTap: () => FocusScope.of(context).unfocus(), child: _buildBody(context)),
        ),
        if (_showOverlay)
          LoadingOverlayWidget(circleController: _circleController, circleAnimation: _circleAnimation, showLoadingText: _showLoadingText)
      ],
    );
  }

  CustomAppBar _buildAppBar(BuildContext context) {
    return CustomAppBar(
      title: TextSpan(
        text: 'Receber ',
        style: AppTextStyles.title,
        children: [
          TextSpan(
            text: 'PIX',
            style: AppTextStyles.title.copyWith(color: Theme.of(context).colorScheme.primary),
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(right: 8, left: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionText(context),
            SizedBox(height: 10),
            AssetSelectorWidget(),
            SizedBox(height: 10),
            Expanded(child: PixValueInputWidget()),
            SizedBox(height: 16),
            Expanded(child: TransactionDisplayWidget()),
            SizedBox(height: 16),
            SlideToConfirmButton(onSlideComplete: () => _onSlideComplete(context)),
            SizedBox(height: 16)
          ],
        ),
      ),
    );
  }
}