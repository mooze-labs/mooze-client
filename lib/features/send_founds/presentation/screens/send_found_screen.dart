import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/features/send_founds/data/asset_data_screen.dart';
import 'package:mooze_mobile/features/send_founds/presentation/widgets/address_modal.dart';
import 'package:mooze_mobile/features/send_founds/presentation/widgets/amout_%20modal.dart';
import 'package:mooze_mobile/features/send_founds/presentation/widgets/asset_selector_widget.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:mooze_mobile/themes/app_colors.dart';

class SendFoundScreen extends StatefulWidget {
  const SendFoundScreen({super.key});

  @override
  State<SendFoundScreen> createState() => _SendFoundScreenState();
}

class _SendFoundScreenState extends State<SendFoundScreen> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();

  final List<SendFoundScreenData> _assets = [
    SendFoundScreenData(
      id: 'bitcoin',
      name: 'Bitcoin',
      symbol: 'BTC',
      icon: 'assets/new_ui_wallet/assets/icons/asset/bitcoin.svg',
      amount: 0,
    ),
    SendFoundScreenData(
      id: 'bitcoin-liquid',
      name: 'Bitcoin Liquid',
      symbol: 'LBTC',
      icon: 'assets/new_ui_wallet/assets/icons/asset/lbtc.svg',
      amount: 0.0021,
    ),
    SendFoundScreenData(
      id: 'dpix',
      name: 'DPIX',
      symbol: 'DPIX',
      icon: 'assets/new_ui_wallet/assets/icons/asset/depix.svg',
      amount: 21,
    ),
    SendFoundScreenData(
      id: 'usdt',
      name: 'Tether',
      symbol: 'USDT',
      icon: 'assets/new_ui_wallet/assets/icons/asset/tether.svg',
      amount: 10,
    )
  ];

  late SendFoundScreenData _selectedAsset;
  String _amount = '';

  @override
  void initState() {
    super.initState();
    _selectedAsset = _assets.first;
    _checkClipboard();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null && _isValidAddress(data!.text!)) {
        _showPasteSnackBar(data.text!);
      }
    } catch (_) {}
  }

  bool _isValidAddress(String address) =>
      address.trim().isNotEmpty && address.length >= 10;

  void _showPasteSnackBar(String clipboardText) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Colar endereço da área de transferência?', style:  Theme.of(context).textTheme.bodyLarge,),
        backgroundColor: AppColors.primaryColor,
        action: SnackBarAction(
          label: 'COLAR',
          textColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () {
            setState(() {
              _addressController.text = clipboardText;
            });
          },
        ),
      ),
    );
  }

  void _openQRScanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Abrindo scanner QR...'),
        backgroundColor: Color(0xFF374151),
      ),
    );
  }

  void _showAmountModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AmountModal(
            onAmountSet: (amount) => setState(() => _amount = amount),
          ),
    );
  }

  void _onAssetChanged(SendFoundScreenData? asset) {
    if (asset != null) setState(() => _selectedAsset = asset);
  }

  void _onMaxPressed() {
    setState(() {
      _amount = _selectedAsset.amount.toString();
    });
  }

  void _onReviewTransaction() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Navegando para revisão da transação...'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios),
        onPressed: () => context.go("/"),
      ),
      title: const Text(
        'Enviar Bitcoin',
      ),
    );
  }

  Widget _buildInstructionText() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyLarge,
        children: [
          const TextSpan(text: 'Escolha o ativo que deseja receber na '),
          TextSpan(
            text: 'Mooze.',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.pinBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      child: Column(
        children: [
          Text(
            'Saldo disponível',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '${_selectedAsset.amount} ${_selectedAsset.symbol}',
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 4),
          Text(
            '1.409,11 BRL',
            style: Theme.of(context).textTheme.titleMedium!        
          ),
        ],
      ),
    );
  }

  void _openAddressInputModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => AddressModal(
            initialAddress: _addressController.text,
            onAddressSet: (newAddress) {
              setState(() {
                _addressController.text = newAddress;
              });
            },
          ),
    );
  }

  Widget _buildAddressField() {
    final displayedText = _formatAddress(_addressController.text);

    return GestureDetector(
      onTap: _openAddressInputModal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 5).copyWith(left: 12),
        decoration: BoxDecoration(
          color: AppColors.pinBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayedText.isEmpty
                    ? 'Digite o endereço aqui'
                    : displayedText,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            IconButton(
              onPressed: _openQRScanner,
              icon: Icon(
                Icons.qr_code_scanner,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAddress(String address) {
    if (address.isEmpty) return '';
    if (address.length <= 12) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
  }

  Widget _buildAmountSelector() {
    return GestureDetector(
      onTap: _showAmountModal,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pinBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SvgPicture.asset(_selectedAsset.icon, width: 21, height: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _amount.isEmpty
                    ? 'Definir quantia em ${_selectedAsset.symbol}'
                    : '$_amount ${_selectedAsset.symbol}',
                style: Theme.of(context).textTheme.bodyLarge!,
              ),
            ),
            GestureDetector(
              onTap: _onMaxPressed,
              child: Text(
                'MAX',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewButton() {
    final isEnabled =
        _addressController.text.trim().isNotEmpty && _amount.isNotEmpty;

    return PrimaryButton(
      text: 'Revisar Transação',
      onPressed: _onReviewTransaction,
      isEnabled: isEnabled,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
        ).copyWith(top: 10, bottom: 24),
        child: Column(
          children: [
            _buildInstructionText(),
            const SizedBox(height: 30),
            AssetSelectorWidget(
              selectedAsset: _selectedAsset,
              assets: _assets,
              onAssetChanged: _onAssetChanged,
            ),
            const SizedBox(height: 30),
            _buildBalanceCard(),
            const Spacer(),
            _buildAddressField(),
            const SizedBox(height: 15),
            _buildAmountSelector(),
            const Spacer(),
            _buildReviewButton(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
