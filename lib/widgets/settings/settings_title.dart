import 'package:anx_reader/utils/app_motion.dart';
import 'package:anx_reader/widgets/settings/settings_section.dart';
import 'package:flutter/material.dart';

Widget settingsTitle({
  required Icon icon,
  required String title,
  required bool isMobile,
  required int id,
  required int selectedIndex,
  required Function setDetail,
  required Widget subPage,
  required List<String> subtitle,
}) {
  return Builder(builder: (context) {
    final c = Theme.of(context).colorScheme;
    final selected = !isMobile && selectedIndex == id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? c.primaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12, vertical: isMobile ? 8 : 0),
          minLeadingWidth: 22,
          minTileHeight: isMobile ? 72 : 48,
          titleAlignment: ListTileTitleAlignment.center,
          horizontalTitleGap: 12,
          leading: Icon(icon.icon,
              color: selected ? c.onPrimaryContainer : c.onSurfaceVariant,
              size: 22),
          title: Text(title),
          trailing: isMobile
              ? const Icon(Icons.chevron_right, size: 18)
              : selected
                  ? const Icon(Icons.check, size: 18)
                  : null,
          selected: selected,
          subtitle: isMobile
              ? Text(subtitle.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall)
              : null,
          onTap: () {
            if (!isMobile) {
              setDetail(subPage, id);
              return;
            }
            Navigator.push(
              context,
              MotionCupertinoPageRoute(builder: (context) => subPage),
            );
          },
        ),
      ),
    );
  });
}

Widget settingsSections({
  required List<AbstractSettingsSection> sections,
}) {
  // return SettingsList(sections: sections);
  return ListView.builder(
    itemCount: sections.length,
    itemBuilder: (context, index) {
      return sections[index];
    },
  );
}
