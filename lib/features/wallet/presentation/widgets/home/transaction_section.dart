import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'section_header.dart';
import 'transaction_list.dart';

class TransactionSection extends StatelessWidget {
  const TransactionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          onAction: () => (context.push('/transactions-history')),
          title: "Transações",
          actionDescription: "Ver mais",
        ),
        TransactionList(),
      ],
    );
  }
}
