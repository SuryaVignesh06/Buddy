import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Disk JSON cache backed by `path_provider` on mobile and desktop platforms.
class ArtCacheStore {
  static Future<File?> _resolveFile(String fileName) async {
    try {
      final dir = await getApplicationSupportDirectory();
      return File('${dir.path}${Platform.pathSeparator}$fileName');
    } catch (_) {
      return null;
    }
  }

  static Future<String?> read(String fileName) async {
    try {
      final file = await _resolveFile(fileName);
      if (file == null || !await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(String fileName, String content) async {
    try {
      final file = await _resolveFile(fileName);
      if (file == null) return;
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
    } catch (_) {
      // Best-effort cache write; ignore disk errors.
    }
  }
}
