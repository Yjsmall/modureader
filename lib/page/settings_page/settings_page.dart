import 'package:anx_reader/widgets/settings/settings_title.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsPageBuilder extends StatelessWidget {
  const SettingsPageBuilder(
      {super.key,
      required this.isMobile,
      required this.id,
      required this.selectedIndex,
      required this.setDetail,
      required this.icon,
      required this.title,
      this.titleBuilder,
      required this.sections,
      required this.subTitles});

  final bool isMobile;
  final int id;
  final int selectedIndex;
  final void Function(Widget detail, int id) setDetail;
  final Icon icon;
  final String title;
  final String Function(BuildContext)? titleBuilder;
  final Widget sections;
  final List<String> subTitles;

  @override
  Widget build(BuildContext context) {
    return settingsTitle(
      icon: icon,
      title: title,
      isMobile: isMobile,
      id: id,
      selectedIndex: selectedIndex,
      setDetail: setDetail,
      subPage: SettingsPageBody(
        title: title,
        titleBuilder: titleBuilder,
        isMobile: isMobile,
        sections: sections,
        description: subTitles.join(' · '),
      ),
      subtitle: subTitles,
    );
  }
}

class SettingsPageBody extends StatefulWidget {
  const SettingsPageBody({
    super.key,
    required this.title,
    this.titleBuilder,
    required this.isMobile,
    required this.sections,
    this.description,
  });

  final String title;
  final String Function(BuildContext)? titleBuilder;
  final bool isMobile;
  final Widget sections;
  final String? description;

  @override
  State<SettingsPageBody> createState() => _SettingsPageBodyState();
}

class _SettingsPageBodyState extends State<SettingsPageBody> {
  @override
  Widget build(BuildContext context) {
    // Register the locale dependency on this page, not on the cached sliver
    // callback, so an already-open page refreshes its navigation title.
    final title = widget.titleBuilder?.call(context) ?? widget.title;
    if (!widget.isMobile) {
      final theme = Theme.of(context);
      return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                key: const ValueKey('settings-detail-panel'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: theme.textTheme.titleLarge),
                          if (widget.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text(widget.description!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ]),
                  ),
                  const Divider(height: 1),
                  Expanded(
                      child: MediaQuery.removePadding(
                    removeTop: true,
                    context: context,
                    child: widget.sections,
                  )),
                ],
              )));
    }
    return CupertinoPageScaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return widget.isMobile
              ? <Widget>[
                  CupertinoSliverNavigationBar(
                    largeTitle: Text(title),
                    backgroundColor:
                        Theme.of(context).appBarTheme.backgroundColor,
                  )
                ]
              : <Widget>[];
        },
        body: MediaQuery.removePadding(
          removeTop: true,
          context: context,
          child: widget.sections,
        ),
      ),
    );
  }
}
