import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';
import 'package:mooze_mobile/features/wallet/presentation/providers/send_funds/network_detection_provider.dart';

class ReceiveQRScreen extends ConsumerStatefulWidget {
  final String qrData;
  final String displayAddress;
  final Asset asset;
  final NetworkType network;
  final double? amount;
  final String? description;

  const ReceiveQRScreen({
    super.key,
    required this.qrData,
    required this.displayAddress,
    required this.asset,
    required this.network,
    this.amount,
    this.description,
  });

  @override
  ConsumerState<ReceiveQRScreen> createState() => _ReceiveQRScreenState();
}

class _ReceiveQRScreenState extends ConsumerState<ReceiveQRScreen>
    with SingleTickerProviderStateMixin {
  bool _isCopied = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Receber Pagamento"),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildPaymentInfo(),

              const SizedBox(height: 10),

              _buildQRCode(),

              const SizedBox(height: 20),

              _buildAddressSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    widget.asset.iconPath,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.asset.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getNetworkLabel(widget.network),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (widget.amount != null) ...[
            const SizedBox(height: 16),
            Text(
              'Valor:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              '${widget.amount} ${widget.asset.ticker}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],

          if (widget.description != null && widget.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Descrição:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              widget.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.network == NetworkType.lightning
                      ? Icons.flash_on_rounded
                      : Icons.link_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.network == NetworkType.lightning
                      ? 'Lightning Invoice'
                      : 'Endereço de Recebimento',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: SelectableText(
              _getCleanAddress(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: ElevatedButton(
                onPressed: _copyAddressToClipboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isCopied
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isCopied ? 0 : 2,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Row(
                    key: ValueKey(_isCopied),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCopied ? Icons.check_rounded : Icons.copy_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCopied ? 'Copiado!' : 'Copiar Endereço',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: PrettyQrView.data(data: widget.qrData),
    );
  }

  void _copyAddressToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _getCleanAddress()));

    setState(() {
      _isCopied = true;
    });

    _animationController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
        _animationController.reverse();
      }
    });
  }

  String _getCleanAddress() {
    if (widget.network == NetworkType.liquid) {
      String address = widget.displayAddress;

      if (address.startsWith('liquidnetwork:')) {
        address = address.substring('liquidnetwork:'.length);
      }

      final queryIndex = address.indexOf('?');
      if (queryIndex != -1) {
        address = address.substring(0, queryIndex);
      }

      return address;
    }

    if (widget.network == NetworkType.bitcoin) {
      String address = widget.displayAddress;

      if (address.startsWith('bitcoin:')) {
        address = address.substring('bitcoin:'.length);
      }

      final queryIndex = address.indexOf('?');
      if (queryIndex != -1) {
        address = address.substring(0, queryIndex);
      }

      return address;
    }

    return widget.displayAddress;
  }

  void _shareQRCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compartilhamento não implementado')),
    );
  }

  String _getNetworkLabel(NetworkType network) {
    return switch (network) {
      NetworkType.bitcoin => 'Bitcoin On-chain',
      NetworkType.lightning => 'Lightning Network',
      NetworkType.liquid => 'Liquid Network',
      NetworkType.unknown => 'Desconhecida',
    };
  }
}
