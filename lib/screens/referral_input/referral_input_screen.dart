import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/buttons.dart';
import '../../services/mooze/referral.dart';
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

class _ReferralInputScreenState extends State<ReferralInputScreen> {
  final TextEditingController _referralCodeController = TextEditingController();
  final ReferralService _referralService = ReferralService(
    backendUrl: BACKEND_URL,
  );
  final UserService _userService = UserService(backendUrl: BACKEND_URL);
  String? _existingReferralCode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingReferralCode();
  }

  Future<void> _checkExistingReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    final existingCode = prefs.getString('referralCode');

    // Check if user already has a referral in their user details
    final userDetails = await _userService.getUserDetails();
    if (userDetails?.referredBy != null) {
      setState(() {
        _existingReferralCode = userDetails!.referredBy;
      });
      return;
    }

    // Fallback to checking SharedPreferences
    if (existingCode != null) {
      setState(() {
        _existingReferralCode = existingCode;
      });
    }
  }

  @override
  void dispose() {
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _validateReferralCode() async {
    final referralCode = _referralCodeController.text.trim().toUpperCase();
    if (referralCode.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final isValid = await _referralService.validateReferralCode(referralCode);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (isValid) {
      // Save the valid referral code to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('referralCode', referralCode);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código de indicação válido! Desconto aplicado.'),
          backgroundColor: Colors.green,
        ),
      );
      await _checkExistingReferralCode();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O código inserido é inválido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Código de Indicação')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Caso tenha um código de indicação, digite-o aqui. O uso de um código de indicação te dá até 15% de desconto nas taxas',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            if (_existingReferralCode != null)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Desconto aplicado',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Código: $_existingReferralCode',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              TextField(
                controller: _referralCodeController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  hintText: 'Digite o código de indicação',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 24),
            if (_existingReferralCode == null)
              PrimaryButton(
                onPressed: () => _validateReferralCode(),
                text: _isLoading ? 'Validando...' : 'Validar código',
              ),
          ],
        ),
      ),
    );
  }
}
