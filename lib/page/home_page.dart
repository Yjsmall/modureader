import 'package:anx_reader/l10n/modu_strings.dart';
import 'package:anx_reader/l10n/app_language.dart';
import 'dart:async';
import 'package:anx_reader/utils/app_motion.dart';
import 'package:anx_reader/service/notes/reading_link.dart';
import 'package:anx_reader/service/notes/open_reading_link.dart';

import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/enums/sync_trigger.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/home_page/ai_page.dart';
import 'package:anx_reader/page/home_page/remote_library_page.dart';
import 'package:anx_reader/service/initialization_check.dart';
import 'package:anx_reader/page/home_page/bookshelf_page.dart';
import 'package:anx_reader/page/home_page/notes_page.dart';
import 'package:anx_reader/page/home_page/sentence_contexts_page.dart';
import 'package:anx_reader/page/home_page/settings_page.dart';
import 'package:anx_reader/page/home_page/statistics_page.dart';
import 'package:anx_reader/service/receive_file/receive_share.dart';
import 'package:anx_reader/utils/check_update.dart';
import 'package:anx_reader/utils/env_var.dart';
import 'package:anx_reader/utils/get_path/get_temp_dir.dart';
import 'package:anx_reader/utils/load_default_font.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/platform_utils.dart';
import 'package:anx_reader/providers/sync.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/widgets/ai/ai_chat_stream.dart';
import 'package:anx_reader/widgets/navigation/app_navigation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:anx_reader/widgets/home_navigation_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

WebViewEnvironment? webViewEnvironment;

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _currentTab = 'bookshelf';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => initAnx());
  }

  Future<void> _checkWindowsWebview() async {
    final availableVersion = await WebViewEnvironment.getAvailableVersion();
    AnxLog.info('WebView2 version: $availableVersion');

    if (availableVersion == null) {
      SmartDialog.show(
        builder: (context) => AlertDialog(
          title: const Icon(Icons.error),
          content: Text(L10n.of(context).webview2NotInstalled),
          actions: [
            TextButton(
              onPressed: () => {
                launchUrl(
                    Uri.parse(
                        'https://developer.microsoft.com/en-us/microsoft-edge/webview2'),
                    mode: LaunchMode.externalApplication)
              },
              child: Text(L10n.of(context).webview2Install),
            ),
          ],
        ),
      );
    } else {
      webViewEnvironment = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(
            userDataFolder: (await getAnxTempDir()).path),
      );
    }
  }

  void _showDbUpdatedDialog() {
    SmartDialog.show(
      clickMaskDismiss: false,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).commonAttention),
        content: Text(L10n.of(context).dbUpdatedTip),
        actions: [
          TextButton(
            onPressed: () {
              SmartDialog.dismiss();
            },
            child: Text(L10n.of(context).commonOk),
          ),
        ],
      ),
    );
  }

  Future<void> initAnx() async {
    AnxToast.init(context);
    if (AnxPlatform.isWindows) {
      await _checkWindowsWebview();
    }
    if (!mounted) return;
    // Local note links must not wait for optional remote synchronization.
    readingLinkInbox.attach((raw) => openReadingLink(raw, context, ref));
    checkUpdate(false);
    InitializationCheck.check();
    if (Prefs().webdavStatus) {
      await Sync().init();
      unawaited(
          Sync().syncData(SyncDirection.both, null, trigger: SyncTrigger.auto));
    }
    loadDefaultFont();

    if (!mounted) return;

    if (AnxPlatform.isAndroid || AnxPlatform.isIOS || AnxPlatform.isOhos) {
      receiveShareIntent(ref);
    }

    if (DBHelper.updatedDB) {
      _showDbUpdatedDialog();
    }
  }

  @override
  void dispose() {
    readingLinkInbox.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeKey = appLocaleKey(Localizations.localeOf(context));
    List<Map<String, dynamic>> navBarItems = [
      {
        'icon': Icons.menu_book_outlined,
        'label': L10n.of(context).navBarBookshelf,
        'identifier': 'bookshelf'
      },
      {
        'icon': Icons.cloud_download_outlined,
        'label': switch (localeKey) {
          'zh-CN' => '远程',
          'zh-TW' || 'zh-LZH' => '遠程',
          _ => ModuStrings.text(context, '远程书库', 'Remote library'),
        },
        'identifier': 'remoteLibrary'
      },
      if (Prefs().bottomNavigatorShowStatistics)
        {
          'icon': Icons.history,
          'label': switch (localeKey) {
            'zh-CN' => '历史',
            'zh-TW' || 'zh-LZH' => '歷史',
            _ => L10n.of(context).navBarStatistics,
          },
          'identifier': 'statistics'
        },
      if (Prefs().bottomNavigatorShowAI && EnvVar.enableAIFeature)
        {
          'icon': Icons.auto_awesome_outlined,
          'label': L10n.of(context).navBarAI,
          'identifier': 'ai'
        },
      if (Prefs().bottomNavigatorShowNote)
        {
          'icon': Icons.edit_note_outlined,
          'label': L10n.of(context).navBarNotes,
          'identifier': 'notes'
        },
      {
        'icon': Icons.format_quote_outlined,
        'label': ModuStrings.text(context, '句境', 'Sentences'),
        'identifier': 'sentenceContexts'
      },
      {
        'icon': Icons.settings_outlined,
        'label': L10n.of(context).navBarSettings,
        'identifier': 'settings'
      },
    ];

    int currentIndex = navBarItems
        .indexWhere((element) => element['identifier'] == _currentTab);
    if (currentIndex == -1) {
      currentIndex = 0;
      _currentTab = 'bookshelf';
    }

    Widget pages(
      int index,
      BoxConstraints constraints,
      ScrollController? controller,
    ) {
      final page = [
        BookshelfPage(controller: controller),
        const RemoteLibraryPage(),
        if (Prefs().bottomNavigatorShowStatistics)
          StatisticPage(controller: controller),
        if (Prefs().bottomNavigatorShowAI && EnvVar.enableAIFeature)
          AiChatStream(),
        if (Prefs().bottomNavigatorShowNote) NotesPage(controller: controller),
        SentenceContextsPage(controller: controller),
        SettingsPage(controller: controller),
      ];
      return page[index];
    }

    void onBottomTap(int index, bool fromRail) {
      if (navBarItems[index]['identifier'] == 'ai' && !fromRail) {
        showCupertinoSheet(
            context: context,
            scrollableBuilder:
                (BuildContext context, ScrollController controller) {
              Widget widgetBuilder(BuildContext context) => const AiPage();
              return widgetBuilder(context);
            });
        return;
      }
      setState(() {
        _currentTab = navBarItems[index]['identifier'];
      });
    }

    final destinations = navBarItems
        .map((item) => AppDestination(
              id: item['identifier'] as String,
              label: item['label'] as String,
              icon: item['icon'] as IconData,
            ))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Scaffold(
            body: Row(
              children: [
                AppNavigationSidebar(
                  destinations: destinations,
                  selectedIndex: currentIndex,
                  onSelected: (index) => onBottomTap(index, true),
                  extended: constraints.maxWidth >= 1100,
                ),
                Expanded(child: pages(currentIndex, constraints, null)),
              ],
            ),
          );
        } else {
          final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
          if (navBarItems[currentIndex]['identifier'] == 'ai') {
            currentIndex = 0;
          }
          return Scaffold(
            extendBody: true,
            body: BottomBar(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : AppMotion.duration(const Duration(milliseconds: 180)),
              width: constraints.maxWidth,
              offset: HomeNavigationMetrics.barOffset,
              body: (_, controller) => HomeNavigationBody(
                hasBottomBar: !keyboardOpen,
                scrollBehindBar: true,
                child: pages(currentIndex, constraints, controller),
              ),
              showIcon: !keyboardOpen,
              hideOnScroll: Prefs().autoHideBottomBar,
              scrollOpposite: false,
              curve: Curves.easeIn,
              barColor: Colors.transparent,
              iconDecoration: BoxDecoration(
                color: Prefs().autoHideBottomBar
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(500),
              ),
              child: Visibility(
                visible: !keyboardOpen,
                maintainState: true,
                child: SizedBox(
                  height: HomeNavigationMetrics.barHeightFor(context),
                  child: AppNavigationDock(
                    destinations: destinations,
                    selectedIndex: currentIndex,
                    onSelected: (index) => onBottomTap(index, false),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
