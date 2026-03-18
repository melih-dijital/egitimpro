import 'package:flutter/material.dart';

import '../../theme/duty_planner_theme.dart';

class SchedulePageFrame extends StatelessWidget {
  final Widget child;

  const SchedulePageFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: DutyPlannerTheme.screenPadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: DutyPlannerTheme.maxContentWidth(context),
          ),
          child: child,
        ),
      ),
    );
  }
}

class ScheduleSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const ScheduleSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: DutyPlannerColors.textSecondary),
              ),
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}

class ScheduleEmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ScheduleEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 56, color: DutyPlannerColors.textHint),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: DutyPlannerColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ScheduleErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ScheduleErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 52,
              color: DutyPlannerColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: DutyPlannerColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class RunStatusBadge extends StatelessWidget {
  final String status;

  const RunStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'completed' => DutyPlannerColors.success,
      'failed' => DutyPlannerColors.error,
      _ => DutyPlannerColors.warning,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
