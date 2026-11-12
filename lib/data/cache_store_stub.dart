/// Web/non-IO in-memory fallback for artwork metadata caching.
class ArtCacheStore {
  static final Map<String, String> _memory = {};

  static Future<String?> read(String fileName) async {
    return _memory[fileName];
  }

  static Future<void> write(String fileName, String content) async {
    _memory[fileName] = content;
  }
}
