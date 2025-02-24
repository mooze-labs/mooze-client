import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/liquid/wallet_provider.dart';
import 'package:mooze_mobile/widgets/asset_selector.dart';

class ReceiveFundsScreen extends ConsumerStatefulWidget {
  const ReceiveFundsScreen({Key? key}) : super(key: key);

  @override
  _ReceiveFundsScreenState createState() => _ReceiveFundsScreenState();
}

class _ReceiveFundsScreenState extends ConsumerState<ReceiveFundsScreen>
    with SingleTickerProviderStateMixin {
  String? _address;
  String? _selectedAssetId;
  double? _amount;
  bool _isLoading = false;

  final Map<String, Map<String, String>> assetDetails = {
    '6f0279e9ed041c3d710a9f57d0c02928416460c4b722ae3457a11eec381c526d': {
      'name': 'Liquid Bitcoin',
      'logo': 'assets/lbtc-logo.png',
    },
    '02f22f8d9c76ab41661a2729e4752e2c5d1a263012141b86ea98af5472df5189': {
      'name': 'Depix',
      'logo': 'assets/depix-logo.png',
    },
    'ce091c998b83c78bb71a632313ba3760f1763d9cfcffae02258ffa9865a37bd2': {
      'name': 'USDt',
      'logo': 'assets/usdt-logo.png',
    },
  };

  Future<void> _generateAddress() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final address = await ref
          .read(liquidWalletNotifierProvider.notifier)
          .generateAddress();
      setState(() {
        _address = address;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Erro ao gerar endereço: $e");
    }
  }

  void _copyToClipboard() {
    final qrData = _generateQRData();
    if (qrData != null) {
      Clipboard.setData(ClipboardData(text: qrData));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Endereço copiado para a área de transferência!")),
      );
    }
  }

  void _shareAddress() {
    final qrData = _generateQRData();
    if (qrData != null) {
      Share.share(qrData);
    }
  }

  void _showFullScreenQR() {
    final qrData = _generateQRData();
    if (qrData != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => FullScreenQR(qrData: qrData),
          transitionsBuilder: (_, animation, __, child) {
            return ScaleTransition(
              scale: Tween(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
              child: child,
            );
          },
        ),
      );
    }
  }

  String? _generateQRData() {
    if (_address == null || _selectedAssetId == null || _amount == null) {
      return null;
    }
    return 'liquidnetwork:$_address?asset_id=$_selectedAssetId&amount=${_amount!.toStringAsFixed(8)}';
  }

  @override
  void initState() {
    super.initState();
    _generateAddress();
  }

  @override
  Widget build(BuildContext context) {
    final qrData = _generateQRData();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Receber"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareAddress,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AssetSelector(
                selectedAssetId: _selectedAssetId,
                assetDetails: assetDetails,
                onChanged: (value) {
                  setState(() {
                    _selectedAssetId = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFD973C1)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _amount = double.tryParse(value);
                  });
                },
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _showFullScreenQR,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : (qrData != null)
                          ? QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 150,
                              gapless: false,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Colors.black,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.circle,
                                color: Colors.black,
                              ),
                            )
                          : const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 20),
              if (qrData != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        qrData,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white),
                      onPressed: _copyToClipboard,
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class FullScreenQR extends StatelessWidget {
  final String qrData;

  const FullScreenQR({Key? key, required this.qrData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: MediaQuery.of(context).size.width * 0.8,
            gapless: false,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.circle,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
