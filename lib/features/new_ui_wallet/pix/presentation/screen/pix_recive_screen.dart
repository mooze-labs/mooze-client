import 'package:flutter/material.dart';
import 'package:mooze_mobile/features/new_ui_wallet/pix/presentation/screen/pix_payment_screen.dart';
import 'package:mooze_mobile/features/new_ui_wallet/pix/presentation/widgets/recive/asset_selector_widget.dart';
import 'package:mooze_mobile/features/new_ui_wallet/pix/presentation/widgets/recive/loading_overlay_widget.dart';
import 'package:mooze_mobile/features/new_ui_wallet/pix/presentation/widgets/recive/pix_value_input_widget.dart';
import 'package:mooze_mobile/features/new_ui_wallet/pix/presentation/widgets/recive/transaction_details_widget.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/widgets/buttons/slide_to_confirm_button.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/widgets/custom_app_bar.dart';
import 'package:mooze_mobile/themes/theme_base.dart';

class ReceberPixScreen extends StatefulWidget {
  @override
  _ReceberPixScreenState createState() => _ReceberPixScreenState();
}

class _ReceberPixScreenState extends State<ReceberPixScreen>
    with TickerProviderStateMixin {
  String? selectedAsset = 'Depix';
  TextEditingController valueController = TextEditingController();

  late AnimationController _circleController;
  late Animation<double> _circleAnimation;
  bool _showOverlay = false;
  bool _showLoadingText = false;

  // Constants - Colors
  static const Color _backgroundColor = Color(0xFF0A0A0A);
  static const Color _cardBackground = Color(0xFF191818);
  static const Color _primaryColor = Color(0xFFEA1E63);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFF9194A6);
  static const Color _textTertiary = Color(0xFF8E8E8E);
  static const Color _positiveColor = Colors.green;

  final List<String> assets = ['Depix', 'Bitcoin', 'Ethereum', 'Cardano'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupInitialValue();
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

  void _setupInitialValue() {
    valueController.text = 'R\$ 00,00';
  }

  @override
  void dispose() {
    valueController.dispose();
    _circleController.dispose();
    super.dispose();
  }

  void _onAssetChanged(String? newAsset) {
    setState(() {
      selectedAsset = newAsset;
    });
  }

  void _onSlideComplete() async {
    setState(() {
      _showOverlay = true;
      _showLoadingText = true;
    });

    _circleController.forward();
    await Future.delayed(Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => PixPaymentScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: _backgroundColor,
          appBar: _buildAppBar(),
          resizeToAvoidBottomInset: false,
          body: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: _buildBody(),
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

  CustomAppBar _buildAppBar() {
    return CustomAppBar(
      title: TextSpan(
        text: 'Receber ',
        style: AppTextStyles.title,
        children: [
          TextSpan(
            text: 'PIX',
            style: AppTextStyles.title.copyWith(color: _primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(right: 8, left: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionText(),
            SizedBox(height: 10),
            AssetSelectorWidget(
              selectedAsset: selectedAsset,
              assets: assets,
              onAssetChanged: _onAssetChanged,
            ),
            SizedBox(height: 10),
            Expanded(
              child: PixValueInputWidget(valueController: valueController),
            ),
            SizedBox(height: 16),
            Expanded(child: TransactionDetailsWidget()),
            SizedBox(height: 16),
            SlideToConfirmButton(onSlideComplete: _onSlideComplete),
            SizedBox(height: 16),
          ],
        ),
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
                color: _primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}
