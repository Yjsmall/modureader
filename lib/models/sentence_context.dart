class SentenceContext {
  const SentenceContext({
    this.id,
    required this.bookId,
    required this.bookTitle,
    required this.author,
    required this.word,
    required this.sentence,
    required this.cfi,
    required this.chapter,
    required this.createdAt,
    this.notes = '',
  });

  final int? id;
  final int bookId;
  final String bookTitle, author, word, sentence, cfi, chapter, notes;
  final DateTime createdAt;

  Map<String, Object?> toDb() => {
        if (id != null) 'id': id,
        'book_id': bookId,
        'book_title': bookTitle,
        'author': author,
        'word': word,
        'sentence': sentence,
        'cfi': cfi,
        'chapter': chapter,
        'create_time': createdAt.toIso8601String(),
        'notes': notes,
      };

  factory SentenceContext.fromDb(Map<String, dynamic> row) => SentenceContext(
        id: row['id'] as int,
        bookId: row['book_id'] as int,
        bookTitle: row['book_title'] as String,
        author: row['author'] as String,
        word: row['word'] as String,
        sentence: row['sentence'] as String,
        cfi: row['cfi'] as String,
        chapter: row['chapter'] as String,
        createdAt: DateTime.parse(row['create_time'] as String),
        notes: row['notes'] as String? ?? '',
      );

  SentenceContext withNotes(String value) => SentenceContext(
        id: id,
        bookId: bookId,
        bookTitle: bookTitle,
        author: author,
        word: word,
        sentence: sentence,
        cfi: cfi,
        chapter: chapter,
        createdAt: createdAt,
        notes: value,
      );
}

class SentenceContextDocument {
  const SentenceContextDocument(
    this.bookId,
    this.title,
    this.author,
    this.count,
  );
  final int bookId, count;
  final String title, author;
}
