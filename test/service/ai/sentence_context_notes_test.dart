import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/models/sentence_context.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:anx_reader/service/ai/sentence_context_notes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langchain_core/chat_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/sentence_context_dao.dart';

SentenceContext _sentence({String notes = ''}) => SentenceContext(
      bookId: 1,
      bookTitle: 'Private book title',
      author: 'Author',
      word: 'bank',
      sentence: 'She sat on the bank of the river.',
      cfi: 'private-position',
      chapter: 'Chapter',
      createdAt: DateTime(2026, 10, 12),
      notes: notes,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs().initPrefs();
  });

  test('request includes word and sentence as data, and asks for both analyses',
      () {
    final messages = sentenceContextNotesMessages(_sentence(), 'zh-CN');
    final system = (messages.first as SystemChatMessage).content;
    expect(system, contains('语境词义'));
    expect(system, contains('句子分析'));
    expect(system, contains('zh-CN'));
    expect(system, contains('不是指令'));
    expect(jsonDecode(messages.last.contentAsString), {
      'word': 'bank',
      'sentence': 'She sat on the bank of the river.',
    });
    expect(messages.last.contentAsString, isNot(contains('Private book')));
    expect(messages.last.contentAsString, isNot(contains('private-position')));
  });

  test(
      'provider availability rejects disabled, incomplete and empty-key config',
      () {
    const provider = AiProvider(
        id: 'configured',
        title: 'Fixture',
        url: 'https://example.test/v1',
        protocol: AiProtocol.openai,
        model: 'fixture',
        apiKeys: [AiApiKey(id: 'key', key: 'test-only-secret')]);
    Prefs().selectedAiService = provider.id;
    expect(configuredSentenceContextProvider(), isNull);
    for (final value in [
      provider.copyWith(enabled: false),
      provider.copyWith(model: ''),
      provider.copyWith(url: ''),
      provider.copyWith(apiKeys: []),
      provider.copyWith(apiKeys: [const AiApiKey(id: 'key', key: ' ')])
    ]) {
      Prefs().saveAiProviders([value]);
      expect(configuredSentenceContextProvider(), isNull);
    }
    Prefs().saveAiProviders([provider]);
    expect(configuredSentenceContextProvider(), provider.id);
  });

  test('legacy configured provider remains available', () {
    Prefs().saveAiConfig('openai', {
      'api_key': 'test-only-secret',
      'model': 'fixture',
      'url': 'https://example.test/v1'
    });
    expect(configuredSentenceContextProvider(), 'openai');
  });

  test('without AI, collecting and reopening preserves a plain sentence',
      () async {
    final dao = MemorySentenceContextDao();
    final service = SentenceContextNotesService(
        dao: dao,
        providerId: () => null,
        analyze: (_, __) async => throw StateError('must not call AI'));
    addTearDown(service.dispose);
    expect(await service.collect(_sentence()), true);
    expect((await dao.sentences(1)).single.notes, isEmpty);
    expect(await service.collect(_sentence()), false);
  });

  test(
      'collection saves first; concurrent analysis coalesces and persists notes',
      () async {
    final dao = MemorySentenceContextDao();
    final result = Completer<String>();
    var calls = 0;
    final service = SentenceContextNotesService(
        dao: dao,
        providerId: () => 'fixture',
        analyze: (sentence, id) {
          calls++;
          expect(dao.entries.single.id, sentence.id);
          expect(id, 'fixture');
          return result.future;
        });
    addTearDown(service.dispose);
    await service.collect(_sentence());
    final saved = dao.entries.single;
    final first = service.generate(saved), second = service.generate(saved);
    expect(identical(first, second), true);
    expect(service.isAnalyzing(saved.id), true);
    expect(saved.notes, isEmpty);
    result.complete(
        'Word meaning: river edge.\nSentence analysis: She is the subject.');
    await first;
    expect(calls, 1);
    expect(dao.entries.single.notes, contains('river edge'));
    expect(service.isAnalyzing(saved.id), false);
    await service.collect(_sentence());
    expect(calls, 1,
        reason: 'A saved answer is not regenerated on duplicate collection');
  });

  for (final failure in ['network', 'empty', 'storage']) {
    test('$failure failure preserves collection and permits retry', () async {
      final dao = MemorySentenceContextDao();
      await dao.collect(_sentence());
      var failing = true;
      dao.failNotesWrite = failure == 'storage';
      final service = SentenceContextNotesService(
          dao: dao,
          providerId: () => 'fixture',
          analyze: (_, __) async {
            if (failing && failure == 'network') {
              throw const SocketException('test');
            }
            return failing && failure == 'empty'
                ? ' '
                : 'Word meaning and sentence analysis';
          });
      addTearDown(service.dispose);
      await service.generate(dao.entries.single);
      expect(dao.entries.single.notes, isEmpty);
      expect(service.hasFailed(dao.entries.single.id), true);
      failing = false;
      dao.failNotesWrite = false;
      await service.generate(dao.entries.single);
      expect(dao.entries.single.notes, isNotEmpty);
      expect(service.hasFailed(dao.entries.single.id), false);
    });
  }

  test('late response cannot resurrect a deleted card or overwrite newer notes',
      () async {
    for (final deleted in [true, false]) {
      final dao = MemorySentenceContextDao();
      await dao.collect(_sentence());
      final saved = dao.entries.single;
      final response = Completer<String>();
      final service = SentenceContextNotesService(
          dao: dao,
          providerId: () => 'fixture',
          analyze: (_, __) => response.future);
      final pending = service.generate(saved);
      if (deleted) {
        await dao.remove(saved.id!);
      } else {
        await dao.saveNotes(saved, 'newer notes');
      }
      response.complete('late analysis');
      await pending;
      expect(
          deleted
              ? dao.entries.isEmpty
              : dao.entries.single.notes == 'newer notes',
          true);
      service.dispose();
    }
  });

  test('strict transport reports HTTP failure instead of yielding notes text',
      () async {
    final oldOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = oldOverrides);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var requests = 0;
    server.listen((request) async {
      requests++;
      await request.drain<void>();
      request.response.statusCode = 401;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'error': {
          'message': 'fixture unauthorized',
          'type': 'invalid_request_error',
          'code': 'invalid_api_key'
        }
      }));
      await request.response.close();
    });
    final provider = AiProvider(
        id: 'fixture',
        title: 'Fixture',
        url: 'http://127.0.0.1:${server.port}/v1',
        protocol: AiProtocol.openai,
        model: 'fixture',
        apiKeys: const [AiApiKey(id: 'key', key: 'test-only-secret')]);
    await expectLater(
        aiGenerateStream(sentenceContextNotesMessages(_sentence(), 'en'),
                providerOverride: provider, throwOnError: true)
            .toList(),
        throwsA(predicate(
            (error) => error.toString().contains('fixture unauthorized'))));
    expect(requests, 1);
    final chat = await aiGenerateStream(
            sentenceContextNotesMessages(_sentence(), 'en'),
            providerOverride: provider)
        .toList();
    expect(chat.last, startsWith('Error: '),
        reason: 'Existing chat error presentation must be preserved');
    expect(requests, 2);
  });

  test(
      'configured AI automatically persists only the final answer via real SSE',
      () async {
    final oldOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = oldOverrides);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    Map<String, dynamic>? requestBody;
    const answer =
        'Word meaning: river edge.\nSentence analysis: She is the subject.';
    server.listen((request) async {
      requestBody = jsonDecode(await utf8.decoder.bind(request).join())
          as Map<String, dynamic>;
      request.response.headers.contentType =
          ContentType('text', 'event-stream', charset: 'utf-8');
      for (final content in ['<think>internal reasoning</think>', answer]) {
        request.response.write('data: ${jsonEncode({
              'id': 'fixture',
              'object': 'chat.completion.chunk',
              'created': 1,
              'model': 'fixture',
              'choices': [
                {
                  'index': 0,
                  'delta': {'content': content},
                  'finish_reason': content == answer ? 'stop' : null
                }
              ]
            })}\n\n');
      }
      request.response.write('data: [DONE]\n\n');
      await request.response.close();
    });
    final provider = AiProvider(
        id: 'fixture',
        title: 'Fixture',
        url: 'http://127.0.0.1:${server.port}/v1',
        protocol: AiProtocol.openai,
        model: 'fixture',
        apiKeys: const [AiApiKey(id: 'key', key: 'test-only-secret')]);
    Prefs().saveAiProviders([provider]);
    Prefs().selectedAiService = provider.id;
    final dao = MemorySentenceContextDao();
    final service = SentenceContextNotesService(dao: dao);
    addTearDown(service.dispose);
    expect(await service.collect(_sentence()), true);
    await service.generate(dao.entries.single);
    expect(dao.entries.single.notes, answer);
    expect(dao.entries.single.notes, isNot(contains('internal reasoning')));
    expect(service.hasFailed(dao.entries.single.id), false);
    expect(requestBody, isNotNull);
    expect(requestBody!['tools'], isNull);
    final messages = requestBody!['messages'] as List;
    expect(jsonDecode(messages.last['content'] as String),
        {'word': _sentence().word, 'sentence': _sentence().sentence});
  });
}
