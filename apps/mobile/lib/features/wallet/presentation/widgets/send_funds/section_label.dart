import 'package:flutter/material.dart';

import 'send_flow_parts.dart';

/// Label above a part of the send form.
///
/// It draws a [SendSectionLabel], the label style of the send flow.
class SectionLabel extends StatelessWidget {
  final String label;

  const SectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) => SendSectionLabel(label);
}
