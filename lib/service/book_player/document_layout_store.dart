import 'package:anx_reader/models/document_page_layout.dart';
import 'package:anx_reader/service/local_data/json_preference_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-document local layouts, never a transferable global preference.
class DocumentLayoutStore {
  DocumentLayoutStore(this.prefs) : _store = JsonPreferenceStore(prefs, key);
  final SharedPreferences prefs;
  final JsonPreferenceStore _store;
  static const key = 'documentPageLayouts';

  DocumentLayoutConfig read(String documentKey) {
    try {
      return DocumentLayoutConfig.fromJson(_store.read()[documentKey]);
    } catch (_) {
      return const DocumentLayoutConfig();
    }
  }

  Future<void> save(String documentKey, DocumentLayoutConfig config) {
    if (documentKey.isEmpty) throw ArgumentError('Empty document identity');
    final encoded = config.toJson();
    // Validate the complete snapshot before any write; do not retain mutable maps.
    final snapshot = DocumentLayoutConfig.fromJson(encoded).toJson();
    return _store.update((values) => values[documentKey] = snapshot,
        failureMessage: 'Layout save failed');
  }
}
