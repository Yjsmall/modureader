import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/widgets/bookshelf/bookshelf_style.dart';
import 'package:flutter/material.dart';

class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.book,
    this.height,
    this.width,
    this.radius,
  });

  final Book book;
  final double? height;
  final double? width;
  final double? radius;

  // Calculate text color based on background brightness
  Color _getContrastColor(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    final double effectiveRadius = radius ?? 6;
    final BorderRadius borderRadius = BorderRadius.circular(effectiveRadius);
    final File file = File(book.coverFullPath);

    Widget child;

    if (file.existsSync()) {
      child = Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(file),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      // Default cover with responsive text and icon
      child = LayoutBuilder(
        builder: (context, constraints) {
          final coverWidth = constraints.maxWidth;

          // Calculate responsive sizes based on width
          final titleFontSize = (coverWidth * 0.12).clamp(4.0, 28.0);
          final authorFontSize = (coverWidth * 0.08).clamp(3.0, 16.0);
          final padding = coverWidth * 0.12;

          final scheme = Theme.of(context).colorScheme;
          final shelfStyle = Theme.of(context).extension<BookshelfStyle>();
          final backgroundColor = Prefs().eInkMode
              ? Colors.white
              : shelfStyle == null
                  ? scheme.surfaceContainerHigh
                  : Color.alphaBlend(
                      scheme.surfaceContainer.withValues(alpha: .72),
                      shelfStyle.forBook(book));
          final textColor = _getContrastColor(backgroundColor);

          final showTitle = Prefs().showBookTitleOnDefaultCover;
          final showAuthor = Prefs().showAuthorOnDefaultCover;

          return Container(
            color: backgroundColor,
            child: Stack(
              children: [
                // Text content (title at top, author at bottom)
                if (showTitle || showAuthor)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        padding, padding * 2, padding, padding * 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title at top
                        if (showTitle)
                          Text(
                            book.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              height: 1.2,
                            ),
                          ),
                        const Spacer(),
                        // Author at bottom
                        if (showAuthor)
                          Text(
                            book.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: authorFontSize,
                              fontWeight: FontWeight.w300,
                              color: textColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                Positioned(
                  left: padding,
                  right: padding,
                  top: padding,
                  child: Container(
                      height: 1, color: textColor.withValues(alpha: 0.15)),
                ),
              ],
            ),
          );
        },
      );
    }

    final RoundedSuperellipseBorder borderShape = RoundedSuperellipseBorder(
      borderRadius: borderRadius,
      side: BorderSide(
        width: 0.5,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );

    return SizedBox(
      height: height,
      width: width,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: ShapeDecoration(
          shape: borderShape,
        ),
        child: ClipRSuperellipse(
          borderRadius: borderRadius,
          child: MediaQuery.withNoTextScaling(child: child),
        ),
      ),
    );
  }
}
