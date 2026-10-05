import 'package:flutter/widgets.dart';

import 'protected_screen_gate.dart';
import 'screen_security_controller.dart';

class SecureScreen extends StatefulWidget {
  const SecureScreen({
    super.key,
    required this.child,
    this.showSecurityNotice = false,
  });

  final Widget child;

  final bool showSecurityNotice;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  bool get _gated => widget.showSecurityNotice;

  @override
  void initState() {
    super.initState();
    if (!_gated) ScreenSecurityController.instance.enable();
  }

  @override
  void dispose() {
    if (!_gated) ScreenSecurityController.instance.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _gated ? ProtectedScreenGate(child: widget.child) : widget.child;
}
