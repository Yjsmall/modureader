import 'dart:async';

import 'package:anx_reader/service/ai/sentence_context_notes.dart';
import 'package:anx_reader/models/sentence_context.dart';
import 'package:anx_reader/page/home_page/sentence_contexts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sentence_context_dao.dart';

class _Dao extends MemorySentenceContextDao {
  _Dao()
      : super([
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
        ]);
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

  testWidgets('analysis shows loading, failure, retry and persisted Notes',
      (tester) async {
    final dao = _Dao();
    var response = Completer<String>();
    var calls = 0;
    final service = SentenceContextNotesService(
        dao: dao,
        providerId: () => 'fixture',
        analyze: (_, __) {
          calls++;
          return response.future;
        });
    await tester.pumpWidget(MaterialApp(
        home: SentenceContextsPage(dao: dao, notesService: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Document A'));
    await tester.pumpAndSettle();
    expect(find.text('Notes'), findsOneWidget);
    await tester.tap(find.text('Generate analysis'));
    await tester.pump();
    await tester.pump();
    expect(find.text('AI is explaining the word and analyzing the sentence…'),
        findsOneWidget);
    expect(find.text('Generate analysis'), findsNothing);
    response.completeError(StateError('fixture request failed'));
    await tester.pumpAndSettle();
    expect(find.text('Analysis failed. Your sentence is saved. Please retry.'),
        findsOneWidget);
    expect(find.text('The word belongs here.'), findsOneWidget);
    response = Completer<String>();
    await tester.tap(find.text('Retry analysis'));
    await tester.pump();
    response.complete(
        'Word meaning: a vocabulary item.\nSentence analysis: The word is the subject.');
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text(dao.entries.first.notes), findsOneWidget);
    expect(find.text('Retry analysis'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Document A'));
    await tester.pumpAndSettle();
    expect(find.text(dao.entries.first.notes), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(375, 812),
    const Size(844, 390),
    const Size(1024, 768)
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets(
          'Notes fit $size in $brightness with large text and reduced motion',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final dao = _Dao();
        dao.entries[0] = dao.entries[0].withNotes(
            'Word meaning: a vocabulary item in this sentence.\n\n'
            'Sentence analysis: The word is the subject, belongs is the verb, '
            'and here describes the place.');
        final service =
            SentenceContextNotesService(dao: dao, providerId: () => null);
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(brightness: brightness),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(2),
                    disableAnimations: true),
                child: child!),
            home: SentenceContextCardsPage(
                document: const SentenceContextDocument(1, 'Document A', '', 1),
                dao: dao,
                notesService: service)));
        await tester.pumpAndSettle();
        expect(find.text('Notes'), findsOneWidget);
        expect(find.text(dao.entries.first.notes), findsOneWidget);
        expect(find.text('Generate analysis'), findsNothing);
        await tester.drag(find.byType(ListView), const Offset(0, -700));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        service.dispose();
      });
    }
  }

  testWidgets('leaving the cards page keeps the pending notes save alive',
      (tester) async {
    final dao = _Dao();
    final response = Completer<String>();
    final service = SentenceContextNotesService(
        dao: dao,
        providerId: () => 'fixture',
        analyze: (_, __) => response.future);
    await tester.pumpWidget(MaterialApp(
        home: SentenceContextsPage(dao: dao, notesService: service)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Document A'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generate analysis'));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    response.complete('Word meaning and sentence analysis after leaving.');
    await service.generate(dao.entries.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Document A'));
    await tester.pumpAndSettle();
    expect(find.text(dao.entries.first.notes), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });
}
