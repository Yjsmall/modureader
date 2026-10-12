import 'package:anx_reader/service/book_player/sentence_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'OCR sentence uses selection offsets rather than the first matching word',
    () {
      const text = 'First word. Second word belongs here! Last.';
      final start = text.lastIndexOf('word');
      expect(sentenceAt(text, start, start + 4), 'Second word belongs here!');
      expect(sentenceAt('上一句。这个单词在这里！”下一句。', 6, 8), '这个单词在这里！”');
    },
  );

  test('OCR sentences retain abbreviations, decimals and untruncated text', () {
    const text = 'Before. Dr. Smith paid 3.14 dollars. After.';
    expect(sentenceAt(text, 12, 17), 'Dr. Smith paid 3.14 dollars.');
    final long = '${'前'.padRight(1200, '前')}单词。下一句。';
    expect(sentenceAt(long, 1200, 1202), long.substring(0, 1203));
    expect(sentenceAt('No punctuation', 3, 14), 'No punctuation');
    expect(sentenceAt('text', 1, 1), isEmpty);
  });
}
