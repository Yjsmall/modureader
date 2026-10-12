import 'package:flutter/material.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.description,
      this.action});
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24)),
                child: Icon(icon, size: 32, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 24),
              Text(title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              if (action != null) ...[const SizedBox(height: 24), action!],
            ],
          ),
        ),
      ),
    );
  }
}
