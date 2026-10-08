import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/config/environment.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/widgets/due_widgets.dart';
import '../../../shared/models/models.dart';
import '../domain/dashboard_summary.dart';

final dashboardProvider = Provider<DashboardSummary>(
  (ref) => DashboardSummary.fromItems(
    ref.watch(dueItemsProvider),
    ref.watch(todayProvider),
  ),
);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider),
        items = ref.watch(dueItemsProvider),
        summary = ref.watch(dashboardProvider),
        org = ref.watch(organisationProvider);
    final next = items.where((i) => !i.isClosed).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final completed =
        items
            .where(
              (i) =>
                  [DueStatus.completed, DueStatus.renewed].contains(i.status),
            )
            .toList()
          ..sort(
            (a, b) => (b.completionDate ?? b.updatedAt).compareTo(
              a.completionDate ?? a.updatedAt,
            ),
          );
    final unread = ref
        .watch(notificationsProvider)
        .where((n) => !n.read)
        .length;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return WorkspaceBody(
      child: PageBody(
        onRefresh: () => ref.read(workspaceProvider.notifier).refresh(),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat(
                        'EEEE, d MMMM',
                      ).format(ref.watch(todayProvider)).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$greeting,\n${user.name.split(' ').first}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const CompanySwitcher(),
                  ],
                ),
              ),
              Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: IconButton(
                  tooltip: 'Notifications',
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Profile',
                onPressed: () => context.push('/profile'),
                icon: UserAvatar(
                  name: user.name,
                  image: user.avatarUrl,
                  radius: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GlassCard(
            blur: true,
            tint: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xCC25213F)
                : const Color(0xEDE7E5FF),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        summary.attention > 0
                            ? Icons.bolt_rounded
                            : Icons.check_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'YOUR ATTENTION, PLEASE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  summary.attention == 0
                      ? 'You’re all caught up.'
                      : '${summary.attention} items need\nyour attention',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(height: 1.22),
                ),
                const SizedBox(height: 12),
                Text(
                  '${summary.overdue} overdue  ·  ${summary.today} today  ·  ${summary.dueSoon} due soon',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'A clear desk starts here.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () => context.go('/due?filter=Attention'),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Review now'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Due overview'),
          LayoutBuilder(
            builder: (context, c) {
              final columns = c.maxWidth > 650 ? 4 : 2;
              final metrics = [
                (
                  'Overdue',
                  summary.overdue,
                  Icons.warning_amber_rounded,
                  AppColors.danger,
                  'Needs a little attention',
                ),
                (
                  'Today',
                  summary.today,
                  Icons.today_outlined,
                  AppColors.warning,
                  'Make today count',
                ),
                (
                  'This Week',
                  summary.thisWeek,
                  Icons.date_range_outlined,
                  AppColors.primary,
                  'Keep a step ahead',
                ),
                (
                  'Upcoming',
                  summary.upcoming,
                  Icons.event_available_outlined,
                  const Color(0xFF568FCA),
                  'On the horizon',
                ),
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final (label, count, icon, color, caption) in metrics)
                    SizedBox(
                      width: (c.maxWidth - 12 * (columns - 1)) / columns,
                      child: GlassCard(
                        padding: const EdgeInsets.all(17),
                        onTap: () => context.go(
                          '/due?filter=${Uri.encodeComponent(label)}',
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(icon, size: 18, color: color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Text(
                              '$count',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              caption,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SectionHeader(title: 'Quick actions'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (Permissions.manage(user, org.id))
                _QuickAction(
                  label: 'Add Due Item',
                  icon: Icons.add_rounded,
                  onTap: () => context.push('/due/new'),
                ),
              _QuickAction(
                label: 'Upload document',
                icon: Icons.upload_file_outlined,
                onTap: () => context.push('/documents?upload=true'),
              ),
              _QuickAction(
                label: 'Calendar',
                icon: Icons.calendar_month_outlined,
                onTap: () => context.go('/calendar'),
              ),
            ],
          ),
          SectionHeader(
            title: 'Upcoming deadlines',
            action: 'View all',
            onAction: () => context.go('/due'),
          ),
          if (next.isEmpty)
            const EmptyState(message: 'No open obligations. Enjoy the clarity.')
          else
            LayoutBuilder(
              builder: (context, c) => Wrap(
                spacing: 16,
                children: [
                  for (final item in next.take(4))
                    SizedBox(
                      width: c.maxWidth > 700
                          ? (c.maxWidth - 16) / 2
                          : c.maxWidth,
                      child: DueItemCard(item: item),
                    ),
                ],
              ),
            ),
          SectionHeader(
            title: 'Recently completed',
            action: 'View history',
            onAction: () => context.go('/due?filter=Completed'),
          ),
          if (completed.isEmpty)
            const EmptyState(
              title: 'Your history starts here.',
              message:
                  'Completed obligations and evidence will stay on record.',
            )
          else
            for (final item in completed.take(2)) DueItemCard(item: item),
          if (AppConfig.isDemo)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                'DEMO WORKSPACE  ·  STORED ON THIS DEVICE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5,
                  letterSpacing: 1.1,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    radius: 14,
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
