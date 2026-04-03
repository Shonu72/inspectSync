import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../util/logger.dart';

/// Provides real connectivity status by combining [Connectivity] (network interface)
/// with an actual HTTP reachability check (DNS lookup).
///
/// Usage:
///   final service = ConnectivityService();
///   service.statusStream.listen((status) => print(status));
///   final isOnline = await service.checkNow();
///   service.dispose();
class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  Timer? _periodicCheck;

  ConnectivityStatus _status = ConnectivityStatus.unknown;
  ConnectivityStatus get status => _isManualOffline ? ConnectivityStatus.offline : _status;

  List<ConnectivityResult> _lastResults = [];
  int _lastLatencyMs = 0;
  double _lastSpeedMbps = 0.0;

  int get latencyMs => _lastLatencyMs;
  double get speedMbps => _lastSpeedMbps;
  
  String get networkType {
    if (_lastResults.isEmpty || _lastResults.contains(ConnectivityResult.none)) return 'NONE';
    if (_lastResults.contains(ConnectivityResult.wifi)) return 'WIFI';
    if (_lastResults.contains(ConnectivityResult.mobile)) return 'LTE (4G)'; // Simplified for tactical display
    if (_lastResults.contains(ConnectivityResult.ethernet)) return 'ETH';
    if (_lastResults.contains(ConnectivityResult.vpn)) return 'VPN';
    return 'UNKNOWN';
  }

  bool _isManualOffline = false;
  bool get isManualOffline => _isManualOffline;

  bool get isOnline => !_isManualOffline && _status == ConnectivityStatus.online;
  bool get isOffline => _isManualOffline || _status == ConnectivityStatus.offline;

  final _statusController = StreamController<ConnectivityStatus>.broadcast();
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    // Listen for network interface changes (wifi on/off, mobile data toggle)
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _onConnectivityChanged(results);
    });

    // Periodic reachability check every 10 seconds for real-time telemetry
    _periodicCheck = Timer.periodic(const Duration(seconds: 10), (_) {
      checkNow();
    });

    // Initial check
    await checkNow();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      // No network interface at all — immediately go offline
      _updateStatus(ConnectivityStatus.offline);
    } else {
      // Network interface is available, but verify actual internet
      _lastResults = results;
      checkNow();
    }
  }

  /// Performs an actual reachability check by doing a DNS lookup.
  /// Returns `true` if the device can reach the internet.
  Future<bool> checkNow() async {
    try {
      // First check: does the OS report any network interface?
      final connectivityResults = await _connectivity.checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        _lastLatencyMs = 0;
        _lastSpeedMbps = 0.0;
        _lastResults = connectivityResults;
        _updateStatus(ConnectivityStatus.offline);
        return false;
      }

      // Second check: actual DNS lookup to verify internet reachability + measure latency
      final stopwatch = Stopwatch()..start();
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      stopwatch.stop();

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _lastLatencyMs = stopwatch.elapsedMilliseconds;
        _lastResults = connectivityResults;
        
        // Estimate "Uplink" speed based on latency (Simplified tactical estimation)
        // In a real scenario, this would be based on an actual data transfer.
        // For this operational dashboard, we use a quality-of-service (QoS) heuristic:
        if (_lastLatencyMs < 80) {
          _lastSpeedMbps = 45.2; // Excellent (5G/Fiber)
        } else if (_lastLatencyMs < 200) {
          _lastSpeedMbps = 12.4; // Good (4G/Strong WiFi)
        } else if (_lastLatencyMs < 500) {
          _lastSpeedMbps = 2.8;  // Poor (3G/Congested)
        } else {
          _lastSpeedMbps = 0.5;  // Critically slow
        }

        _updateStatus(ConnectivityStatus.online);
        return true;
      } else {
        _lastLatencyMs = 0;
        _lastSpeedMbps = 0.0;
        _updateStatus(ConnectivityStatus.offline);
        return false;
      }
    } on SocketException catch (_) {
      _lastLatencyMs = 0;
      _lastSpeedMbps = 0.0;
      _updateStatus(ConnectivityStatus.offline);
      return false;
    } on TimeoutException catch (_) {
      _lastLatencyMs = 0;
      _lastSpeedMbps = 0.0;
      _updateStatus(ConnectivityStatus.offline);
      return false;
    } catch (e) {
      AppLogger.error('ConnectivityService: unexpected error: $e');
      _lastLatencyMs = 0;
      _lastSpeedMbps = 0.0;
      _updateStatus(ConnectivityStatus.offline);
      return false;
    } finally {
      notifyListeners();
    }
  }

  void setManualOffline(bool value) {
    if (_isManualOffline != value) {
      _isManualOffline = value;
      notifyListeners();
      _statusController.add(status);
      if (value) {
        AppLogger.warning('ConnectivityService: MANUAL OFFLINE MODE ENGAGED');
      } else {
        AppLogger.success('ConnectivityService: MANUAL OFFLINE MODE DISENGAGED');
        checkNow(); // Re-verify actual connection when toggle is off
      }
    }
  }

  void _updateStatus(ConnectivityStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(status); // Use logical status
      notifyListeners();
      if (newStatus == ConnectivityStatus.online) {
        AppLogger.success('ConnectivityService: Network protocol established (ONLINE)');
      } else {
        AppLogger.warning('ConnectivityService: Network interface disconnected (OFFLINE)');
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _periodicCheck?.cancel();
    _statusController.close();
    super.dispose();
  }
}

enum ConnectivityStatus {
  online,
  offline,
  unknown,
}
