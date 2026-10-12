import 'package:anx_reader/widgets/bookshelf/bookshelf_caption.dart';
import 'package:anx_reader/widgets/bookshelf/bookshelf_style.dart';
import 'package:anx_reader/widgets/bookshelf/continue_reading_card.dart';
import 'package:anx_reader/utils/app_motion.dart';
import 'dart:async';
import 'dart:io';
import 'package:anx_reader/l10n/modu_strings.dart';
import 'package:anx_reader/widgets/home_navigation_metrics.dart';
import 'dart:math';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/enums/sort_field.dart';
import 'package:anx_reader/enums/sort_order.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/tag.dart';
import 'package:anx_reader/providers/book_list.dart';
import 'package:anx_reader/providers/book_filters.dart';
import 'package:anx_reader/providers/tags.dart';
import 'package:anx_reader/service/knowledge/book_knowledge_index_queue.dart';
import 'package:anx_reader/service/knowledge/book_knowledge_index_service.dart';
import 'package:anx_reader/page/search/search_page.dart';
import 'package:anx_reader/utils/color/hash_color.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/widgets/bookshelf/book_import_picker.dart';
import 'package:anx_reader/widgets/bookshelf/book_folder.dart';
import 'package:anx_reader/widgets/bookshelf/book_selection_actions.dart';
import 'package:anx_reader/widgets/bookshelf/stop_vectorization_button.dart';
import 'package:anx_reader/widgets/bookshelf/sync_status_bottom_sheet.dart';
import 'package:anx_reader/widgets/common/container/filled_container.dart';
import 'package:anx_reader/widgets/common/tag_chip.dart';
import 'package:anx_reader/widgets/common/anx_segmented_button.dart';
import 'package:anx_reader/widgets/tips/bookshelf_tips.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookshelfPage extends ConsumerStatefulWidget {
  const BookshelfPage({super.key, this.controller});
  final ScrollController? controller;

  @override
  ConsumerState<BookshelfPage> createState() => BookshelfPageState();
}

class BookshelfPageState extends ConsumerState<BookshelfPage>
    with AutomaticKeepAliveClientMixin {
  late final _scrollController = widget.controller ?? ScrollController();
  final _gridViewKey = GlobalKey();
  bool _dragging = false;
  final GlobalKey _libraryActionsKey = GlobalKey();
  final TextEditingController _editTagController = TextEditingController();
  final Set<int> _selectedBookIds = <int>{};
  bool _selectionMode = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    unawaited(_recoverAutomaticVectorizationQueue());
  }

  Future<void> _recoverAutomaticVectorizationQueue() async {
    final prefs = Prefs();
    if (!prefs.vectorModelEnabled || !prefs.autoVectorizeOnImport) return;

    try {
      final books = await bookDao.selectNotDeleteBooks();
      final indexService = BookKnowledgeIndexService();
      final added = await enqueueMissingBooksForAutomaticIndexing(
        books: books,
        vectorModelEnabled: prefs.vectorModelEnabled,
        autoVectorizeOnImport: prefs.autoVectorizeOnImport,
        hasIndex: indexService.hasIndex,
        isBookAvailable: (book) => File(book.fileFullPath).existsSync(),
        shouldContinue: () =>
            mounted && prefs.vectorModelEnabled && prefs.autoVectorizeOnImport,
      );
      if (added > 0) {
        AnxLog.info('Recovered $added books into the vectorization queue');
      }
    } catch (error, stackTrace) {
      AnxLog.warning(
        'Failed to recover automatic vectorization queue: '
        '$error\n$stackTrace',
      );
    }
  }

  @override
  void dispose() {
    _editTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Theme(
      data: BookshelfStyle.theme(Theme.of(context), eink: Prefs().eInkMode),
      child: Builder(builder: _buildShelf),
    );
  }

  Widget _buildShelf(BuildContext context) {
    final statusFilter = ref.watch(readingStatusFilterNotifierProvider);
    final selectedTags = ref.watch(tagSelectionProvider);
    final tagsAsync = ref.watch(tagListProvider);
    final booksAsync = ref.watch(bookListProvider);
    final listMode = Prefs().bookshelfListMode;
    final visibleBooks = booksAsync.valueOrNull
            ?.expand((group) => group)
            .toList(growable: false) ??
        const <Book>[];
    final selectedBooks = visibleBooks
        .where((book) => _selectedBookIds.contains(book.id))
        .toList(growable: false);
    final unfinished = visibleBooks
        .where((book) =>
            book.readingPercentage > .02 && book.readingPercentage < .98)
        .toList()
      ..sort((a, b) => b.updateTime.compareTo(a.updateTime));
    final continueBook = unfinished.isEmpty ? null : unfinished.first;

    void setBookSelected(Book book, bool selected) {
      setState(() {
        _selectionMode = true;
        if (selected) {
          _selectedBookIds.add(book.id);
        } else {
          _selectedBookIds.remove(book.id);
        }
      });
    }

    void exitSelectionMode() {
      setState(() {
        _selectionMode = false;
        _selectedBookIds.clear();
      });
    }

    VoidCallback? showTagPicker;

    Widget buildFilterBar(Widget viewToggle) {
      final statusChips = [
        _StatusChip(
          label: ModuStrings.text(context, '全部书籍', 'All books'),
          selected: statusFilter == ReadingStatusFilter.none,
          onTap: () {
            ref.read(readingStatusFilterNotifierProvider.notifier).clear();
            ref.read(bookListProvider.notifier).refresh();
          },
        ),
        _StatusChip(
          label: L10n.of(context).bookshelfFilterFinished,
          selected: statusFilter == ReadingStatusFilter.finished,
          onTap: () {
            ref
                .read(readingStatusFilterNotifierProvider.notifier)
                .toggle(ReadingStatusFilter.finished);
            ref.read(bookListProvider.notifier).refresh();
          },
        ),
        _StatusChip(
          label: L10n.of(context).bookshelfFilterReading,
          selected: statusFilter == ReadingStatusFilter.reading,
          onTap: () {
            ref
                .read(readingStatusFilterNotifierProvider.notifier)
                .toggle(ReadingStatusFilter.reading);
            ref.read(bookListProvider.notifier).refresh();
          },
        ),
        _StatusChip(
          label: L10n.of(context).bookshelfFilterNotStarted,
          selected: statusFilter == ReadingStatusFilter.notStarted,
          onTap: () {
            ref
                .read(readingStatusFilterNotifierProvider.notifier)
                .toggle(ReadingStatusFilter.notStarted);
            ref.read(bookListProvider.notifier).refresh();
          },
        ),
      ];

      Future<void> showTagEditDialog(Tag tag) async {
        await TagChip.showEditDialog(
          context: context,
          initialName: tag.name,
          initialColor: tag.color ?? hashColor(tag.name),
          onRename: (newName) async {
            await ref
                .read(tagListProvider.notifier)
                .updateTag(tag.id, newName: newName);
            ref.read(bookListProvider.notifier).refresh();
          },
          onColorChange: (color) async {
            await ref
                .read(tagListProvider.notifier)
                .updateTag(tag.id, color: color);
            ref.read(bookListProvider.notifier).refresh();
          },
          onDelete: () async {
            await ref.read(tagListProvider.notifier).deleteTag(tag.id);
            if (selectedTags.contains(tag.id)) {
              ref.read(tagSelectionProvider.notifier).toggle(tag.id);
            }
            ref.read(bookListProvider.notifier).refresh();
          },
        );
      }

      Future<void> showTagMenu() async {
        final tags = tagsAsync.when(
          data: (value) => value,
          loading: () => const <Tag>[],
          error: (_, __) => const <Tag>[],
        );

        if (!context.mounted) return;

        final renderBox =
            _libraryActionsKey.currentContext?.findRenderObject() as RenderBox?;
        final overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox?;
        if (renderBox == null || overlay == null) return;

        final position = RelativeRect.fromRect(
          Rect.fromPoints(
            renderBox.localToGlobal(Offset.zero, ancestor: overlay),
            renderBox.localToGlobal(
              renderBox.size.bottomRight(Offset.zero),
              ancestor: overlay,
            ),
          ),
          Offset.zero & overlay.size,
        );

        final liveSelected = {...selectedTags};

        final boxMaxWidth = min(MediaQuery.of(context).size.width - 32, 500.0);

        await showMenu<int>(
          popUpAnimationStyle: AppMotion.style,
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          context: context,
          position: position,
          constraints: BoxConstraints(maxHeight: 360, maxWidth: boxMaxWidth),
          items: [
            PopupMenuItem<int>(
              enabled: false,
              padding: EdgeInsets.zero,
              child: Align(
                alignment: Alignment.topRight,
                child: FilledContainer(
                  constraints:
                      BoxConstraints(maxHeight: 340, maxWidth: boxMaxWidth),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: StatefulBuilder(
                    builder: (context, setStateMenu) {
                      return SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (tags.isEmpty)
                              Text(
                                L10n.of(context).tagsEmptyHint,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            // "No tag" virtual option - only show when there are tags
                            if (tags.isNotEmpty)
                              TagChip(
                                label: L10n.of(context).noTagFilter,
                                color: Colors.grey,
                                selected: liveSelected.contains(kNoTagFilterId),
                                onTap: () {
                                  setStateMenu(() {
                                    if (liveSelected.contains(kNoTagFilterId)) {
                                      liveSelected.remove(kNoTagFilterId);
                                    } else {
                                      // Mutual exclusion: clear other tags when selecting "no tag"
                                      liveSelected.clear();
                                      liveSelected.add(kNoTagFilterId);
                                    }
                                  });
                                  ref
                                      .read(tagSelectionProvider.notifier)
                                      .toggle(kNoTagFilterId);
                                  ref.read(bookListProvider.notifier).refresh();
                                },
                                dense: false,
                              ),
                            for (final tag in tags)
                              TagChip(
                                label: tag.name,
                                color: tag.color,
                                selected: liveSelected.contains(tag.id),
                                onTap: () {
                                  setStateMenu(() {
                                    if (liveSelected.contains(tag.id)) {
                                      liveSelected.remove(tag.id);
                                    } else {
                                      // Mutual exclusion: clear "no tag" when selecting a regular tag
                                      liveSelected.remove(kNoTagFilterId);
                                      liveSelected.add(tag.id);
                                    }
                                  });
                                  ref
                                      .read(tagSelectionProvider.notifier)
                                      .toggle(tag.id);
                                  ref.read(bookListProvider.notifier).refresh();
                                },
                                onLongPress: () {
                                  Navigator.of(context).pop();
                                  Future.microtask(
                                      () => showTagEditDialog(tag));
                                },
                                dense: false,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      }

      showTagPicker = () => unawaited(showTagMenu());

      final selectedTagWidgets = tagsAsync.when(
        data: (tags) {
          final tagMap = {for (final t in tags) t.id: t};
          final List<Widget> chips = [];

          // Display "no tag" chip
          if (selectedTags.contains(kNoTagFilterId)) {
            chips.add(Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TagChip(
                label: L10n.of(context).noTagFilter,
                color: Colors.grey,
                selected: true,
                onTap: () {
                  ref
                      .read(tagSelectionProvider.notifier)
                      .toggle(kNoTagFilterId);
                  ref.read(bookListProvider.notifier).refresh();
                },
                dense: true,
              ),
            ));
          }

          // Display regular tag chips
          chips.addAll(selectedTags
              .where((id) => id != kNoTagFilterId)
              .map((id) => tagMap[id])
              .whereType<Tag>()
              .map((tag) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TagChip(
                      label: tag.name,
                      color: tag.color,
                      selected: true,
                      onTap: () {
                        ref.read(tagSelectionProvider.notifier).toggle(tag.id);
                        ref.read(bookListProvider.notifier).refresh();
                      },
                      dense: true,
                    ),
                  )));

          return Row(children: chips);
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      );

      return Container(
        height: 56 +
            (MediaQuery.textScalerOf(context).scale(14) - 14)
                    .clamp(0, double.infinity) *
                1.4,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ...statusChips,
                                selectedTagWidgets,
                              ],
                            ),
                          )))),
            ),
            const SizedBox(width: 8),
            viewToggle,
          ],
        ),
      );
    }

    final viewToggle = IconButton(
      key: const ValueKey('bookshelf-view-toggle'),
      tooltip: listMode
          ? ModuStrings.text(context, '切换为缩略图', 'Switch to thumbnails')
          : ModuStrings.text(context, '切换为列表', 'Switch to list'),
      icon: Icon(listMode ? Icons.grid_view : Icons.view_list_outlined),
      onPressed: () {
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
        setState(() => Prefs().bookshelfListMode = !listMode);
      },
    );

    final importAction = PopupMenuButton<bool>(
      popUpAnimationStyle: AppMotion.style,
      borderRadius: BorderRadius.circular(14),
      tooltip: ModuStrings.text(context, '导入书籍', 'Import books'),
      onSelected: (folder) => pickBooksForImport(context, ref, folder: folder),
      itemBuilder: (context) => [
        PopupMenuItem(
            value: false,
            child: Text(ModuStrings.text(
                context, '选择文件（可多选）', 'Select files (multiple)'))),
        PopupMenuItem(
            value: true,
            child: Text(ModuStrings.text(context, '导入文件夹', 'Import folder'))),
      ],
      child: Ink(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add,
                  size: 20, color: Theme.of(context).colorScheme.onPrimary),
              if (MediaQuery.textScalerOf(context).scale(14) <= 20) ...[
                const SizedBox(width: 8),
                Text(ModuStrings.text(context, '导入书籍', 'Import books'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary)),
              ],
            ]),
          ),
        ),
      ),
    );

    void showSortMenu() {
      final button =
          _libraryActionsKey.currentContext?.findRenderObject() as RenderBox?;
      final overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox?;
      if (button == null || overlay == null) return;
      final anchor = button.localToGlobal(Offset(0, button.size.height),
          ancestor: overlay);
      showMenu(
        popUpAnimationStyle: AppMotion.style,
        context: context,
        position: RelativeRect.fromRect(
            Rect.fromLTWH(anchor.dx, anchor.dy, button.size.width, 0),
            Offset.zero & overlay.size),
        items: [
          for (var sortField in SortFieldEnum.values)
            PopupMenuItem(
                child: Text(
                  sortField.getL10n(context),
                  style: TextStyle(
                    color: sortField == Prefs().sortField
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Prefs().sortField = sortField;
                  ref.read(bookListProvider.notifier).refresh();
                }),
          PopupMenuItem(
            enabled: false,
            child: StatefulBuilder(builder: (_, setState) {
              return Row(
                children: [
                  Expanded(
                    child: AnxSegmentedButton<SortOrderEnum>(
                      onSelectionChanged: (value) {
                        Prefs().sortOrder = value.first;
                        ref.read(bookListProvider.notifier).refresh();
                        setState(() {});
                      },
                      segments: SortOrderEnum.values
                          .map(
                            (e) => SegmentButtonItem(
                              value: e,
                              label: e.getL10n(navigatorKey.currentContext!),
                            ),
                          )
                          .toList(),
                      selected: {Prefs().sortOrder},
                    ),
                  ),
                ],
              );
            }),
          )
        ],
      );
    }

    final libraryActions = PopupMenuButton<String>(
      key: _libraryActionsKey,
      tooltip: ModuStrings.text(context, '书架操作', 'Library actions'),
      icon: const Icon(Icons.more_horiz),
      onSelected: (action) {
        switch (action) {
          case 'select':
            setState(() {
              _selectionMode = true;
              _selectedBookIds.clear();
            });
          case 'sync':
            showSyncStatusBottomSheet(context);
          case 'sort':
            showSortMenu();
          case 'tags':
            showTagPicker?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
            value: 'select',
            enabled: visibleBooks.isNotEmpty,
            child: Row(children: [
              const Icon(Icons.checklist_outlined),
              const SizedBox(width: 12),
              Text(ModuStrings.text(context, '选择', 'Select'))
            ])),
        PopupMenuItem(
            value: 'sync',
            child: Row(children: [
              const Icon(Icons.sync),
              const SizedBox(width: 12),
              Text(L10n.of(context).settingsSync)
            ])),
        PopupMenuItem(
            value: 'sort',
            child: Row(children: [
              const Icon(Icons.sort),
              const SizedBox(width: 12),
              Text(ModuStrings.text(context, '排序', 'Sort'))
            ])),
        PopupMenuItem(
            value: 'tags',
            child: Row(children: [
              const Icon(Icons.sell_outlined),
              const SizedBox(width: 12),
              Text(ModuStrings.text(context, '标签', 'Tags'))
            ])),
      ],
    );

    final searchField = Material(
      key: const ValueKey('bookshelf-search'),
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant, width: .75),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        dense: true,
        minTileHeight: 48,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: const Icon(Icons.search),
        title: Text(L10n.of(context).searchBooksOrNotes,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchPage()),
        ),
      ),
    );

    final libraryHeader = Padding(
      key: const ValueKey('bookshelf-library-header'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: LayoutBuilder(builder: (context, constraints) {
        final heading = Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(ModuStrings.text(context, '收藏的世界', 'Your collection'),
                  style: Theme.of(context).textTheme.titleMedium),
              DecoratedBox(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                          ModuStrings.format(
                              context, '{count} 本', '{count} books',
                              values: {'count': visibleBooks.length}),
                          style: Theme.of(context).textTheme.bodySmall))),
            ]);
        final search = Row(children: [
          Expanded(child: searchField),
          const SizedBox(width: 8),
          libraryActions
        ]);
        if (constraints.maxWidth >= 640) {
          return Row(children: [
            Expanded(child: heading),
            const SizedBox(width: 24),
            SizedBox(width: 360, child: search)
          ]);
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 16), search]);
      }),
    );

    Widget buildBookshelfBody = booksAsync.when(
      data: (books) {
        return LayoutBuilder(builder: (context, constraints) {
          const gutter = 16.0;
          final gap = constraints.maxWidth >= 720 ? 24.0 : 16.0;
          final bottomInset = 24 +
              MediaQuery.paddingOf(context).bottom +
              HomeNavigationClearance.of(context);
          Widget buildEntry(int index) {
            final group = books[index];
            return BookshelfCard(
                key: ValueKey<String>(group.first.groupId == 0
                    ? 'card:book:${group.first.id}'
                    : 'card:folder:${group.first.groupId}'),
                book: group.first,
                selected:
                    group.any((book) => _selectedBookIds.contains(book.id)),
                child: BookFolder(
                  key: ValueKey<String>(group.first.groupId == 0
                      ? 'book:${group.first.id}'
                      : 'folder:${group.first.groupId}'),
                  books: group,
                  listMode: listMode,
                  selectionMode: _selectionMode,
                  selectedBookIds: _selectedBookIds,
                  onSelectionChanged: setBookSelected,
                ));
          }

          final preferredWidth = Prefs().bookCoverWidth;
          final minCoverWidth =
              constraints.maxWidth < 400 && preferredWidth <= 160
                  ? min(preferredWidth, 104.0)
                  : preferredWidth;
          final columns = MediaQuery.textScalerOf(context).scale(13) > 26
              ? 1
              : max(
                  1,
                  (constraints.maxWidth - gutter * 2 + gap) ~/
                      (minCoverWidth + BookshelfStyle.cardPadding * 2 + gap));
          final itemWidth =
              (constraints.maxWidth - gutter * 2 - (columns - 1) * gap) /
                  columns;
          final textHeight = BookshelfCaption.heightFor(context);
          return CustomScrollView(
            key: listMode ? const ValueKey('bookshelf-list') : _gridViewKey,
            controller: _scrollController,
            slivers: [
              if (!_selectionMode &&
                  !listMode &&
                  statusFilter == ReadingStatusFilter.none &&
                  selectedTags.isEmpty &&
                  continueBook != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(gutter, 8, gutter, 24),
                  sliver: SliverToBoxAdapter(
                      child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: ContinueReadingCard(book: continueBook)),
                  )),
                ),
              if (!_selectionMode) SliverToBoxAdapter(child: libraryHeader),
              if (!_selectionMode)
                SliverToBoxAdapter(child: buildFilterBar(viewToggle)),
              if (books.isEmpty)
                const SliverFillRemaining(
                    hasScrollBody: false, child: Center(child: BookshelfTips()))
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(gutter, 16, gutter, bottomInset),
                  sliver: listMode
                      ? SliverList.separated(
                          itemCount: books.length,
                          itemBuilder: (_, index) => buildEntry(index),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                        )
                      : SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisExtent:
                                (itemWidth - BookshelfStyle.cardPadding * 2) *
                                        1.25 +
                                    textHeight +
                                    BookshelfStyle.cardPadding * 2,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: gap,
                          ),
                          delegate: SliverChildBuilderDelegate(
                              (_, index) => buildEntry(index),
                              childCount: books.length),
                        ),
                ),
            ],
          );
        });
      },
      loading: () => const Center(
          child: EinkStaticIndicator(child: CircularProgressIndicator())),
      error: (error, stack) => Center(child: Text(error.toString())),
    );

    Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectionMode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: BookSelectionActions(
              books: selectedBooks,
              onCompleted: exitSelectionMode,
            ),
          ),
        const _KnowledgeQueueBanner(),
        Expanded(
          child: DropTarget(
            onDragDone: (detail) async {
              setState(() {
                _dragging = false;
              });
              await pickBooksForImport(context, ref,
                  droppedPaths: detail.files.map((file) => file.path).toList());
            },
            onDragEntered: (detail) {
              setState(() {
                _dragging = true;
              });
            },
            onDragExited: (detail) {
              setState(() {
                _dragging = false;
              });
            },
            child: Stack(
              children: [
                buildBookshelfBody,
                if (_dragging)
                  Container(
                    color: Theme.of(context).colorScheme.surface.withAlpha(90),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.file_download_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          Text(
                            L10n.of(context).bookshelfDragging,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );

    PreferredSizeWidget appBar = AppBar(
      titleSpacing: 32,
      toolbarHeight: 80 +
          (MediaQuery.textScalerOf(context).scale(24) - 24)
              .clamp(0, double.infinity) +
          (MediaQuery.textScalerOf(context).scale(12) - 12)
              .clamp(0, double.infinity),
      title: _selectionMode
          ? Text(ModuStrings.format(
              context, '已选 {count} 本', '{count} books selected',
              values: {'count': selectedBooks.length}))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(L10n.of(context).navBarBookshelf),
                const SizedBox(height: 4),
                Text(
                    ModuStrings.format(context, '{count} 本藏书', '{count} books',
                        values: {'count': visibleBooks.length}),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
      actions: _selectionMode
          ? [
              TextButton(
                onPressed: visibleBooks.isEmpty
                    ? null
                    : () {
                        setState(() {
                          if (selectedBooks.length == visibleBooks.length) {
                            _selectedBookIds.clear();
                          } else {
                            _selectedBookIds
                              ..clear()
                              ..addAll(visibleBooks.map((book) => book.id));
                          }
                        });
                      },
                child: Text(
                  selectedBooks.length == visibleBooks.length &&
                          visibleBooks.isNotEmpty
                      ? ModuStrings.text(context, '取消全选', 'Deselect all')
                      : ModuStrings.text(context, '全选', 'Select all'),
                ),
              ),
              IconButton(
                tooltip: ModuStrings.text(context, '退出选择', 'Exit selection'),
                onPressed: exitSelectionMode,
                icon: const Icon(Icons.close),
              ),
            ]
          : [
              Padding(
                  padding: const EdgeInsets.only(right: 32),
                  child: importAction)
            ],
    );

    return PopScope(
        canPop: !_selectionMode,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _selectionMode) exitSelectionMode();
        },
        child: Scaffold(
          appBar: appBar,
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Material(
              key: const ValueKey('bookshelf-workspace'),
              color: Theme.of(context).colorScheme.surface,
              child: body,
            ),
          ),
        ));
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: selected
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          backgroundColor: selected
              ? theme.colorScheme.surfaceContainer
              : Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: theme.chipTheme.labelStyle,
        ),
        child: Text(label),
      ),
    );
  }
}

class _KnowledgeQueueBanner extends StatelessWidget {
  const _KnowledgeQueueBanner();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bookKnowledgeIndexQueue,
      builder: (context, _) {
        final active = bookKnowledgeIndexQueue.activeItems;
        if (active.isEmpty) return const SizedBox.shrink();
        final current = bookKnowledgeIndexQueue.current ?? active.first;
        final queued = bookKnowledgeIndexQueue.queuedCount;
        final statusLabel = switch (current.status) {
          BookKnowledgeQueueStatus.queued => '等待开始',
          BookKnowledgeQueueStatus.extracting => '读取章节',
          BookKnowledgeQueueStatus.preparing => '整理章节',
          BookKnowledgeQueueStatus.vectorizing =>
            '生成向量 ${((current.progress ?? 0) * 100).round()}%',
          BookKnowledgeQueueStatus.cancelling => '正在取消',
          _ => '后台处理',
        };

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.hub_outlined, size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '后台向量化：${current.book.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                        queued > 0
                            ? '$statusLabel · 排队 $queued 本'
                            : statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    EinkStaticIndicator(
                        child:
                            LinearProgressIndicator(value: current.progress)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const StopVectorizationButton(compact: true),
            ],
          ),
        );
      },
    );
  }
}
