import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/features/phone_verification/presentation/widgets/send_method.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import 'package:mooze_mobile/shared/widgets.dart';

final _phoneFormatter = MaskTextInputFormatter(
  mask: '(##) #####-####',
  filter: {"#": RegExp(r'[0-9]')},
);

class PhoneVerificationMethodScreen extends StatefulWidget {
  final bool forceAuth;
  final bool isAppResuming;

  const PhoneVerificationMethodScreen({
    super.key,
    this.forceAuth = false,
    this.isAppResuming = false,
  });

  @override
  State<PhoneVerificationMethodScreen> createState() =>
      _PhoneVerificationMethodScreenState();
}

class _PhoneVerificationMethodScreenState
    extends State<PhoneVerificationMethodScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isPhoneValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        _isPhoneValid = _phoneFormatter.getUnmaskedText().length == 11;
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    SendMethod? selectedMethod = sendMethods.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.phone_verif_method_title),
        leading: const Icon(Icons.arrow_back_ios_new_rounded),
      ),
      body: PlatformSafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineSmall,
                  children: [
                    TextSpan(text: t.phone_verif_inform_prefix),
                    TextSpan(
                      text: t.phone_verif_phone_number,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                t.phone_verif_method_subtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),

              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.colors.primaryColor,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/flags/br.svg',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+55',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [_phoneFormatter],
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(fontWeight: FontWeight.bold),
                              cursorColor: Colors.white,
                              decoration: InputDecoration(
                                filled: false,
                                isCollapsed: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                hintText: t.phone_verif_number_hint,
                                hintStyle: const TextStyle(color: Colors.white54),
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
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      color: context.colors.backgroundColor,
                      child: Text(
                        t.phone_verif_number_label,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              FloatingLabelDropdown<SendMethod>(
                label: "Método de envio",
                value: selectedMethod,
                items: sendMethods,
                onChanged: (method) {
                  setState(() {
                    selectedMethod = method;
                  });
                },
                itemIconBuilder:
                    (method) => SvgPicture.asset(
                      method.iconAsset,
                      width: 24,
                      height: 24,
                    ),
                itemLabelBuilder: (method) => method.name,
                borderColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),

              const SizedBox(height: 50),

              PrimaryButton(
                text: t.phone_verif_send_code,
                onPressed:
                    _isPhoneValid
                        ? () => context.go('/phone-verification/code')
                        : null,
                isEnabled: _isPhoneValid,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
