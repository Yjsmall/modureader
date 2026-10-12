import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/common/app_empty_state.dart';
import 'package:flutter/material.dart';

class NotesTips extends StatelessWidget {
  const NotesTips({super.key});

  @override
  Widget build(BuildContext context) => AppEmptyState(
        icon: Icons.edit_note_outlined,
        title: L10n.of(context).notesTips_1,
        description: L10n.of(context).notesTips_2,
      );
}
