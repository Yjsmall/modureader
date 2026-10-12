import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/custom_css_profile.dart';
import 'package:anx_reader/models/document_reading_mode.dart';
import 'package:anx_reader/service/local_data/json_preference_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Import-time evidence. Opening only reads this local cache; no file I/O,
/// sampling, hashing, or silent migration is allowed on the reader hot path.
class DocumentReadingModeStore {
  DocumentReadingModeStore(this.prefs)
      : _store = JsonPreferenceStore(prefs, key);
  final SharedPreferences prefs;
  final JsonPreferenceStore _store;
  static const key = 'documentReadingModes';

  String _source(Book book) => book.md5?.isNotEmpty == true
      ? 'md5:${book.md5}'
      : 'path:${book.filePath}';

  DocumentReadingMode read(Book book) {
    // PDF is a known container type, including old library entries. No page
    // inspection is necessary. Old EPUBs without evidence keep Preview 3.
    if (book.filePath.toLowerCase().endsWith('.pdf')) {
      return DocumentReadingMode.pdf;
    }
    final entry = _store.read()[customCssBookKey(book)];
    if (entry is! Map ||
        entry['version'] != 1 ||
        entry['source'] != _source(book)) {
      return DocumentReadingMode.standard;
    }
    if (DocumentReadingMode.supportsImageBook(book.filePath) &&
        entry['scannedOverride'] is bool) {
      return entry['scannedOverride'] == true
          ? DocumentReadingMode.imageEpub
          : DocumentReadingMode.standard;
    }
    return DocumentReadingMode.fromDetection(book.filePath, entry['mode']);
  }

  Future<void> save(Book book, Object? detection) {
    final mode = DocumentReadingMode.fromDetection(book.filePath, detection);
    return _write(book, mode: mode.storageValue);
  }

  Future<void> setScanned(Book book, bool enabled) {
    if (!DocumentReadingMode.supportsImageBook(book.filePath)) {
      throw ArgumentError('Unsupported image-book container');
    }
    return _write(book, scannedOverride: enabled);
  }

  Future<void> _write(Book book, {String? mode, bool? scannedOverride}) {
    final identity = customCssBookKey(book), source = _source(book);
    return _store.update((entries) {
      final old = entries[identity];
      entries[identity] = {
        if (old is Map && old['version'] == 1 && old['source'] == source)
          ...old,
        'version': 1,
        'source': source,
        if (mode != null) 'mode': mode,
        if (scannedOverride != null) 'scannedOverride': scannedOverride,
      };
    },
        failureMessage: 'Document classification save failed',
        recoverMalformed: true);
  }
}
