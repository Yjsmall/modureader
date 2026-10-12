import 'dart:async';
import 'dart:convert';

import 'package:anx_reader/service/book_player/document_type_store.dart';
import 'package:anx_reader/service/local_data/json_preference_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Models the real preferences cache changing before platform I/O completes.
class _ControlledPrefs implements SharedPreferences {
  final values = <String, String>{};
  bool failNextWrite = false;
  Object? writeError;
  bool failRollback = false;
  Completer<void>? writeGate;

  @override
  String? getString(String key) => values[key];

  @override
  Future<bool> setString(String key, String value) async {
    values[key] = value;
    final gate = writeGate;
    writeGate = null;
    if (gate != null) await gate.future;
    if (failNextWrite) {
      failNextWrite = false;
      final error = writeError;
      writeError = null;
      if (error != null) throw error;
      return false;
    }
    if (failRollback) throw StateError('rollback failed');
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    if (failRollback) throw StateError('rollback failed');
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('updates from separate stores wait for rollback and retain both books',
      () async {
    final prefs = _ControlledPrefs();
    final first = DocumentTypeStore(prefs), second = DocumentTypeStore(prefs);
    await first.save('existing', 'text');
    prefs.failNextWrite = true;
    prefs.writeGate = Completer<void>();
    final gate = prefs.writeGate!;
    final failed = first.save('existing', 'scanned');
    final failureCheck = expectLater(failed, throwsStateError);
    final following = second.save('next', 'mixed');
    // Allow the first update to start, but keep its platform write pending.
    await Future<void>.delayed(Duration.zero);
    expect(first.read('existing'), 'scanned');
    expect(second.read('next'), isNull);
    gate.complete();
    await failureCheck;
    await following;
    expect(first.read('existing'), 'text');
    expect(second.read('next'), 'mixed');
  });

  for (final existing in [false, true]) {
    for (final throws in [false, true]) {
      test(
          'rollback restores ${existing ? 'old' : 'absent'} value on '
          '${throws ? 'exception' : 'false result'}', () async {
        final prefs = _ControlledPrefs();
        final store = JsonPreferenceStore(prefs, 'data');
        if (existing) prefs.values['data'] = '{"saved":1}';
        final previous = prefs.getString('data');
        prefs.failNextWrite = true;
        final original = StateError('platform write failed');
        if (throws) prefs.writeError = original;
        await expectLater(
            store.update((values) => values['new'] = 2,
                failureMessage: 'save failed'),
            throws ? throwsA(same(original)) : throwsStateError);
        expect(prefs.getString('data'), previous);
        await store.update((values) => values['next'] = 3,
            failureMessage: 'save failed');
        expect(store.read(), {if (existing) 'saved': 1, 'next': 3});
      });
    }
  }

  test('rollback failure preserves the original platform error', () async {
    final prefs = _ControlledPrefs();
    final original = StateError('platform write failed');
    prefs.failNextWrite = true;
    prefs.writeError = original;
    prefs.failRollback = true;
    await expectLater(
        JsonPreferenceStore(prefs, 'data')
            .update((values) => values['a'] = 1, failureMessage: 'save failed'),
        throwsA(same(original)));
  });

  test('malformed collections are preserved unless recovery is explicit',
      () async {
    final prefs = _ControlledPrefs();
    final store = JsonPreferenceStore(prefs, 'data');
    for (final bad in ['{broken', '[]', 'null', '42']) {
      prefs.values['data'] = bad;
      expect(store.read(), isEmpty);
      await expectLater(
          store.update((values) => values['a'] = 1,
              failureMessage: 'save failed'),
          throwsFormatException);
      expect(prefs.getString('data'), bad);
      await store.update((values) => values['a'] = 1,
          failureMessage: 'save failed', recoverMalformed: true);
      expect(store.read(), {'a': 1});
    }
  });

  test('failed encoding leaves preferences intact and the queue usable',
      () async {
    final prefs = _ControlledPrefs();
    final store = JsonPreferenceStore(prefs, 'data');
    prefs.values['data'] = '{"saved":1}';
    await expectLater(
        store.update((values) => values['bad'] = double.nan,
            failureMessage: 'save failed'),
        throwsA(isA<JsonUnsupportedObjectError>()));
    expect(prefs.getString('data'), '{"saved":1}');
    await store.update((values) => values['good'] = 2,
        failureMessage: 'save failed');
    expect(store.read(), {'saved': 1, 'good': 2});
  });

  test('unrelated keys and preferences instances are not blocked by a write',
      () async {
    final prefs = _ControlledPrefs()..writeGate = Completer<void>();
    final gate = prefs.writeGate!;
    final pending = JsonPreferenceStore(prefs, 'a')
        .update((values) => values['book'] = 1, failureMessage: 'save failed');
    await Future<void>.delayed(Duration.zero);
    await JsonPreferenceStore(prefs, 'b')
        .update((values) => values['book'] = 2, failureMessage: 'save failed');
    final other = _ControlledPrefs();
    await JsonPreferenceStore(other, 'a')
        .update((values) => values['book'] = 3, failureMessage: 'save failed');
    gate.complete();
    await pending;
    expect(JsonPreferenceStore(prefs, 'a').read(), {'book': 1});
    expect(JsonPreferenceStore(prefs, 'b').read(), {'book': 2});
    expect(JsonPreferenceStore(other, 'a').read(), {'book': 3});
  });

  test('detected types report failed writes and restore the previous cache',
      () async {
    final prefs = _ControlledPrefs();
    final store = DocumentTypeStore(prefs);
    await store.saveDetected('book', 'text');
    prefs.failNextWrite = true;
    await expectLater(store.saveDetected('book', 'scanned'), throwsStateError);
    expect(store.readDetected('book'), 'text');
    await store.saveDetected('book', 'mixed');
    expect(store.readDetected('book'), 'mixed');
    await store.save('book', 'scanned');
    await store.save('book', null);
    expect(store.read('book'), isNull);
    expect(store.readDetected('book'), 'mixed');
  });
}
