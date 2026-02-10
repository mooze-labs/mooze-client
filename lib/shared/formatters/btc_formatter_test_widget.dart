import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/formatters/btc_input_formatter.dart';

class BtcFormatterTestWidget extends StatefulWidget {
  const BtcFormatterTestWidget({super.key});

  @override
  State<BtcFormatterTestWidget> createState() => _BtcFormatterTestWidgetState();
}

class _BtcFormatterTestWidgetState extends State<BtcFormatterTestWidget> {
  final _controller = TextEditingController(text: '0.00000000');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teste Formatador BTC')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Digite números e veja o formatador em ação:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Comportamento esperado:\n'
              '- Inicial: 0.00000000\n'
              '- Digita "1": 0.00000001\n'
              '- Digita "2": 0.00000012\n'
              '- Digita "3": 0.00000123\n'
              '- E assim por diante...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              inputFormatters: [BtcInputFormatter()],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Valor BTC',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixText: 'BTC',
              ),
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, value, child) {
                final btcValue = BtcInputFormatter.parseValue(value.text);
                final sats = (btcValue * 100000000).round();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Valores convertidos:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('BTC: $btcValue'),
                        Text('Satoshis: $sats'),
                        Text('Texto raw: ${value.text}'),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _controller.text = '0.00000000';
                });
              },
              child: const Text('Resetar'),
            ),
          ],
        ),
      ),
    );
  }
}
