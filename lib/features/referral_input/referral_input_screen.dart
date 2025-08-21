import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/new_ui_wallet/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/support_screen.dart';
import 'package:mooze_mobile/shared/formatter/upper_case_text_formatter.dart';
import 'package:mooze_mobile/shared/user/services/mock_referral_service.dart';
import 'package:mooze_mobile/themes/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/mooze/user.dart';

const BACKEND_URL = String.fromEnvironment(
  "BACKEND_URL",
  defaultValue: "api.mooze.app",
);

class ReferralInputScreen extends StatefulWidget {
  const ReferralInputScreen({super.key});

  @override
  State<ReferralInputScreen> createState() => _ReferralInputScreenState();
}

class _ReferralInputScreenState extends State<ReferralInputScreen>
    with TickerProviderStateMixin {
  final TextEditingController _referralCodeController = TextEditingController();
  final userService = MockUserService();
  // TODO: Remove MOCK
  // final ReferralService _referralService = ReferralService(
  //   backendUrl: BACKEND_URL,
  // );
  // final userService = UserService(backendUrl: BACKEND_URL);
  final MockReferralService _referralService = MockReferralService();
  final UserService _userService = UserService(backendUrl: BACKEND_URL);
  String? _existingReferralCode;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _checkExistingReferralCode();
    _animationController.forward();
  }

  Future<void> _checkExistingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    final existingCode = prefs.getString('referralCode');

    final userDetails = await _userService.getUserDetails();
    if (userDetails?.referredBy != null) {
      setState(() {
        _existingReferralCode = userDetails!.referredBy;
      });
      if (existingCode == null) {
        await prefs.setString('referralCode', userDetails!.referredBy!);
      }
      return;
    }

    if (existingCode != null) {
      setState(() {
        _existingReferralCode = existingCode;
      });
    }
  }

  @override
  void dispose() {
    _referralCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _validateReferralCode() async {
    final referralCode = _referralCodeController.text.trim().toUpperCase();
    if (referralCode.isEmpty) return;

    setState(() {
      _isLoading = true;
    });
    
    await Future.delayed(Duration(seconds: 3));
    // final userId = await userService.getUserId(); // TODO: Remove MOCK and add userId in validateReferralCode

    final result = await _referralService.validateReferralCode(referralCode).run();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    result.match(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Código inválido. Verifique e tente novamente.'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },

      (isValid) async {
        if (isValid) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('referralCode', referralCode);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Código válido! Desconto aplicado com sucesso.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          await _checkExistingReferralCode();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Código inválido. Verifique e tente novamente.'),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Código de Indicação'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                const Color(0xFF8BC34A).withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF8BC34A),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF4CAF50,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.card_giftcard_rounded,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Economize com indicações!',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ATÉ 15% DE DESCONTO',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Digite seu código de indicação e aproveite descontos exclusivos em todas as taxas da plataforma.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onPrimary.withValues(alpha: 
                                    0.7,
                                  ),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        if (_existingReferralCode != null)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4CAF50,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Desconto Ativo',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Código: $_existingReferralCode',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white.withValues(alpha: 
                                                0.9,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.savings_rounded,
                                        color: Colors.white.withValues(alpha: 0.9),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Você está economizando em todas as transações!',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withValues(alpha: 
                                              0.9,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primaryColor,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/new_ui_wallet/assets/icons/menu/settings/gift.svg',
                                      width: 24,
                                      height: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: SizedBox(
                                        height: 50,
                                        child: TextField(
                                          controller: _referralCodeController,
                                          keyboardType: TextInputType.phone,
                                          inputFormatters: [
                                            UpperCaseTextFormatter(),
                                          ],
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium!.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          cursorColor: Colors.white,
                                          decoration: const InputDecoration(
                                            filled: false,
                                            isCollapsed: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder:
                                                InputBorder.none,
                                            hintText: 'Ex: MOOZE123',
                                            hintStyle: TextStyle(
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: 12,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  color: AppColors.backgroundColor,
                                  child: const Text(
                                    'Código de Indicação',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                if (_existingReferralCode == null) ...[
                  const SizedBox(height: 24),
                  PrimaryButton(
                    onPressed:
                        _isLoading ? null : () => _validateReferralCode(),
                    text: _isLoading ? 'Validando...' : 'Aplicar Código',
                    isEnabled: !_isLoading,
                  ),
                  const SizedBox(height: 25),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
