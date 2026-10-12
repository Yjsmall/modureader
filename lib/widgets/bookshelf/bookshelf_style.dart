import 'package:anx_reader/models/book.dart';
import 'package:flutter/material.dart';

/// A page-local palette. Shared book widgets retain their normal appearance
/// when rendered outside the bookshelf.
class BookshelfStyle extends ThemeExtension<BookshelfStyle> {
  const BookshelfStyle({
    required this.peach,
    required this.sand,
    required this.mint,
    required this.featured,
    this.eink = false,
  });

  final Color peach;
  final Color sand;
  final Color mint;
  final Color featured;
  final bool eink;
  static const cardPadding = 10.0;

  static ThemeData theme(ThemeData base, {required bool eink}) {
    final dark = base.brightness == Brightness.dark;
    final style = eink
        ? const BookshelfStyle(
            peach: Colors.white,
            sand: Colors.white,
            mint: Colors.white,
            featured: Colors.white,
            eink: true)
        : BookshelfStyle(
            peach: dark ? const Color(0xFF332925) : const Color(0xFFF8E8DF),
            sand: dark ? const Color(0xFF302F23) : const Color(0xFFF1ECDA),
            mint: dark ? const Color(0xFF233029) : const Color(0xFFE7EEE5),
            featured: dark ? const Color(0xFF392A24) : const Color(0xFFFAE6DC),
          );
    final c = eink
        ? base.colorScheme
        : base.colorScheme.copyWith(
            primary: dark ? const Color(0xFFFFAA91) : const Color(0xFFC94C35),
            onPrimary: dark ? const Color(0xFF3C2119) : Colors.white,
            secondary: dark ? const Color(0xFFA9C8B0) : const Color(0xFF50765D),
            primaryContainer:
                dark ? const Color(0xFF4A2F26) : const Color(0xFFFBE9E2),
            onPrimaryContainer:
                dark ? const Color(0xFFFFDDCE) : const Color(0xFF9A3C2B),
            surface: dark ? base.colorScheme.surface : const Color(0xFFFBF9F5),
            surfaceContainer:
                dark ? const Color(0xFF24221F) : const Color(0xFFFFFDFA),
            surfaceContainerHigh:
                dark ? const Color(0xFF302C25) : const Color(0xFFF0ECE6),
            onSurface: dark ? const Color(0xFFF4EFE8) : const Color(0xFF302D32),
            onSurfaceVariant:
                dark ? const Color(0xFFC5BDB2) : const Color(0xFF716960),
            outlineVariant:
                dark ? const Color(0xFF494237) : const Color(0xFFECE7E0),
          );
    return base.copyWith(
      colorScheme: c,
      scaffoldBackgroundColor: c.surface,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        iconTheme: IconThemeData(color: c.onSurfaceVariant, size: 22),
      ),
      extensions: [
        ...base.extensions.values.where((e) => e is! BookshelfStyle),
        style
      ],
    );
  }

  Color forBook(Book book) {
    if (book.groupId != 0) {
      return [peach, sand, mint][book.groupId.abs() % 3];
    }
    if (book.readingPercentage >= .98) return sand;
    if (book.readingPercentage <= .02) return peach;
    return mint;
  }

  @override
  BookshelfStyle copyWith(
          {Color? peach,
          Color? sand,
          Color? mint,
          Color? featured,
          bool? eink}) =>
      BookshelfStyle(
          peach: peach ?? this.peach,
          sand: sand ?? this.sand,
          mint: mint ?? this.mint,
          featured: featured ?? this.featured,
          eink: eink ?? this.eink);

  @override
  BookshelfStyle lerp(covariant BookshelfStyle? other, double t) {
    if (other == null) return this;
    return BookshelfStyle(
      peach: Color.lerp(peach, other.peach, t)!,
      sand: Color.lerp(sand, other.sand, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      featured: Color.lerp(featured, other.featured, t)!,
      eink: t < .5 ? eink : other.eink,
    );
  }
}

class BookshelfCard extends StatelessWidget {
  const BookshelfCard(
      {super.key,
      required this.book,
      required this.child,
      this.selected = false});
  final Book book;
  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.extension<BookshelfStyle>();
    if (style == null) return child;
    final color = theme.colorScheme.surfaceContainer;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!style.eink)
            BoxShadow(
              color: theme.colorScheme.onSurface.withValues(alpha: .025),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
        ],
      ),
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: .65),
              width: selected ? 1.5 : .75),
        ),
        child: Padding(
          padding: const EdgeInsets.all(BookshelfStyle.cardPadding),
          child: child,
        ),
      ),
    );
  }
}

/// A colored display area inside the white card; the book itself keeps 2:3.
class BookshelfCoverStage extends StatelessWidget {
  const BookshelfCoverStage(
      {super.key, required this.book, required this.child});
  final Book book;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<BookshelfStyle>();
    if (style == null) return child;
    return LayoutBuilder(builder: (context, constraints) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: style.forBook(book),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(constraints.maxWidth >= 180 ? 20 : 12),
          child: Center(child: AspectRatio(aspectRatio: 2 / 3, child: child)),
        ),
      );
    });
  }
}
