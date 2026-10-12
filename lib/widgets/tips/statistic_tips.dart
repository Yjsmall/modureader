import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/common/app_empty_state.dart';
import 'package:flutter/material.dart';

class StatisticsTips extends StatelessWidget {
  const StatisticsTips({super.key});

  @override
  Widget build(BuildContext context) => AppEmptyState(
        icon: Icons.history_outlined,
        title: L10n.of(context).statisticsTips_1,
        description: L10n.of(context).statisticsTips_2,
      );
}
