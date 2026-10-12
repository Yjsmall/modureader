import 'package:anx_reader/theme/app_theme.dart';
import 'package:anx_reader/l10n/modu_strings.dart';
import 'package:anx_reader/widgets/home_navigation_metrics.dart';
import 'package:flutter/material.dart';

class AppDestination {
  const AppDestination(
      {required this.id, required this.label, required this.icon});
  final String id;
  final String label;
  final IconData icon;
}

/// A quiet, opaque dock. Secondary destinations remain one tap away in More.
class AppNavigationDock extends StatelessWidget {
  const AppNavigationDock(
      {super.key,
      required this.destinations,
      required this.selectedIndex,
      required this.onSelected});
  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final preferred = ['bookshelf', 'notes', 'ai', 'settings'];
    final visible = <int>[
      for (final id in preferred)
        if (destinations.any((d) => d.id == id))
          destinations.indexWhere((d) => d.id == id),
    ];
    final overflow = <int>[
      for (var i = 0; i < destinations.length; i++)
        if (!visible.contains(i)) i
    ];
    if (overflow.isNotEmpty) visible.insert(visible.length - 1, -1);
    return Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: HomeNavigationMetrics.horizontalInset),
        child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(HomeNavigationMetrics.barRadius),
              boxShadow: [
                if ((Theme.of(context).cardTheme.elevation ?? 0) > 0)
                  BoxShadow(
                      color: AppTheme.surfaceShadow(c, .055),
                      blurRadius: 20,
                      offset: const Offset(0, 6)),
              ],
            ),
            child: Material(
              color: AppTheme.darkOverlaySurface(c),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(HomeNavigationMetrics.barRadius),
                side: BorderSide(color: c.outlineVariant, width: .75),
              ),
              surfaceTintColor: Colors.transparent,
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  for (final index in visible)
                    Expanded(
                      child: _DockItem(
                        label: index == -1
                            ? ModuStrings.text(context, '更多', 'More')
                            : destinations[index].label,
                        icon: index == -1
                            ? Icons.more_horiz
                            : destinations[index].icon,
                        selected: index == selectedIndex ||
                            (index == -1 && overflow.contains(selectedIndex)),
                        onTap: index == -1
                            ? () => _showMore(context, overflow)
                            : () => onSelected(index),
                      ),
                    ),
                ],
              ),
            )));
  }

  void _showMore(BuildContext context, List<int> indices) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(ModuStrings.text(context, '更多', 'More'),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 18)),
              ),
              for (final index in indices)
                ListTile(
                  leading: Icon(destinations[index].icon),
                  title: Text(destinations[index].label),
                  selected: index == selectedIndex,
                  trailing: Icon(index == selectedIndex
                      ? Icons.check
                      : Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(index);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final foreground = selected ? c.primary : c.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      focusable: true,
      onTap: onTap,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: foreground),
                const SizedBox(height: 4),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500)),
                const SizedBox(height: 6),
                SizedBox(
                    width: 16,
                    height: 2,
                    child: ColoredBox(
                        color: selected ? foreground : Colors.transparent)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppNavigationSidebar extends StatelessWidget {
  const AppNavigationSidebar(
      {super.key,
      required this.destinations,
      required this.selectedIndex,
      required this.onSelected,
      required this.extended});
  final List<AppDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      width: extended ? 216 : 88,
      decoration: BoxDecoration(
          color: c.surfaceContainer,
          border: Border(right: BorderSide(color: c.outlineVariant))),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: extended ? 24 : 12, vertical: 24),
                child: Row(
                  mainAxisAlignment: extended
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book_outlined, color: c.primary, size: 24),
                    if (extended) ...[
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(ModuStrings.text(context, '默读', 'Modu'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontSize: 18))),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (var index = 0; index < destinations.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: extended
                            ? ListTile(
                                minLeadingWidth: 24,
                                horizontalTitleGap: 12,
                                minTileHeight: 52,
                                leading: Icon(destinations[index].icon),
                                title: Text(destinations[index].label),
                                selected: selectedIndex == index,
                                selectedTileColor: c.primaryContainer,
                                selectedColor: c.onPrimaryContainer,
                                onTap: () => onSelected(index),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 0),
                              )
                            : Material(
                                color: selectedIndex == index
                                    ? c.primaryContainer
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: _DockItem(
                                    label: destinations[index].label,
                                    icon: destinations[index].icon,
                                    selected: selectedIndex == index,
                                    onTap: () => onSelected(index)),
                              ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
