import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../widgets.dart';

class SelectNetworkBitcoinScreen extends ConsumerWidget {
  const SelectNetworkBitcoinScreen({super.key, required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Como você quer receber?',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          onPressed: () {
            context.replace('/menu');
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PaymentMethod(
            title: "On-chain (bitcoin)",
            subtitle: "Receba na rede padrão do Bitcoin",
            icon: const Icon(
              Icons.currency_bitcoin,
              size: 24,
              color: Color(0xFFF7931A),
            ),
            onTap: () {},
          ),
          PaymentMethod(
            title: "Liquid (confidencial)",
            subtitle: "Receba com mais privacidade na rede Liquid",
            icon: const Icon(Icons.water_drop, size: 24, color: Colors.green),
            onTap: () {},
          ),
          PaymentMethod(
            title: "Lightning",
            subtitle: "Receba instantaneamente com taxas quase zero",
            icon: const Icon(Icons.bolt, size: 24, color: Colors.amberAccent),
            onTap: () {},
          ),
          PaymentMethod(
            title: "PIX",
            subtitle: "Receba com PIX via sistema bancário brasileiro",
            icon: SvgPicture.asset(
              "assets/images/icons/pix-brands-solid.svg",
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                Colors.greenAccent,
                BlendMode.srcIn,
              ),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
