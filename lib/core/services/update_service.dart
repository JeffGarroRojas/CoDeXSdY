import 'dart:convert';
import 'package:http/http.dart' as http;
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

  String get currentVersion => '1.0.0';

  Future<UpdateInfo> checkForUpdates() async {
    try {
      final status = await _shorebird.checkForUpdate();

      if (status == UpdateStatus.outdated) {
        return UpdateInfo(
          type: UpdateType.shorebird,
          version: 'Actualización disponible',
          message:
              'Se descargará una actualización en segundo plano. '
              'La app se actualizará automáticamente.',
        );
      }

      final remoteInfo = await _checkRemoteVersion();
      if (remoteInfo != null) {
        return remoteInfo;
      }

      return UpdateInfo(type: UpdateType.none);
    } catch (e) {
      debugPrint('Update check error: $e');
      return UpdateInfo(type: UpdateType.none);
    }
  }

  Future<UpdateInfo?> _checkRemoteVersion() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/YOUR_USERNAME/YOUR_REPO/releases/latest',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion =
            data['tag_name']?.toString().replaceAll('v', '') ?? '';
        final downloadUrl = data['assets']?[0]?['browser_download_url'];

        if (_isNewerVersion(latestVersion)) {
          return UpdateInfo(
            type: UpdateType.required,
            version: latestVersion,
            message:
                'Nueva versión disponible: $latestVersion. '
                'Descarga el APK para obtener las últimas funciones.',
            downloadUrl: downloadUrl,
          );
        }
      }
    } catch (e) {
      debugPrint('Remote version check failed: $e');
    }
    return null;
  }

  bool _isNewerVersion(String latestVersion) {
    try {
      final current = currentVersion.replaceAll(RegExp(r'[^0-9.]'), '');
      final latest = latestVersion.replaceAll(RegExp(r'[^0-9.]'), '');

      final currentParts = current
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      final latestParts = latest
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      for (int i = 0; i < 3; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final l = i < latestParts.length ? latestParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (e) {
      debugPrint('Version comparison failed: $e');
    }
    return false;
  }

  Future<void> downloadAndApplyUpdate() async {
    try {
      await _shorebird.update();
    } catch (e) {
      debugPrint('Update failed: $e');
    }
  }
}
