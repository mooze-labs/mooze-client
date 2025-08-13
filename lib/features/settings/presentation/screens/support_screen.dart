import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/shared/widgets/buttons/primary_button.dart';
import 'package:url_launcher/url_launcher.dart';

class MockUserService { // TODO: REMOVE MOCK
  Future<String> getUserId() async {
    await Future.delayed(const Duration(seconds: 1));
    return '8ef2afe3b57e4405f0c1c48c3c8a13b2383016f6172aebb3841eaeb2139d0984';
  }
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  bool _codeCopied = false;
  late Future<String> _userIdFuture;

  @override
  void initState() {
    super.initState();
    _userIdFuture = MockUserService().getUserId();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Central de Suporte'),
        leading: IconButton(
          onPressed: () => context.go('/settings'),
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.1),
                            colorScheme.secondary.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Icon(
                              Icons.support_agent_rounded,
                              size: 32,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Como podemos ajudar?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Para um atendimento mais eficiente, compartilhe o código abaixo com nosso suporte.',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.7,
                              ),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Seu código de identificação',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    FutureBuilder<String>(
                      future: _userIdFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.outline.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final userId = snapshot.data ?? 'Erro ao carregar';
                        final hasError = !snapshot.hasData;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color:
                                hasError
                                    ? colorScheme.errorContainer.withValues(
                                      alpha: 0.1,
                                    )
                                    : _codeCopied
                                    ? colorScheme.primaryContainer.withValues(
                                      alpha: 0.3,
                                    )
                                    : colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  hasError
                                      ? colorScheme.error.withValues(alpha: 0.3)
                                      : _codeCopied
                                      ? colorScheme.primary.withValues(
                                        alpha: 0.3,
                                      )
                                      : colorScheme.outline.withValues(
                                        alpha: 0.2,
                                      ),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withValues(
                                  alpha: 0.05,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      hasError
                                          ? Icons.error_outline_rounded
                                          : _codeCopied
                                          ? Icons.check_circle_outline_rounded
                                          : Icons.fingerprint_rounded,
                                      color:
                                          hasError
                                              ? colorScheme.error
                                              : _codeCopied
                                              ? colorScheme.primary
                                              : colorScheme.primary.withValues(
                                                alpha: 0.7,
                                              ),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        hasError
                                            ? 'Erro ao carregar código'
                                            : _codeCopied
                                            ? 'Código copiado!'
                                            : 'Código de identificação',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SelectableText(
                                  userId,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace',
                                    color:
                                        hasError
                                            ? colorScheme.error
                                            : colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (!hasError)
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        await Clipboard.setData(
                                          ClipboardData(text: userId),
                                        );
                                        setState(() {
                                          _codeCopied = true;
                                        });
                                        Future.delayed(
                                          const Duration(seconds: 3),
                                          () {
                                            if (mounted) {
                                              setState(() {
                                                _codeCopied = false;
                                              });
                                            }
                                          },
                                        );
                                      },
                                      icon: Icon(
                                        _codeCopied
                                            ? Icons.check
                                            : Icons.copy_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        _codeCopied
                                            ? 'Copiado!'
                                            : 'Copiar código',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            _codeCopied
                                                ? colorScheme.primary
                                                : colorScheme.onSurface,
                                        side: BorderSide(
                                          color:
                                              _codeCopied
                                                  ? colorScheme.primary
                                                      .withValues(alpha: 0.3)
                                                  : colorScheme.outline
                                                      .withValues(alpha: 0.3),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Nosso time de suporte está disponível 24/7 para ajudá-lo com qualquer dúvida ou problema.',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onPrimary.withValues(
                                  alpha: 0.7,
                                ),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Column(
              children: [
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Falar com o suporte',
                  onPressed: () async {
                    final Uri url = Uri.parse("https://t.me/Moozep2pbot");
                    try {
                      final launched = await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!launched && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Não foi possível abrir o Telegram",
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Erro ao tentar abrir o Telegram: $e",
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
