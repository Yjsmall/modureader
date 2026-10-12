import 'package:anx_reader/widgets/common/container/filled_container.dart';
import 'package:anx_reader/widgets/settings/settings_tile.dart';
import 'package:flutter/material.dart';

abstract class AbstractSettingsSection extends StatelessWidget {
  const AbstractSettingsSection({super.key});
}

class SettingsSection extends AbstractSettingsSection {
  const SettingsSection({
    super.key,
    required this.tiles,
    this.margin,
    this.title,
  });

  final List<AbstractSettingsTile> tiles;
  final EdgeInsetsDirectional? margin;
  final Widget? title;

  @override
  Widget build(BuildContext context) {
    return buildSectionBody(context);
  }

  Widget buildSectionBody(BuildContext context) {
    final tileList = buildTileList();

    if (title == null) {
      return tileList;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            top: 24,
            bottom: 12,
            start: 16,
            end: 16,
          ),
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
            child: title!,
          ),
        ),
        Padding(
          padding:
              margin ?? const EdgeInsetsDirectional.symmetric(horizontal: 16),
          child: FilledContainer(
            padding: EdgeInsetsGeometry.zero,
            child: tileList,
          ),
        ),
      ],
    );
  }

  Widget buildTileList() {
    return Column(
      children: tiles,
    );
  }
}

class CustomSettingsSection extends AbstractSettingsSection {
  const CustomSettingsSection({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
