import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/themes/theme_context_x.dart';
import '../widgets/currency/currency_list.dart';

class CurrencySelectorScreen extends ConsumerStatefulWidget {
  const CurrencySelectorScreen({super.key});

  @override
  ConsumerState<CurrencySelectorScreen> createState() =>
      _CurrencySelectorScreenState();
}

class _CurrencySelectorScreenState
    extends ConsumerState<CurrencySelectorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Moeda'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Moeda de exibição',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Escolha a moeda usada para exibir preços e valores em todo o app.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: colorScheme.onSurface.withValues(alpha: 0.08)),
                  ],
                ),
              ),
              const Expanded(child: CurrencyList()),
            ],
          ),
        ),
      ),
    );
  }
}
