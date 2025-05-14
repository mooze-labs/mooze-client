import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/providers/fiat/fiat_provider.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class MoozeDrawer extends ConsumerWidget {
  const MoozeDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the current route name
    final String currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    final fiatPrices = ref.watch(fiatPricesProvider);

    return Drawer(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Image.asset('assets/images/mooze-logo.png'),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: fiatPrices.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (err, stack) => const Text(
                      "Preço não disponível",
                      style: TextStyle(color: Colors.grey),
                    ),
                data: (prices) {
                  if (!prices.containsKey("bitcoin")) {
                    return const Text(
                      "Preço não disponível",
                      style: TextStyle(color: Colors.grey),
                    );
                  }
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: Text(
                      "1 BTC: R\$ ${prices["bitcoin"]!.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
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
            _buildDrawerDivider(context),
            _buildDrawerUrlItem(
              context,
              Icons.monetization_on,
              "Saque de Depix",
              "https://tally.so/r/w5EMVb",
            ),
            _buildDrawerUrlItem(
              context,
              Icons.data_usage,
              "Central de dados",
              "https://keepo.io/mooze.app/",
            ),
            _buildDrawerUrlItem(
              context,
              SimpleIcons.github,
              "Github",
              "https://github.com/mooze-labs",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Divider(
        color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.3),
        thickness: 1,
      ),
    );
  }

  Widget _buildDrawerUrlItem(
    BuildContext context,
    IconData icon,
    String title,
    String url,
  ) {
    final Color itemColor = Theme.of(context).colorScheme.onSecondary;

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
          style: TextStyle(color: itemColor, fontWeight: FontWeight.normal),
        ),
        trailing: Icon(Icons.open_in_new, size: 16, color: itemColor),
        onTap: () async {
          Navigator.pop(context);
          try {
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Não foi possível abrir o link")),
              );
            }
          }
        },
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
    final Color itemColor =
        isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSecondary;

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
          style: TextStyle(
            color: itemColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
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
