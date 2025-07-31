import 'package:flutter/material.dart';

import '../consts.dart';

import 'section_header.dart';
import 'transaction_list.dart';

class TransactionSection extends StatelessWidget {
  const TransactionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(onAction: () => (), title: "Transações", actionDescription: "Ver mais"),
        const SizedBox(width: 16.0),
        TransactionList()
      ],
    );
  }
}