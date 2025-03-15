import 'package:flutter/material.dart';

class MoozeDrawer extends StatelessWidget {
  const MoozeDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.black,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [Image.asset('assets/images/mooze-logo.png')],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.history, color: Colors.white),
              title: const Text(
                "Carteira",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/wallet");
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.white),
              title: const Text(
                "Transações",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/transactions");
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text(
                "Configurações",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/settings");
              },
            ),
          ],
        ),
      ),
    );
  }
}
