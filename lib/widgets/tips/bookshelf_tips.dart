import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/common/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:anx_reader/widgets/bookshelf/book_import_picker.dart';
import 'package:anx_reader/l10n/modu_strings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookshelfTips extends ConsumerWidget {
  const BookshelfTips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: L10n.of(context).bookshelfTips_1,
        description: L10n.of(context).bookshelfTips_2,
        action: FilledButton.icon(
          onPressed: () => pickBooksForImport(context, ref),
          icon: const Icon(Icons.add),
          label: Text(
              ModuStrings.text(context, '导入第一本书', 'Import your first book')),
        ),
      );
}
