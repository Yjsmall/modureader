import 'package:anx_reader/dao/sentence_context.dart';
import 'package:anx_reader/models/sentence_context.dart';
import 'package:anx_reader/page/home_page/sentence_contexts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Dao extends SentenceContextDao {
  final entries = [
    SentenceContext(
      id: 1,
      bookId: 1,
      bookTitle: 'Document A',
      author: 'Author',
      word: 'word',
      sentence: 'The word belongs here.',
      cfi: 'a',
      chapter: 'Chapter 1',
      createdAt: DateTime(2026, 10, 12),
    ),
    SentenceContext(
      id: 2,
      bookId: 2,
      bookTitle: 'Document B',
      author: '',
      word: 'other',
      sentence: 'Another sentence.',
      cfi: 'b',
      chapter: '',
      createdAt: DateTime(2026, 10, 11),
    ),
  ];
  @override
  Future<List<SentenceContextDocument>> documents() async => [
        for (final id in entries.map((e) => e.bookId).toSet())
          SentenceContextDocument(
            id,
            entries.firstWhere((e) => e.bookId == id).bookTitle,
            '',
            entries.where((e) => e.bookId == id).length,
          ),
      ];
  @override
  Future<List<SentenceContext>> sentences(int bookId) async =>
      entries.where((e) => e.bookId == bookId).toList();
  @override
  Future<void> remove(int id) async => entries.removeWhere((e) => e.id == id);
}

void main() {
  testWidgets(
    'documents open sentence cards, copying and deleting refresh the collection',
    (tester) async {
      final dao = _Dao();
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: SentenceContextsPage(dao: dao)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Document A'), findsOneWidget);
      expect(find.text('Document B'), findsOneWidget);
      await tester.tap(find.text('Document A'));
      await tester.pumpAndSettle();
      expect(find.text('word'), findsOneWidget);
      expect(find.text('The word belongs here.'), findsOneWidget);
      expect(find.text('Another sentence.'), findsNothing);
      await tester.tap(find.byTooltip('Copy sentence'));
      await tester.pumpAndSettle();
      expect(copied, 'The word belongs here.');
      await tester.tap(find.byTooltip('Delete sentence'));
      await tester.pumpAndSettle();
      expect(find.text('No saved sentences in this document.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Document A'), findsNothing);
      expect(find.text('Document B'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
