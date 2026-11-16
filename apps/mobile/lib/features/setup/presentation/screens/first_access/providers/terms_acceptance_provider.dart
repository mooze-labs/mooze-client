import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the user checked the terms on the first access screen.
///
/// It lives as long as that screen: the setup steps open over it, so the
/// check stays while the user goes forward and back. Once the setup ends
/// and the screen leaves, it resets, so a wallet deleted later in the same
/// session meets the terms unchecked again.
final termsAcceptanceProvider = StateProvider.autoDispose<bool>((ref) => false);
