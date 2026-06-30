import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';

import 'section_header.dart';
import 'transaction_list.dart';

class TransactionSection extends StatelessWidget {
  const TransactionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      children: [
        SectionHeader(
          onAction: () => (context.push('/transactions-history')),
          title: t.wallet_transactions_section_title,
          actionDescription: t.wallet_section_see_more,
        ),
        const SizedBox(height: 10),
        TransactionList(),
      ],
    );
  }
}
