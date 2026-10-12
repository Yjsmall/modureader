import 'package:anx_reader/models/pdf_reading_view.dart';
import 'package:anx_reader/service/local_data/json_preference_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local region positions supplement (never replace) the original CFI.
class PdfReadingStateStore {
  PdfReadingStateStore(this.prefs) : _store = JsonPreferenceStore(prefs, key);
  final SharedPreferences prefs;
  final JsonPreferenceStore _store;
  static const key = 'pdfReadingStates';

  bool hasSavedMode(String bookKey) {
    final value = _store.read()[bookKey];
    return value is Map && value['enabled'] is bool;
  }

  Map<String, dynamic> _state(Object? value) =>
      value is Map<String, dynamic> && value['enabled'] is bool
          ? Map<String, dynamic>.from(value)
          : {'enabled': false};

  Map<String, dynamic> read(String bookKey) => _state(_store.read()[bookKey]);

  Future<void> setEnabled(String bookKey, bool enabled) =>
      _update(bookKey, {'enabled': enabled, 'position': null, 'cfi': null});

  PdfReadingView readView(String bookKey) {
    try {
      return PdfReadingView.fromJson(read(bookKey)['view']);
    } catch (_) {
      return const PdfReadingView();
    }
  }

  Future<void> saveView(String bookKey, PdfReadingView view, {bool? enabled}) =>
      _update(bookKey, {
        'view': PdfReadingView.fromJson(view.toJson()).toJson(),
        if (enabled != null) 'enabled': enabled
      });

  Future<void> savePosition(String bookKey, String cfi, dynamic position,
      {bool? enabled}) {
    if (position != null) {
      if (position is! Map ||
          position['page'] is! int ||
          position['page'] < 0 ||
          position['panel'] is! int ||
          position['panel'] < 0 ||
          position['panel'] > 8 ||
          position['signature'] is! String ||
          (position['signature'] as String).length > 4096 ||
          cfi.isEmpty) {
        throw const FormatException('Invalid PDF region position');
      }
      final center = position['center'];
      if (center != null &&
          (center is! Map ||
              !['x', 'y'].every((key) =>
                  center[key] is num &&
                  (center[key] as num).isFinite &&
                  center[key] >= 0 &&
                  center[key] <= 1))) {
        throw const FormatException('Invalid PDF viewport position');
      }
      position = {
        'page': position['page'],
        'panel': position['panel'],
        'signature': position['signature'],
        if (center != null) 'center': {'x': center['x'], 'y': center['y']},
      };
    }
    return _update(bookKey, {
      'cfi': cfi,
      'position': position,
      if (enabled != null) 'enabled': enabled
    });
  }

  Future<void> _update(String bookKey, Map<String, dynamic> patch) {
    if (bookKey.isEmpty) throw ArgumentError('Empty document identity');
    return _store.update((all) {
      all[bookKey] = {..._state(all[bookKey]), ...patch};
    }, failureMessage: 'PDF reading position save failed');
  }
}
