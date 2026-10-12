import 'package:anx_reader/dao/sentence_context.dart';
import 'package:anx_reader/models/sentence_context.dart';

class MemorySentenceContextDao extends SentenceContextDao {
  MemorySentenceContextDao([List<SentenceContext> initial = const []])
      : entries = [...initial];
  final List<SentenceContext> entries;
  bool failNotesWrite = false;

  @override
  Future<bool> collect(SentenceContext sentence) async {
    if (await find(sentence) != null) return false;
    final id = entries.fold<int>(0, (max, e) => e.id! > max ? e.id! : max) + 1;
    entries.add(SentenceContext.fromDb({...sentence.toDb(), 'id': id}));
    return true;
  }

  @override
  Future<SentenceContext?> find(SentenceContext sentence) async => entries
      .where((e) =>
          e.bookId == sentence.bookId &&
          e.chapter == sentence.chapter &&
          e.sentence == sentence.sentence)
      .firstOrNull;

  @override
  Future<bool> saveNotes(SentenceContext sentence, String notes) async {
    if (failNotesWrite) throw StateError('Notes write failed');
    final index = entries.indexWhere((e) =>
        e.id == sentence.id &&
        e.word == sentence.word &&
        e.sentence == sentence.sentence &&
        e.notes == sentence.notes);
    if (index < 0) return false;
    entries[index] = entries[index].withNotes(notes);
    return true;
  }

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
