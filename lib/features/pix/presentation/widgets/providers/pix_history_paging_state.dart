import 'package:flutter_riverpod/flutter_riverpod.dart';

class PixHistoryPagingNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void nextPage() => state + 50;
  void reset() => state = 0;
}

final pixHistoryPagingNotifier =
    NotifierProvider<PixHistoryPagingNotifier, int>(
      PixHistoryPagingNotifier.new,
    );
