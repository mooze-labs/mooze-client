import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/models/sideswap.dart';
import 'package:mooze_mobile/providers/sideswap_repository_provider.dart';
import 'package:mooze_mobile/providers/peg_operation_provider.dart'; // Add this import
import 'package:mooze_mobile/screens/swap/widgets/peg_status.dart';
import 'package:mooze_mobile/widgets/appbar.dart';
import 'package:mooze_mobile/widgets/buttons.dart';

class CheckPegStatusScreen extends ConsumerStatefulWidget {
  final String? orderId; // Make nullable
  final bool? pegIn; // Make nullable

  const CheckPegStatusScreen({super.key, this.pegIn, this.orderId});

  @override
  ConsumerState<CheckPegStatusScreen> createState() =>
      _CheckPegStatusScreenState();
}

class _CheckPegStatusScreenState extends ConsumerState<CheckPegStatusScreen> {
  PegOrderStatus? pegOrderStatus;
  String? _orderId;
  bool? _isPegIn;
  late Future<PegOrderStatus?> _orderStatusFuture;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Use provided values if available, otherwise try to load from persistence
    if (widget.orderId != null && widget.pegIn != null) {
      _orderId = widget.orderId;
      _isPegIn = widget.pegIn;

      // Save for future use
      ref
          .read(activePegOperationProvider.notifier)
          .startPegOperation(_orderId!, _isPegIn!);
    } else {
      // Try to load from persistence
      final activeOp = await ref.read(activePegOperationProvider.future);

      if (activeOp != null) {
        _orderId = activeOp.orderId;
        _isPegIn = activeOp.isPegIn;
      }
    }

    if (_orderId != null && _isPegIn != null) {
      setState(() {
        _orderStatusFuture = getPegOrderStatus();
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active peg operation found')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<PegOrderStatus?> getPegOrderStatus() async {
    final sideswapClient = ref.read(sideswapRepositoryProvider);
    final pegOrderStatus = await sideswapClient.getPegStatus(
      _isPegIn!,
      _orderId!,
    );

    if (pegOrderStatus == null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ordem não encontrada')));

      // Clear the stored operation since it's no longer valid
      ref.read(activePegOperationProvider.notifier).completePegOperation();

      Navigator.of(context).pop();
    }

    if (mounted) {
      setState(() {
        this.pegOrderStatus = pegOrderStatus;
      });
    }

    return pegOrderStatus;
  }

  void refreshStatus() {
    setState(() {
      _orderStatusFuture = getPegOrderStatus();
    });
  }

  // The rest of your widget remains the same
  @override
  Widget build(BuildContext context) {
    if (_orderId == null || _isPegIn == null) {
      return Scaffold(
        appBar: MoozeAppBar(title: "Status de peg"),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Return your existing build method implementation
    return Scaffold(
      appBar: MoozeAppBar(title: "Status de peg"),
      body: FutureBuilder<PegOrderStatus?>(
        future: _orderStatusFuture,
        builder: (context, snapshot) {
          // Your existing builder code
          // Just update references from widget.orderId to _orderId and widget.pegIn to _isPegIn

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print(snapshot.error!);
            return const Center(child: Text('Erro ao conectar com servidor'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Nenhuma informação disponível'));
          }

          final PegOrderStatus pegOrder = snapshot.data!;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "ID da operação",
                                style: TextStyle(
                                  fontFamily: "roboto",
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${_orderId!.substring(0, 8)}...${_orderId!.substring(_orderId!.length - 8)}",
                                style: TextStyle(
                                  fontFamily: "roboto",
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Tipo de operação",
                                style: TextStyle(
                                  fontFamily: "roboto",
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _isPegIn! ? "Peg-in" : "Peg-out",
                                style: TextStyle(
                                  fontFamily: "roboto",
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (pegOrder.transactions.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemBuilder: (context, index) {
                          return PegStatus(
                            pegTransaction: pegOrder.transactions[index],
                          );
                        },
                        itemCount: pegOrder.transactions.length,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _orderId!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontSize: 14.5,
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _orderId!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "ID copiado para a área de transferência",
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.content_copy_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  PrimaryButton(text: "Atualizar", onPressed: refreshStatus),
                  SizedBox(height: 70),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
