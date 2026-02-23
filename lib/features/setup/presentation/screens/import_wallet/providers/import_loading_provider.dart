import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to track the loading state of the import button.
final importLoadingProvider = StateProvider<bool>((ref) => false);
