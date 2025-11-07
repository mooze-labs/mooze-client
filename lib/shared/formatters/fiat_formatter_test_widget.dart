import 'package:flutter/material.dart';
import 'package:mooze_mobile/shared/formatters/fiat_input_formatter.dart';

class FiatFormatterTestWidget extends StatefulWidget {
  const FiatFormatterTestWidget({super.key});

  @override
  State<FiatFormatterTestWidget> createState() =>
      _FiatFormatterTestWidgetState();
}

class _FiatFormatterTestWidgetState extends State<FiatFormatterTestWidget> {
  final _controller = TextEditingController(text: '0,00');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teste Formatador Fiat')),
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
              '- Inicial: 0,00\n'
              '- Digita "1": 0,01\n'
              '- Digita "2": 0,12\n'
              '- Digita "3": 1,23\n'
              '- Digita "4": 12,34\n'
              '- Digita "5": 123,45\n'
              '- Digita "6": 1.234,56\n'
              '- E assim por diante...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              inputFormatters: [FiatInputFormatter()],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Valor em Reais',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixText: 'R\$ ',
                prefixStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, value, child) {
                final fiatValue = FiatInputFormatter.parseValue(value.text);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Valores:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Valor formatado: R\$ ${value.text}'),
                        Text('Valor numérico: $fiatValue'),
                        Text('Texto raw: ${value.text}'),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Exemplos de formatação:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${FiatInputFormatter.formatValue(0.01)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${FiatInputFormatter.formatValue(1.23)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${FiatInputFormatter.formatValue(1234.56)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${FiatInputFormatter.formatValue(1000000.00)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _controller.text = '0,00';
                      });
                    },
                    child: const Text('Resetar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _controller.text = FiatInputFormatter.formatValue(
                          1234.56,
                        );
                      });
                    },
                    child: const Text('Testar 1.234,56'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
