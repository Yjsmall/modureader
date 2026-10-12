import 'package:anx_reader/theme/app_theme.dart';
import 'package:anx_reader/l10n/modu_strings.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/service/book.dart';
import 'package:anx_reader/widgets/bookshelf/book_cover.dart';
import 'package:anx_reader/widgets/bookshelf/bookshelf_style.dart';
import 'package:anx_reader/widgets/page_router/reader_cover_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContinueReadingCard extends ConsumerWidget {
  const ContinueReadingCard({super.key, required this.book});
  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final style = theme.extension<BookshelfStyle>()!;
    final heroTag = 'bookshelf-continue-${book.id}';
    void openBook() => pushToReadingPage(ref, context, book, heroTag: heroTag);
    final progress = book.readingPercentage.clamp(0.0, 1.0);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(26),
      side: BorderSide(color: c.outlineVariant),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          if (!style.eink)
            BoxShadow(
              color: AppTheme.surfaceShadow(c, .035),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
        ],
      ),
      child: Material(
        color: style.featured,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: openBook,
          child: LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 560;
            final largeText = MediaQuery.textScalerOf(context).scale(14) > 24;
            final coverWidth = wide ? 126.0 : 80.0;
            final art = SizedBox(
              width: wide ? 200 : 104,
              height: wide ? 224 : 176,
              child: Stack(alignment: Alignment.center, children: [
                Positioned.fill(
                    child: CustomPaint(
                        painter: _CoverOrbitPainter(
                            color: c.primary
                                .withValues(alpha: style.eink ? .4 : .14)))),
                Transform.rotate(
                    angle: style.eink ? 0 : .12,
                    child: Hero(
                      tag: heroTag,
                      createRectTween: readerCoverRectTween,
                      child: DecoratedBox(
                        decoration: BoxDecoration(boxShadow: [
                          if (!style.eink)
                            BoxShadow(
                              color: AppTheme.surfaceShadow(c, .13),
                              blurRadius: 18,
                              offset: const Offset(6, 10),
                            )
                        ]),
                        child: BookCover(
                            book: book,
                            width: coverWidth,
                            height: coverWidth * 1.5,
                            radius: 5),
                      ),
                    )),
                Positioned(
                    right: 0,
                    top: 8,
                    child: ExcludeSemantics(
                        child: Icon(Icons.wb_sunny_outlined,
                            size: 20,
                            color: c.primary.withValues(alpha: .45)))),
              ]),
            );
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    ModuStrings.text(context, '继续上次的故事', 'Continue your story'),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: c.onSurfaceVariant)),
                const SizedBox(height: 14),
                Text(book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge),
                if (book.author.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: c.onSurfaceVariant)),
                ],
                const SizedBox(height: 24),
                ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Column(children: [
                      Row(children: [
                        Expanded(
                            child: Text(
                                ModuStrings.text(
                                    context, '上次读到这里', 'Your last position'),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: c.onSurfaceVariant))),
                        const SizedBox(width: 8),
                        Text('${(progress * 100).round()}%',
                            style: theme.textTheme.bodySmall),
                      ]),
                      const SizedBox(height: 8),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              stopIndicatorColor: Colors.transparent,
                              backgroundColor:
                                  c.onSurface.withValues(alpha: .09))),
                    ])),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: openBook,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.actionColor(c),
                      foregroundColor: AppTheme.onActionColor(c),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  iconAlignment: IconAlignment.end,
                  label: Text(ModuStrings.text(context, '继续阅读', 'Read on')),
                ),
              ],
            );
            return Padding(
              padding: EdgeInsets.all(wide ? 28 : 20),
              child: largeText
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [details, const SizedBox(height: 24), art])
                  : Row(children: [
                      Expanded(child: details),
                      SizedBox(width: wide ? 28 : 12),
                      art
                    ]),
            );
          }),
        ),
      ),
    );
  }
}

class _CoverOrbitPainter extends CustomPainter {
  const _CoverOrbitPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final radius = size.width * .55;
    canvas.drawCircle(size.center(Offset.zero), radius, paint);
    canvas.drawCircle(size.center(Offset.zero), radius * .82, paint);
  }

  @override
  bool shouldRepaint(_CoverOrbitPainter oldDelegate) =>
      oldDelegate.color != color;
}
