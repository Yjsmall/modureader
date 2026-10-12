import 'package:anx_reader/dao/sentence_context.dart';
import 'package:anx_reader/l10n/modu_strings.dart';
import 'package:anx_reader/models/sentence_context.dart';
import 'package:anx_reader/widgets/home_navigation_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class SentenceContextsPage extends StatefulWidget {
  const SentenceContextsPage({super.key, this.controller, this.dao});
  final ScrollController? controller;
  final SentenceContextDao? dao;

  @override
  State<SentenceContextsPage> createState() => _SentenceContextsPageState();
}

class _SentenceContextsPageState extends State<SentenceContextsPage> {
  SentenceContextDao get dao => widget.dao ?? sentenceContextDao;
  late Future<List<SentenceContextDocument>> _documents = dao.documents();

  void _reload() => setState(() {
        _documents = dao.documents();
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar:
            AppBar(title: Text(ModuStrings.text(context, '句境', 'Sentences'))),
        body: FutureBuilder<List<SentenceContextDocument>>(
          future: _documents,
          builder: (context, snapshot) {
            if (snapshot.hasError) return _LoadError(onRetry: _reload);
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final documents = snapshot.data!;
            if (documents.isEmpty) {
              return _EmptyCollection(
                message: ModuStrings.text(
                  context,
                  '还没有收集的句子\n阅读时长按单词，点击“语境”',
                  'No saved sentences yet.\nLong press a word while reading, then tap Context.',
                ),
              );
            }
            return ListView.builder(
              controller: widget.controller,
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16 +
                    MediaQuery.paddingOf(context).bottom +
                    HomeNavigationClearance.of(context),
              ),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final document = documents[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text(document.title),
                    subtitle: Text(
                      [
                        if (document.author.isNotEmpty) document.author,
                        ModuStrings.format(
                          context,
                          '{count} 个句子',
                          '{count} sentences',
                          values: {'count': document.count},
                        ),
                      ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SentenceContextCardsPage(
                            document: document,
                            dao: dao,
                          ),
                        ),
                      );
                      if (mounted) _reload();
                    },
                  ),
                );
              },
            );
          },
        ),
      );
}

class SentenceContextCardsPage extends StatefulWidget {
  const SentenceContextCardsPage({
    super.key,
    required this.document,
    required this.dao,
  });
  final SentenceContextDocument document;
  final SentenceContextDao dao;

  @override
  State<SentenceContextCardsPage> createState() =>
      _SentenceContextCardsPageState();
}

class _SentenceContextCardsPageState extends State<SentenceContextCardsPage> {
  late Future<List<SentenceContext>> _sentences = widget.dao.sentences(
    widget.document.bookId,
  );
  final _deleting = <int>{};
  void _reload() => setState(() {
        _sentences = widget.dao.sentences(widget.document.bookId);
      });

  Future<void> _remove(SentenceContext sentence) async {
    final id = sentence.id!;
    if (_deleting.contains(id)) return;
    setState(() => _deleting.add(id));
    try {
      await widget.dao.remove(id);
      if (mounted) _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ModuStrings.text(
                context,
                '删除失败，请重试',
                'Could not delete. Please retry.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.document.title)),
        body: FutureBuilder<List<SentenceContext>>(
          future: _sentences,
          builder: (context, snapshot) {
            if (snapshot.hasError) return _LoadError(onRetry: _reload);
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final sentences = snapshot.data!;
            if (sentences.isEmpty) {
              return _EmptyCollection(
                message: ModuStrings.text(
                  context,
                  '此文档暂无收集的句子',
                  'No saved sentences in this document.',
                ),
              );
            }
            return ListView.builder(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: sentences.length,
              itemBuilder: (context, index) {
                final sentence = sentences[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Chip(
                          label: Text(sentence.word),
                          avatar: const Icon(Icons.format_quote, size: 18),
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          sentence.sentence,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(height: 1.6),
                        ),
                        const SizedBox(height: 16),
                        if (sentence.chapter.isNotEmpty)
                          Text(
                            sentence.chapter,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat.yMd().add_Hm().format(
                                      sentence.createdAt.toLocal(),
                                    ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            IconButton(
                              tooltip: ModuStrings.text(
                                context,
                                '复制句子',
                                'Copy sentence',
                              ),
                              icon: const Icon(
                                Icons.content_copy_outlined,
                                size: 20,
                              ),
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: sentence.sentence),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ModuStrings.text(
                                          context, '已复制', 'Copied'),
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              tooltip: ModuStrings.text(
                                context,
                                '删除句子',
                                'Delete sentence',
                              ),
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: _deleting.contains(sentence.id)
                                  ? null
                                  : () => _remove(sentence),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.format_quote_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(
            ModuStrings.text(
                context, '加载失败，点击重试', 'Could not load. Tap to retry.'),
          ),
        ),
      );
}
