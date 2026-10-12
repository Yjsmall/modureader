import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/more_settings.dart';
import 'package:flutter/material.dart';

Widget widgetTitle(String title, ReadingSettings? settings) {
  return Builder(builder: (context) {
    Widget settingsButton = settings == null
        ? const SizedBox(
            height: 48,
          )
        : SizedBox(
            height: 48,
            child: IconButton(
                onPressed: () => showMoreSettings(settings),
                tooltip: L10n.of(context).navBarSettings,
                icon: const Icon(Icons.tune_outlined)),
          );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 28,
                        fontFamily: 'SourceHanSerif',
                        fontWeight: FontWeight.bold))),
            settingsButton,
          ],
        ),
        const Divider(),
      ],
    );
  });
}
