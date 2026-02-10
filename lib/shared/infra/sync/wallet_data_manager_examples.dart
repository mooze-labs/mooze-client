import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/shared/infra/sync/wallet_data_manager.dart';

class WalletSyncStatusWidget extends ConsumerWidget {
  const WalletSyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletStatus = ref.watch(walletDataManagerProvider);
    final lastSync = ref.watch(lastSyncTimeProvider);

    if (walletStatus.isInitialLoad) {
      return const CircularProgressIndicator();
    }

    if (walletStatus.hasError) {
      return Column(
        children: [
          Icon(Icons.error, color: Colors.red),
          Text('Erro: ${walletStatus.errorMessage}'),
          ElevatedButton(
            onPressed: () {
              ref.read(walletDataManagerProvider.notifier).refreshWalletData();
            },
            child: Text('Tentar novamente'),
          ),
        ],
      );
    }

    return Row(
      children: [
        if (walletStatus.isLoadingOrRefreshing)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        if (lastSync != null) ...[
          Icon(Icons.sync, size: 16),
          SizedBox(width: 4),
          Text(
            'Última sync: ${_formatTime(lastSync)}',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min atrás';
    } else {
      return '${difference.inHours}h atrás';
    }
  }
}

class WalletRefreshIndicator extends ConsumerWidget {
  final Widget child;

  const WalletRefreshIndicator({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        final walletDataManager = ref.read(walletDataManagerProvider.notifier);
        await walletDataManager.refreshWalletData();
      },
      child: child,
    );
  }
}

class WalletLoadingIndicator extends ConsumerWidget {
  const WalletLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(isLoadingDataProvider);

    if (!isLoading) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 3,
        child: LinearProgressIndicator(
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}

class ExampleWalletScreen extends ConsumerStatefulWidget {
  const ExampleWalletScreen({super.key});

  @override
  ConsumerState<ExampleWalletScreen> createState() =>
      _ExampleWalletScreenState();
}

class _ExampleWalletScreenState extends ConsumerState<ExampleWalletScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletStatus = ref.read(walletDataManagerProvider);
      if (walletStatus.state == WalletDataState.idle) {
        ref.read(walletDataManagerProvider.notifier).initializeWallet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carteira'),
        actions: [WalletSyncStatusWidget(), const SizedBox(width: 16)],
      ),
      body: Stack(
        children: [
          WalletRefreshIndicator(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          WalletLoadingIndicator(),
        ],
      ),
    );
  }
}
