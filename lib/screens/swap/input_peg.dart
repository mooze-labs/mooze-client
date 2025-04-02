import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/screens/swap/check_peg_status.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/buttons.dart';
import 'package:mooze_mobile/widgets/mooze_drawer.dart';

class InputPegScreen extends ConsumerStatefulWidget {
  const InputPegScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InputPegScreen> createState() => _InputPegScreenState();
}

class _InputPegScreenState extends ConsumerState<InputPegScreen> {
  final TextEditingController orderIdController = TextEditingController();
  Set<bool> pegIn = {true}; // default to peg-in

  @override
  void dispose() {
    orderIdController.dispose();
    super.dispose();
  }

  void _checkPegStatus() {
    final orderId = orderIdController.text.trim();

    if (orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, digite o ID da ordem'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                CheckPegStatusScreen(pegIn: pegIn.first, orderId: orderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MoozeAppBar(title: "Consultar Peg"),
      drawer: MoozeDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Center(
              child: SegmentedButton(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text("Peg-in"),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text("Peg-out"),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return Theme.of(context).colorScheme.primary;
                    }
                    return Theme.of(context).colorScheme.secondary;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return Theme.of(context).colorScheme.onPrimary;
                    }
                    return Theme.of(context).colorScheme.onSecondary;
                  }),
                ),
                selected: pegIn,
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    pegIn = newSelection;
                  });
                },
              ),
            ),
            const SizedBox(height: 48),

            Text(
              "ID da Ordem:",
              style: TextStyle(
                fontFamily: "roboto",
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.transparent),
              ),
              child: TextField(
                controller: orderIdController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Digite o ID da ordem de peg",
                  hintStyle: TextStyle(
                    fontFamily: "roboto",
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                style: const TextStyle(fontSize: 16, fontFamily: "roboto"),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              "O ID da ordem é fornecido quando você inicia uma operação de peg-in ou peg-out.",
              style: TextStyle(
                fontFamily: "roboto",
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),

            const Spacer(),

            Center(
              child: PrimaryButton(
                text: "Verificar Status",
                onPressed: _checkPegStatus,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
