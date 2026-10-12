import 'package:anx_reader/service/local_data/json_preference_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local per-document correction, separate from transferable global settings.
class DocumentTypeStore {
  DocumentTypeStore(this.prefs)
      : _store = JsonPreferenceStore(prefs, key),
        _detectedStore = JsonPreferenceStore(prefs, detectedKey);
  final SharedPreferences prefs;
  final JsonPreferenceStore _store;
  final JsonPreferenceStore _detectedStore;
  static const key = 'documentTypeOverrides';
  static const types = {'text', 'scanned', 'image-with-text', 'mixed'};

  String? _validType(Object? value) =>
      value is String && types.contains(value) ? value : null;

  String? read(String documentKey) => _validType(_store.read()[documentKey]);

  static const detectedKey = 'documentDetectedTypes';
  String? readDetected(String documentKey) =>
      _validType(_detectedStore.read()[documentKey]);

  Future<void> saveDetected(String documentKey, String kind) async {
    if (!types.contains(kind) || documentKey.isEmpty) return;
    await _detectedStore.update((entries) => entries[documentKey] = kind,
        failureMessage: 'Could not save detected document type',
        recoverMalformed: true);
  }

  Future<void> save(String documentKey, String? kind) async {
    if (documentKey.isEmpty || (kind != null && !types.contains(kind))) {
      throw ArgumentError('Invalid document type correction');
    }
    await _store.update((values) {
      values.removeWhere((_, value) => _validType(value) == null);
      if (kind == null) {
        values.remove(documentKey);
      } else {
        values[documentKey] = kind;
      }
    },
        failureMessage: 'Could not save document type correction',
        recoverMalformed: true);
  }
}
