import 'package:flutter/material.dart';

class MoozeDrawer extends StatelessWidget {
  const MoozeDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the current route name
    final String currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    return Drawer(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [Image.asset('assets/images/mooze-logo.png')],
              ),
            ),
            _buildDrawerItem(
              context,
              Icons.wallet,
              "Carteira",
              "/wallet",
              currentRoute == "/wallet",
            ),
            _buildDrawerItem(
              context,
              Icons.history,
              "Transações",
              "/transaction_history",
              currentRoute == "/transaction_history",
            ),
            _buildDrawerItem(
              context,
              Icons.store,
              "Modo Comerciante",
              "/store_mode",
              currentRoute == "/store_mode",
            ),
            _buildDrawerItem(
              context,
              Icons.settings,
              "Configurações",
              "/settings",
              currentRoute == "/settings",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
    bool isActive,
  ) {
    // Define colors based on active state
    final Color itemColor = isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSecondary;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: itemColor),
        title: Text(
          title,
          style: TextStyle(color: itemColor, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
        ),
        onTap: () {
          Navigator.pop(context);

          // Only navigate if we're not already on this route
          if (!isActive) {
            Navigator.pushNamed(context, route);
          }
        },
      ),
    );
  }
}
