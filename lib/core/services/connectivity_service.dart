import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus { online, offline, unknown }

class ConnectivityService {
  static ConnectivityService? _instance;
  static ConnectivityService get instance =>
      _instance ??= ConnectivityService._();

  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final _statusController = StreamController<NetworkStatus>.broadcast();
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  NetworkStatus _currentStatus = NetworkStatus.unknown;
  NetworkStatus get currentStatus => _currentStatus;

  bool get isOnline => _currentStatus == NetworkStatus.online;
  bool get isOffline => _currentStatus == NetworkStatus.offline;

  final List<Function> _listeners = [];
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> initialize() async {
    await _checkConnection();

    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }

  Future<NetworkStatus> _checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final status = _mapConnectivityResult(results);
      _updateStatus(status);
      return status;
    } catch (e) {
      _updateStatus(NetworkStatus.unknown);
      return NetworkStatus.unknown;
    }
  }

  NetworkStatus _mapConnectivityResult(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return NetworkStatus.offline;
    }

    final hasConnection = results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet,
    );

    return hasConnection ? NetworkStatus.online : NetworkStatus.offline;
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final status = _mapConnectivityResult(results);
    _updateStatus(status);
  }

  void _updateStatus(NetworkStatus status) {
    if (_currentStatus == status) return;

    _currentStatus = status;
    _statusController.add(status);

    for (final listener in _listeners) {
      try {
        listener(status);
      } catch (e) {
        debugPrint('Connectivity listener error: $e');
      }
    }
  }

  void addListener(Function(NetworkStatus) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(NetworkStatus) listener) {
    _listeners.remove(listener);
  }

  Future<bool> checkConnection() async {
    final status = await _checkConnection();
    return status == NetworkStatus.online;
  }

  Future<T> runWhenOnline<T>({
    required Future<T> Function() operation,
    Future<T> Function()? offlineFallback,
  }) async {
    if (isOnline) {
      return operation();
    } else {
      if (offlineFallback != null) {
        return offlineFallback();
      }
      throw Exception('No network connection available');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
    _listeners.clear();
  }
}

class ConnectivityBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, NetworkStatus status) builder;
  final Widget? offlineBuilder;
  final Widget? loadingBuilder;

  const ConnectivityBuilder({
    super.key,
    required this.builder,
    this.offlineBuilder,
    this.loadingBuilder,
  });

  @override
  State<ConnectivityBuilder> createState() => _ConnectivityBuilderState();
}

class _ConnectivityBuilderState extends State<ConnectivityBuilder> {
  late StreamSubscription<NetworkStatus> _subscription;
  NetworkStatus _status = NetworkStatus.unknown;

  @override
  void initState() {
    super.initState();
    _status = ConnectivityService.instance.currentStatus;
    _subscription = ConnectivityService.instance.statusStream.listen((status) {
      if (mounted) setState(() => _status = status);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == NetworkStatus.unknown && widget.loadingBuilder != null) {
      return widget.loadingBuilder!;
    }

    if (_status == NetworkStatus.offline && widget.offlineBuilder != null) {
      return widget.offlineBuilder!;
    }

    return widget.builder(context, _status);
  }
}

class ConnectivityOverlay extends StatelessWidget {
  final Widget child;
  final bool showOverlay;
  final String offlineMessage;

  const ConnectivityOverlay({
    super.key,
    required this.child,
    this.showOverlay = true,
    this.offlineMessage = 'Sin conexión a internet',
  });

  @override
  Widget build(BuildContext context) {
    if (!showOverlay) return child;

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ConnectivityBuilder(
            builder: (context, status) => const SizedBox.shrink(),
            offlineBuilder: Material(
              child: Container(
                color: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        offlineMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
