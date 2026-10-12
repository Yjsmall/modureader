import 'package:anx_reader/widgets/reading_page/widget_title.dart';
import 'package:anx_reader/widgets/bookshelf/book_cover.dart';
import 'package:anx_reader/widgets/bookshelf/bookshelf_caption.dart';
import 'package:anx_reader/widgets/bookshelf/bookshelf_style.dart';
import 'package:anx_reader/page/home_page/notes_page.dart';
import 'package:anx_reader/providers/notes_statistics.dart';
import 'package:anx_reader/providers/statictics_summary_value.dart';
import 'package:anx_reader/providers/statistic_data.dart';
import 'package:anx_reader/providers/total_reading_time.dart';
import 'package:anx_reader/models/statistic_data_model.dart';
import 'package:anx_reader/page/home_page/statistics_page.dart';
import 'package:anx_reader/widgets/statistic/statistics_dashboard.dart';
import 'package:anx_reader/widgets/statistic/dashboard_tiles/dashboard_tile_registry.dart';
import 'dart:io';
import 'dart:math';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/sync_status.dart';
import 'package:anx_reader/models/tag.dart';
import 'package:anx_reader/models/tb_group.dart';
import 'package:anx_reader/page/home_page/bookshelf_page.dart';
import 'package:anx_reader/page/home_page/settings_page.dart';
import 'package:anx_reader/providers/book_list.dart';
import 'package:anx_reader/providers/sync_status.dart';
import 'package:anx_reader/providers/tags.dart';
import 'package:anx_reader/providers/tb_groups.dart';
import 'package:anx_reader/theme/app_theme.dart';
import 'package:anx_reader/utils/color_scheme.dart';
import 'package:anx_reader/widgets/home_navigation_metrics.dart';
import 'package:anx_reader/widgets/navigation/app_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart' as provider;
import 'package:shared_preferences/shared_preferences.dart';

const destinations = [
  AppDestination(id: 'bookshelf', label: '书架', icon: Icons.menu_book_outlined),
  AppDestination(
      id: 'remoteLibrary', label: '远程书库', icon: Icons.cloud_download_outlined),
  AppDestination(id: 'statistics', label: '历史', icon: Icons.history),
  AppDestination(id: 'ai', label: 'AI', icon: Icons.auto_awesome_outlined),
  AppDestination(id: 'notes', label: '笔记', icon: Icons.edit_note_outlined),
  AppDestination(
      id: 'sentenceContexts', label: '句境', icon: Icons.format_quote_outlined),
  AppDestination(id: 'settings', label: '设置', icon: Icons.settings_outlined),
];

class _Books extends BookList {
  @override
  Future<List<List<Book>>> build() async => [
        for (final (index, title, author, progress) in [
          (1, '山间来信', '林见山', 0.38),
          (2, '慢慢走，深深读', '陈知远', 0.64),
          (3, '日常的诗意', '许清和', 1.0),
          (4, '一间自己的书房', '沈书白', 0.86),
          (5, '时间的花园', '叶南', 0.0),
          (6, '在文字里相遇', '周予安', 1.0),
        ])
          [
            Book.mock().copyWith(
                id: index,
                title: title,
                author: author,
                readingPercentage: progress,
                groupId: 0,
                updateTime:
                    DateTime(2026, 10, 12).subtract(Duration(days: index)),
                filePath: 'file/demo-$index.epub',
                coverPath: 'cover/demo-$index.png')
          ],
      ];
}

class _Groups extends GroupDao {
  @override
  Future<List<TbGroup>> build() async => [];
}

class _Tags extends TagList {
  @override
  Future<List<Tag>> build() async => [];
}

class _Status extends SyncStatus {
  @override
  Future<SyncStatusModel> build() async => const SyncStatusModel(
      localOnly: [],
      remoteOnly: [],
      both: [],
      nonExistent: [],
      downloading: [],
      uploading: []);
}

class _NotesStats extends NotesStatistics {
  @override
  Future<Map<String, int>> build() async =>
      {'numberOfNotes': 45, 'numberOfBooks': 3};
}

class _NotesBooks extends BookIdAndNotes {
  @override
  Future<List<Map<String, dynamic>>> build() async => [
        for (final (id, title, author, count, time) in [
          (101, '山间来信', '林见山', 18, 2400),
          (102, '慢慢走，深深读', '陈知远', 12, 1800),
          (103, '日常的诗意', '许清和', 15, 3100),
        ])
          {
            'bookId': id,
            'book': Book.mock().copyWith(
                id: id,
                title: title,
                author: author,
                coverPath: 'cover/preview-note-$id.png'),
            'numberOfNotes': count,
            'readingTime': time
          },
      ];
}

class _Summary extends StaticticsSummaryValue {
  @override
  Future<int> build(StatisticType type) async => switch (type) {
        StatisticType.totalBooks => 12,
        StatisticType.totalDates => 28,
        StatisticType.totalNotes => 45,
      };
}

class _PeriodStats extends StatisticData {
  @override
  Future<StatisticDataModel> build() async => StatisticDataModel.mock();
}

class _TotalTime extends TotalReadingTime {
  @override
  Future<int> build() async => 125000;
}

late ProviderContainer previewContainer;

const exportPreviews = bool.fromEnvironment('UPDATE_UI_PREVIEWS');

Widget app(Widget child,
        {Brightness brightness = Brightness.light,
        double scale = 1,
        Locale locale = const Locale('zh')}) =>
    UncontrolledProviderScope(
      container: previewContainer,
      child: provider.ChangeNotifierProvider.value(
          value: Prefs(),
          child: Builder(
              builder: (context) => MaterialApp(
                    navigatorKey: navigatorKey,
                    theme: colorSchema(Prefs(), context, brightness),
                    locale: locale,
                    supportedLocales: L10n.supportedLocales,
                    localizationsDelegates: const [
                      L10n.delegate,
                      ...GlobalMaterialLocalizations.delegates
                    ],
                    builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(scale),
                            disableAnimations: true),
                        child: child!),
                    home: RepaintBoundary(
                        key: const ValueKey('preview'), child: child),
                  ))),
    );

Widget shelf(Size size) => Scaffold(
      body: size.width > 600
          ? Row(children: [
              AppNavigationSidebar(
                  destinations: destinations,
                  selectedIndex: 0,
                  onSelected: (_) {},
                  extended: size.width >= 1100),
              const Expanded(child: BookshelfPage())
            ])
          : Stack(children: [
              const HomeNavigationBody(
                  hasBottomBar: true,
                  scrollBehindBar: true,
                  child: BookshelfPage()),
              Positioned(
                  left: 0,
                  right: 0,
                  bottom: HomeNavigationMetrics.barOffset,
                  child: Builder(
                      builder: (context) => SizedBox(
                          height: HomeNavigationMetrics.barHeightFor(context),
                          child: AppNavigationDock(
                              destinations: destinations,
                              selectedIndex: 0,
                              onSelected: (_) {})))),
            ]),
    );

double contrast(Color a, Color b) =>
    (max(a.computeLuminance(), b.computeLuminance()) + .05) /
    (min(a.computeLuminance(), b.computeLuminance()) + .05);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    previewContainer = ProviderContainer(overrides: [
      bookListProvider.overrideWith(_Books.new),
      groupDaoProvider.overrideWith(_Groups.new),
      tagListProvider.overrideWith(_Tags.new),
      syncStatusProvider.overrideWith(_Status.new),
      notesStatisticsProvider.overrideWith(_NotesStats.new),
      bookIdAndNotesProvider.overrideWith(_NotesBooks.new),
      StaticticsSummaryValueProvider(StatisticType.totalBooks)
          .overrideWith(_Summary.new),
      StaticticsSummaryValueProvider(StatisticType.totalDates)
          .overrideWith(_Summary.new),
      statisticDataProvider.overrideWith(_PeriodStats.new),
      totalReadingTimeProvider.overrideWith(_TotalTime.new),
    ]);
    if (!exportPreviews) return;
    final serif = FontLoader('SourceHanSerif')
      ..addFont(rootBundle.load('assets/fonts/SourceHanSerifSC-Regular.otf'))
      ..addFont(rootBundle.load('assets/fonts/SourceHanSerifSC-Bold.otf'));
    await serif.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    // Preview export uses the local CJK system font, never a network font.
    final sans = FontLoader('Roboto')
      ..addFont(Future.value(ByteData.sublistView(
          await File('/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc')
              .readAsBytes())));
    await sans.load();
  });
  tearDownAll(() => previewContainer.dispose());
  setUp(() async {
    // Load deferred language libraries before widget frames are pumped.
    for (final locale in [const Locale('zh'), const Locale('en')]) {
      for (final delegate in L10n.localizationsDelegates) {
        if (delegate.isSupported(locale)) await delegate.load(locale);
      }
    }
    SharedPreferences.setMockInitialValues({});
    await Prefs().initPrefs();
    PackageInfo.setMockInitialValues(
        appName: 'Modu',
        packageName: 'com.modu.reader',
        version: '1.2.7',
        buildNumber: '10117',
        buildSignature: '');
  });

  test('visual redesign preserves the existing font system', () {
    final base = ThemeData(
      fontFamily: 'OriginalApplicationFont',
      appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
              fontFamily: 'SourceHanSerif',
              fontSize: 28,
              fontWeight: FontWeight.bold)),
    );
    final result = AppTheme.apply(base, eink: false);
    expect(result.textTheme, base.textTheme);
    expect(result.appBarTheme.titleTextStyle, base.appBarTheme.titleTextStyle);
  });

  testWidgets('reading tool titles retain their original serif font',
      (tester) async {
    await tester.pumpWidget(app(Scaffold(body: widgetTitle('文本设置', null))));
    await tester.pumpAndSettle();
    final title = tester.widget<Text>(find.text('文本设置'));
    expect(title.style!.fontFamily, 'SourceHanSerif');
    expect(title.style!.fontSize, 28);
    expect(title.style!.fontWeight, FontWeight.bold);
  });

  test('text and selected controls remain legible across palettes', () {
    for (final brightness in Brightness.values) {
      for (final seed in [AppTheme.defaultSeed, Colors.blue, Colors.purple]) {
        final c = AppTheme.scheme(seed: seed, brightness: brightness);
        for (final surface in [
          c.surface,
          c.surfaceContainer,
          c.surfaceContainerLow,
          if (brightness == Brightness.dark) ...[
            c.surfaceContainerHigh,
            c.surfaceContainerHighest,
          ]
        ]) {
          expect(contrast(c.onSurface, surface), greaterThanOrEqualTo(4.5));
          expect(
              contrast(c.onSurfaceVariant, surface), greaterThanOrEqualTo(4.5));
        }
        expect(contrast(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
        expect(contrast(c.onPrimaryContainer, c.primaryContainer),
            greaterThanOrEqualTo(4.5));
        if (brightness == Brightness.dark) {
          expect(contrast(c.onSecondaryContainer, c.secondaryContainer),
              greaterThanOrEqualTo(4.5));
          expect(contrast(c.onTertiaryContainer, c.tertiaryContainer),
              greaterThanOrEqualTo(4.5));
          expect(contrast(AppTheme.onActionColor(c), AppTheme.actionColor(c)),
              greaterThanOrEqualTo(4.5));
          final oled = AppTheme.scheme(
              seed: seed, brightness: brightness, trueBlack: true);
          expect(oled.surface, Colors.black);
          expect(contrast(oled.onSurface, oled.surface),
              greaterThanOrEqualTo(4.5));
        }
      }
    }
  });

  testWidgets('More exposes every secondary page and selected state',
      (tester) async {
    var selected = 0;
    await tester.pumpWidget(app(StatefulBuilder(
        builder: (context, setState) => Scaffold(
              bottomNavigationBar: AppNavigationDock(
                  destinations: destinations,
                  selectedIndex: selected,
                  onSelected: (i) => setState(() => selected = i)),
            ))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('更多'));
    await tester.pumpAndSettle();
    expect(find.text('远程书库'), findsOneWidget);
    expect(find.text('历史'), findsOneWidget);
    expect(find.text('句境'), findsOneWidget);
    await tester.tap(find.text('句境'));
    await tester.pumpAndSettle();
    expect(selected, 5);
    expect(find.byType(BottomSheet), findsNothing);
    final semantics = tester.getSemantics(find.text('更多'));
    expect(
        semantics,
        matchesSemantics(
            label: '更多',
            isButton: true,
            isSelected: true,
            hasSelectedState: true,
            hasTapAction: true,
            isFocusable: true));
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact navigation handles hidden optional destinations',
      (tester) async {
    await tester.pumpWidget(app(Scaffold(
        bottomNavigationBar: AppNavigationDock(destinations: [
      destinations[0],
      destinations[1],
      destinations[5],
      destinations[6]
    ], selectedIndex: 0, onSelected: (_) {}))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('更多'));
    await tester.pumpAndSettle();
    expect(find.text('远程书库'), findsOneWidget);
    expect(find.text('句境'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final (name, size, scale, brightness) in [
    ('bookshelf-phone-light', const Size(375, 812), 1.0, Brightness.light),
    ('bookshelf-phone-dark', const Size(375, 812), 1.0, Brightness.dark),
    ('bookshelf-desktop', const Size(1440, 900), 1.0, Brightness.light),
    ('bookshelf-landscape', const Size(812, 375), 1.0, Brightness.light),
    ('bookshelf-large-text', const Size(375, 812), 2.0, Brightness.light),
    ('bookshelf-largest-text', const Size(375, 812), 3.2, Brightness.light),
  ]) {
    testWidgets('$name layout and view toggle', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester
          .pumpWidget(app(shelf(size), brightness: brightness, scale: scale));
      await tester.pumpAndSettle();
      if (find.byType(SliverGrid).evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('bookshelf-view-toggle')),
          240,
          scrollable: find
              .descendant(
                  of: find.byType(CustomScrollView),
                  matching: find.byType(Scrollable))
              .first,
        );
        await tester.pumpAndSettle();
      }
      expect(find.byType(SliverGrid), findsOneWidget);
      final workspace = find.byKey(const ValueKey('bookshelf-workspace'));
      expect(workspace, findsOneWidget);
      expect(find.text('全部书籍'), findsOneWidget);
      final panel = tester.getRect(workspace);
      expect(
          tester.getRect(find.byTooltip('导入书籍')).bottom, lessThan(panel.top));
      final actions = find.byTooltip('书架操作');
      if (actions.evaluate().isNotEmpty) {
        expect(tester.getRect(actions).top, greaterThan(panel.top));
      }
      if (size.width == 375 && scale == 1) {
        await tester.tap(find.byTooltip('书架操作'));
        await tester.pumpAndSettle();
        expect(find.text('选择'), findsOneWidget);
        expect(find.text('排序'), findsOneWidget);
        expect(find.text('标签'), findsOneWidget);
        await tester.tap(find.text('选择'));
        await tester.pumpAndSettle();
        expect(find.text('已选 0 本'), findsOneWidget);
        await tester.tap(find.byTooltip('退出选择'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      // These are different-length titles. Their actual rendered edges and
      // metadata lines must align, including at accessibility text sizes.
      final captions = find.byType(BookshelfCaption);
      if (captions.evaluate().length >= 2) {
        final firstCaption = tester.getRect(captions.at(0));
        final secondCaption = tester.getRect(captions.at(1));
        expect(firstCaption.top, closeTo(secondCaption.top, 0.01));
        expect(firstCaption.height, closeTo(secondCaption.height, 0.01));
        final covers = find.descendant(
            of: find.byType(SliverGrid), matching: find.byType(BookCover));
        final card = tester.getRect(find.byType(BookshelfCard).first);
        final cover = tester.getRect(covers.at(0));
        expect(
            tester
                .getTopLeft(find
                    .descendant(
                        of: find.byType(AppBar), matching: find.text('书架'))
                    .first)
                .dx,
            closeTo(card.left, .01));
        if (find.text('收藏的世界').evaluate().isNotEmpty) {
          expect(tester.getTopLeft(find.text('收藏的世界')).dx,
              closeTo(card.left, .01));
        }
        expect(cover.center.dx, closeTo(card.center.dx, .01));
        expect(cover.height, closeTo(cover.width * 1.5, .01));
        if (size.width == 375 && scale == 1) {
          expect(
              tester
                  .getRect(find.byKey(const ValueKey('bookshelf-search')))
                  .left,
              closeTo(card.left, .01));
        }
        expect(tester.getRect(covers.at(0)).bottom,
            closeTo(tester.getRect(covers.at(1)).bottom, 0.01));
        expect(tester.getTopLeft(find.text('林见山').last).dy,
            closeTo(tester.getTopLeft(find.text('陈知远').last).dy, 0.01));
      }
      if (exportPreviews && scale == 1 && size.height > 375) {
        await expectLater(find.byKey(const ValueKey('preview')),
            matchesGoldenFile('../../docs/design/previews/$name.png'));
      }
      await tester
          .ensureVisible(find.byKey(const ValueKey('bookshelf-view-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bookshelf-view-toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('bookshelf-list')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets(
        'settings desktop ${brightness.name} uses the same visual system',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(
          Scaffold(
              body: Row(children: [
            AppNavigationSidebar(
                destinations: destinations,
                selectedIndex: 6,
                onSelected: (_) {},
                extended: true),
            const Expanded(child: SettingsPage())
          ])),
          brightness: brightness));
      await tester.pumpAndSettle();
      expect(find.text('阅读与外观'), findsOneWidget);
      expect(find.byKey(const ValueKey('settings-workspace')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('settings-detail-panel')), findsOneWidget);
      expect(find.text('主题 · 显示 · 封面'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (exportPreviews) {
        await expectLater(
            find.byKey(const ValueKey('preview')),
            matchesGoldenFile(
                '../../docs/design/previews/settings-desktop${brightness == Brightness.dark ? '-dark' : ''}.png'));
      }
    });
  }

  for (final (name, page, index, brightness, scale) in [
    ('notes-phone-light', const NotesPage(), 4, Brightness.light, 1.0),
    ('notes-phone-dark', const NotesPage(), 4, Brightness.dark, 1.0),
    ('notes-phone-large-text', const NotesPage(), 4, Brightness.light, 3.2),
    ('settings-phone-light', const SettingsPage(), 6, Brightness.light, 1.0),
    ('settings-phone-dark', const SettingsPage(), 6, Brightness.dark, 1.0),
    (
      'settings-phone-large-text',
      const SettingsPage(),
      6,
      Brightness.light,
      3.2
    ),
  ]) {
    testWidgets('$name shared style layout', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(
          Stack(children: [
            HomeNavigationBody(
                hasBottomBar: true, scrollBehindBar: true, child: page),
            Positioned(
                left: 0,
                right: 0,
                bottom: HomeNavigationMetrics.barOffset,
                child: Builder(
                    builder: (context) => SizedBox(
                        height: HomeNavigationMetrics.barHeightFor(context),
                        child: AppNavigationDock(
                            destinations: destinations,
                            selectedIndex: index,
                            onSelected: (_) {})))),
          ]),
          brightness: brightness,
          scale: scale));
      await tester.pumpAndSettle();
      if (index == 4) {
        expect(find.byKey(const ValueKey('notes-overview')), findsOneWidget);
        expect(find.byType(BookCover), findsWidgets);
      } else {
        expect(find.text('阅读与外观'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      if (exportPreviews && scale == 1) {
        await expectLater(find.byKey(const ValueKey('preview')),
            matchesGoldenFile('../../docs/design/previews/$name.png'));
      }
    });
  }

  testWidgets('desktop category and description follow language changes',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const page = Scaffold(body: SettingsPage());
    await tester.pumpWidget(app(page));
    await tester.pumpAndSettle();
    final panel = find.byKey(const ValueKey('settings-detail-panel'));
    expect(
        find.descendant(of: panel, matching: find.text('外观')), findsOneWidget);
    await tester.pumpWidget(app(page, locale: const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: panel, matching: find.text('Appearance')),
        findsOneWidget);
    expect(find.descendant(of: panel, matching: find.text('外观')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history cards share the confirmed style on a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Prefs().statisticsDashboardTiles = [
      StatisticsDashboardTileType.readingDaysTotal,
      StatisticsDashboardTileType.booksTotal,
      StatisticsDashboardTileType.periodSummary,
    ];
    await tester.pumpWidget(app(Scaffold(
      appBar: AppBar(title: const Text('历史')),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const StatisticsDashboard(),
            const SizedBox(height: 24),
            BookStatisticItem(
                book: Book.mock().copyWith(
                    title: '山间来信',
                    author: '林见山',
                    coverPath: 'cover/preview-history.png'),
                readingTime: 2400),
          ])),
    )));
    await tester.pumpAndSettle();
    expect(find.byType(BookCover), findsOneWidget);
    expect(tester.takeException(), isNull);
    if (exportPreviews) {
      await expectLater(
          find.byKey(const ValueKey('preview')),
          matchesGoldenFile(
              '../../docs/design/previews/history-cards-phone-light.png'));
    }
  });

  testWidgets('e-ink retains monochrome surfaces and disabled motion',
      (tester) async {
    Prefs().eInkMode = true;
    late ThemeData theme;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      theme = colorSchema(Prefs(), context, Brightness.dark);
      return Theme(
          data: theme, child: const Scaffold(body: BookshelfTipsPlaceholder()));
    })));
    expect(theme.colorScheme.surface, Colors.white);
    expect(theme.colorScheme.primary, Colors.black);
    expect(theme.splashFactory, NoSplash.splashFactory);
  });
}

class BookshelfTipsPlaceholder extends StatelessWidget {
  const BookshelfTipsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      Text('阅读', style: Theme.of(context).textTheme.bodyLarge);
}
