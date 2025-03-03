import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mooze_mobile/widgets/buttons.dart';

class FirstAccessScreen extends StatelessWidget {
  const FirstAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextStyle defaultStyle = TextStyle(color: Colors.white, fontSize: 16.0);
    TextStyle linkStyle = TextStyle(color: Colors.pinkAccent, fontSize: 16.0);

    final buttons = Column(
      children: [
        PrimaryButton(
          text: "Negociar agora",
          onPressed: () {
            Navigator.pushNamed(context, '/create_wallet');
          },
          icon: Icons.swap_horiz,
        ),
        SizedBox(height: 20),
        TertiaryButton(
          text: "Criar carteira",
          onPressed: () {
            Navigator.pushNamed(context, '/create_wallet');
          },
          icon: Icons.wallet_rounded,
        ),
        SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Já tem uma carteira? ", style: defaultStyle),
            InkWell(
              onTap: () => Navigator.pushNamed(context, "/import_wallet"),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Importe-a.", style: linkStyle),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: linkStyle.color),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    final body = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/mooze-logo.png', width: 200, height: 200),
          SizedBox(height: 50),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(children: [buttons]),
          ),
        ],
      ),
    );

    return Scaffold(backgroundColor: Color(0xFF14181B), body: body);
  }
}
