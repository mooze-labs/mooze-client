import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets.dart';

class SettingsMenuScreen extends StatelessWidget {
  const SettingsMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Configurações"),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        children: [
          MenuItem(
            icon: Icons.key,
            title: "Frase de recuperação",
            onTap: () {},
          ),
          MenuItem(icon: Icons.lock, title: "Mudar PIN", onTap: () {}),
          MenuItem(
            icon: Icons.currency_exchange,
            title: "Mudar moeda",
            onTap: () {},
          ),
          MenuItem(
            icon: Icons.card_giftcard,
            title: "Inserir cupom de indicação",
            onTap: () {},
          ),
          MenuItem(
            icon: Icons.description,
            title: "Termos de uso",
            onTap: () {},
          ),
          MenuItem(icon: Icons.gavel, title: "Ver licença", onTap: () {}),
          MenuItem(
            icon: Icons.support_agent,
            title: "Contatar suporte",
            onTap: () {},
          ),
          MenuItem(
            icon: Icons.delete_forever,
            title: "Deletar carteira",
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
