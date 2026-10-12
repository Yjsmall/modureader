import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Stores a JSON object with serialized updates and cache rollback on failure.
/// Stores sharing a preferences instance and key also share a write queue.
class JsonPreferenceStore {
  JsonPreferenceStore(this.prefs, this.key);

  final SharedPreferences prefs;
  final String key;
  static final _queues = Expando<Map<String, Future<void>>>();

  Map<String, dynamic> _decode(String? value) {
    final decoded = jsonDecode(value ?? '{}');
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Invalid stored JSON object: $key');
    }
    return decoded;
  }

  /// Damaged local metadata must not prevent opening a book.
  Map<String, dynamic> read() {
    try {
      return _decode(prefs.getString(key));
    } catch (_) {
      return {};
    }
  }

  /// Read the latest object inside the queue so independent updates are merged.
  /// Recoverable caches may opt in to replacing malformed data; user-authored
  /// layouts and reading positions keep the damaged value for recovery.
  Future<void> update(
    void Function(Map<String, dynamic> values) change, {
    required String failureMessage,
    bool recoverMalformed = false,
  }) {
    final queues = _queues[prefs] ??= {};
    final operation = (queues[key] ?? Future<void>.value()).then((_) async {
      final previous = prefs.getString(key);
      final values = recoverMalformed ? read() : _decode(previous);
      change(values);
      final encoded = jsonEncode(values);
      try {
        if (!await prefs.setString(key, encoded)) {
          throw StateError(failureMessage);
        }
      } catch (_) {
        // SharedPreferences changes its cache before the platform write.
        try {
          if (previous == null) {
            await prefs.remove(key);
          } else {
            await prefs.setString(key, previous);
          }
        } catch (_) {
          // Preserve the original write error if rollback also fails.
        }
        rethrow;
      }
    });
    final settled = operation.then<void>((_) {}, onError: (Object _) {});
    queues[key] = settled;
    settled.then((_) {
      if (identical(queues[key], settled)) queues.remove(key);
    });
    return operation;
  }
}
