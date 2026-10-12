import 'package:flutter/material.dart';
import 'package:anx_reader/l10n/modu_strings.dart';
import 'package:anx_reader/widgets/bookshelf/bookshelf_style.dart';

/// Every shelf entry reserves the same title, author and progress baselines.
/// The cover stays the same height whether a title takes one or two lines.
class BookshelfCaption extends StatelessWidget {
  const BookshelfCaption(
      {super.key,
      required this.title,
      required this.subtitle,
      this.progress,
      this.trailing});
  final String title;
  final String subtitle;
  final double? progress;
  final Widget? trailing;

  static double heightFor(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final titleLineHeight =
        Theme.of(context).textTheme.bodyMedium?.height ?? 1.2;
    final card = Theme.of(context).extension<BookshelfStyle>() != null;
    return (card ? 37 : 26) +
        scaler.scale(card ? 14 : 13) * titleLineHeight * 2 +
        scaler.scale(card ? 11 : 9) * 1.4 +
        (card ? scaler.scale(10) * 1.4 : 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final card = theme.extension<BookshelfStyle>() != null;
    if (card) {
      final status = progress == null
          ? null
          : progress! >= .98
              ? ModuStrings.text(context, '已读完', 'Finished')
              : progress! <= .02
                  ? ModuStrings.text(context, '未开始', 'Unread')
                  : ModuStrings.text(context, '正在读', 'Reading');
      final ink = progress != null && progress! >= .98
          ? theme.colorScheme.secondary
          : theme.colorScheme.primary;
      return SizedBox(
          height: heightFor(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 12),
              SizedBox(
                  height: scaler.scale(14) *
                      (theme.textTheme.bodyMedium?.height ?? 1.2) *
                      2,
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: Tooltip(
                                message: title,
                                child: Text(title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)))),
                        if (trailing != null) trailing!,
                      ])),
              const SizedBox(height: 4),
              SizedBox(
                  height: scaler.scale(11) * 1.4,
                  child: Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          color: theme.colorScheme.onSurfaceVariant))),
              const SizedBox(height: 10),
              SizedBox(
                  height: scaler.scale(10) * 1.4,
                  child: Row(children: [
                    if (status != null) ...[
                      DecoratedBox(
                          decoration:
                              BoxDecoration(color: ink, shape: BoxShape.circle),
                          child: const SizedBox(width: 4, height: 4)),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                        child: Text(status ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant))),
                    if (progress != null)
                      Text('${(progress!.clamp(0, 1) * 100).round()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant)),
                  ])),
              const SizedBox(height: 8),
              if (progress != null)
                ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                        value: progress!.clamp(0, 1),
                        minHeight: 3,
                        color: ink,
                        stopIndicatorColor: Colors.transparent,
                        backgroundColor: theme.colorScheme.outlineVariant))
              else
                const SizedBox(height: 3),
            ]),
          ));
    }
    return SizedBox(
      height: heightFor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: scaler.scale(card ? 14 : 13) *
                (theme.textTheme.bodyMedium?.height ?? 1.2) *
                2,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Tooltip(
                  message: title,
                  triggerMode: TooltipTriggerMode.manual,
                  child: Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: card ? 14 : 13,
                          fontWeight: FontWeight.bold)),
                )),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: scaler.scale(card ? 11 : 9) * 1.4,
            child: Row(children: [
              Expanded(
                  child: Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: card ? 11 : 9,
                          fontWeight: FontWeight.w300,
                          color: card
                              ? theme.colorScheme.onSurfaceVariant
                              : null))),
              if (progress != null) ...[
                const SizedBox(width: 8),
                Text('${(progress! * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: card ? 11 : 9,
                        fontWeight: FontWeight.w300,
                        color:
                            card ? theme.colorScheme.onSurfaceVariant : null)),
              ],
            ]),
          ),
          const SizedBox(height: 8),
          if (progress != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                  value: progress!.clamp(0, 1),
                  minHeight: card ? 4 : 2,
                  stopIndicatorColor: card ? Colors.transparent : null,
                  backgroundColor: card
                      ? theme.colorScheme.onSurface.withValues(alpha: .1)
                      : theme.colorScheme.outlineVariant),
            )
          else
            const SizedBox(height: 2),
        ],
      ),
    );
  }
}
