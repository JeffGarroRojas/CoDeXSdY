import 'package:flutter/services.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:flutter/foundation.dart';

enum UpdateType { none, shorebird, required }

class UpdateInfo {
  final UpdateType type;
  final String? version;
  final String? message;
  final String? downloadUrl;

  UpdateInfo({
    required this.type,
    this.version,
    this.message,
    this.downloadUrl,
  });
}

class UpdateService {
  static final UpdateService instance = UpdateService._();
  UpdateService._();

  final _shorebird = ShorebirdUpdater();
  String? _currentVersion;

  String get currentVersion {
    if (_currentVersion != null) return _currentVersion!;
    return '1.0.0';
  }

  Future<void> init() async {
    try {
      final info = await const MethodChannel(
        'shorebird_update_channel',
      ).invokeMethod<Map<dynamic, dynamic>>('getCurrentVersion');
      if (info != null) {
        _currentVersion = info['version']?.toString();
      }
    } catch (e) {
      _currentVersion = '1.3.4';
    }
  }

  Future<UpdateInfo> checkForUpdates() async {
    try {
      final status = await _shorebird.checkForUpdate();

      if (status == UpdateStatus.outdated) {
        return UpdateInfo(
          type: UpdateType.shorebird,
          version: '1.3.4',
          message: '¡Nueva versión disponible! Se descargará en segundo plano.',
        );
      }

      if (status == UpdateStatus.upToDate) {
        return UpdateInfo(
          type: UpdateType.none,
          version: '1.3.4',
          message: 'Ya tienes la versión 1.3.4 ✅',
        );
      }

      return UpdateInfo(type: UpdateType.none);
    } catch (e) {
      debugPrint('Update check error: $e');
      return UpdateInfo(type: UpdateType.none);
    }
  }

  Future<void> downloadAndApplyUpdate() async {
    try {
      await _shorebird.update();
    } catch (e) {
      debugPrint('Update failed: $e');
    }
  }
}
