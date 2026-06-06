import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<bool> {
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityNotifier() : super(true) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final results = await _connectivity.checkConnectivity();

      state = results.any(
        (result) => result != ConnectivityResult.none,
      );

      _subscription = _connectivity.onConnectivityChanged.listen(
        (results) {
          final isOnline = results.any(
            (result) => result != ConnectivityResult.none,
          );

          if (isOnline != state) {
            state = isOnline;
          }
        },
        onError: (_) {
          state = false;
        },
      );
    } catch (_) {
      state = false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityServiceProvider);
});
