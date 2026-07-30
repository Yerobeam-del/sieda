import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool get isOnline => _isOnline;

  ConnectivityService() {
    _init();
  }

  void _init() {
    _connectivity.checkConnectivity().then((result) {
      _isOnline = !result.contains(ConnectivityResult.none);
      notifyListeners();
    });

    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final online = !result.contains(ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        debugPrint('[Connectivity] ${online ? "ONLINE" : "OFFLINE"}');
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
