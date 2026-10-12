import 'package:anx_reader/dao/base_dao.dart';
import 'package:anx_reader/models/sentence_context.dart';
import 'package:sqflite/sqflite.dart';

final sentenceContextDao = SentenceContextDao();

class SentenceContextDao extends BaseDao {
  Future<bool> collect(SentenceContext sentence) async {
    if (sentence.word.trim().isEmpty || sentence.sentence.trim().isEmpty) {
      throw ArgumentError('A selected word and its sentence are required');
    }
    // SQLite's change count also distinguishes ignored inserts on Android.
    return transaction((txn) async {
      await txn.insert(
        'tb_sentence_contexts',
        sentence.toDb(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      final result = await txn.rawQuery('SELECT changes() AS count');
      return result.single['count'] == 1;
    });
  }

  Future<List<SentenceContextDocument>> documents() => rawQueryList(
        '''
    SELECT book_id, book_title, author, COUNT(*) AS count
    FROM tb_sentence_contexts GROUP BY book_id
    ORDER BY MAX(create_time) DESC, book_id
  ''',
        mapper: (row) => SentenceContextDocument(
          row['book_id'] as int,
          row['book_title'] as String,
          row['author'] as String,
          row['count'] as int,
        ),
      );

  Future<List<SentenceContext>> sentences(int bookId) => queryList(
        'tb_sentence_contexts',
        mapper: SentenceContext.fromDb,
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'create_time DESC, id DESC',
      );

  Future<void> remove(int id) async {
    await delete('tb_sentence_contexts', where: 'id = ?', whereArgs: [id]);
  }
}
