import 'package:flutter_riverpod/flutter_riverpod.dart';

const bool _kPixCpfRequired = true;
final pixCpfRequiredProvider = Provider<bool>((ref) => _kPixCpfRequired);
