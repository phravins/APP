import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/due_dates.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/illustrations.dart';
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
        org = ref.watch(organisationProvider);
    final items = ref.watch(dueItemsProvider),
        summary = ref.watch(dashboardProvider);
    final today = ref.watch(todayProvider),
        pins = ref.watch(pinnedItemsProvider);
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
    final pinned = items
        .where((i) => pins.contains(i.id) && i.status != DueStatus.archived)
        .toList();
    final unread = ref
        .watch(notificationsProvider)
        .where((n) => !n.read)
        .length;
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return WorkspaceBody(
      child: PageBody(
        onRefresh: () => ref.read(workspaceProvider.notifier).refresh(),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEE, d MMM').format(today).toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hello, ${user.name.split(' ').first}',
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
              IconButton(
                tooltip: 'Profile',
                onPressed: () => context.push('/profile'),
                icon: UserAvatar(
                  name: user.name,
                  image: user.avatarUrl,
                  radius: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlassCard(
            blur: true,
            tint: dark ? const Color(0xF02C2945) : const Color(0xF5EEECFF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEEDS ATTENTION',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            summary.attention == 0
                                ? 'You’re all caught up.'
                                : '${summary.attention} items need your attention',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const DeskIllustration(kind: DeskArt.attention, size: 72),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${summary.overdue} overdue · ${summary.today} today · ${summary.dueSoon} soon',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/due?filter=Attention'),
                      child: const Text('Review now'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Due overview'),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 650 ? 4 : 2;
              final metrics = [
                (
                  'Overdue',
                  summary.overdue,
                  Icons.warning_amber_rounded,
                  AppColors.danger,
                ),
                (
                  'Today',
                  summary.today,
                  Icons.today_outlined,
                  AppColors.warning,
                ),
                (
                  'This Week',
                  summary.thisWeek,
                  Icons.date_range_outlined,
                  AppColors.primary,
                ),
                (
                  'Upcoming',
                  summary.upcoming,
                  Icons.event_available_outlined,
                  const Color(0xFF318CBC),
                ),
              ];
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (label, count, icon, color) in metrics)
                    SizedBox(
                      width: (c.maxWidth - 8 * (cols - 1)) / cols,
                      child: GlassCard(
                        padding: const EdgeInsets.all(12),
                        onTap: () => context.go(
                          '/due?filter=${Uri.encodeComponent(label)}',
                        ),
                        child: Row(
                          children: [
                            IllustratedIcon(icon: icon, color: color, size: 30),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$count',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (Permissions.manage(user, org.id)) ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => context.push('/due/new'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Due Item'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => context.push('/due/new?templates=true'),
                  icon: const Icon(
                    Icons.dashboard_customize_outlined,
                    size: 18,
                  ),
                  label: const Text('Templates'),
                ),
              ],
              IconButton.outlined(
                tooltip: 'Upload document',
                onPressed: () => context.push('/documents?upload=true'),
                icon: const Icon(Icons.upload_file_outlined, size: 20),
              ),
            ],
          ),
          if (pinned.isNotEmpty) ...[
            SectionHeader(
              title: 'Pinned obligations',
              action: 'View all',
              onAction: () => context.go('/due?filter=Pinned'),
            ),
            for (final item in pinned.take(2)) DueItemCard(item: item),
          ],
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
                spacing: 12,
                children: [
                  for (final item in next.take(4))
                    SizedBox(
                      width: c.maxWidth > 700
                          ? (c.maxWidth - 12) / 2
                          : c.maxWidth,
                      child: DueItemCard(item: item),
                    ),
                ],
              ),
            ),
          SectionHeader(
            title: 'Your next 7 days',
            action: 'Calendar',
            onAction: () => context.go('/calendar'),
          ),
          GlassCard(
            padding: const EdgeInsets.all(8),
            child: LayoutBuilder(
              builder: (context, c) => Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (var n = 0; n < 7; n++)
                    SizedBox(
                      width: (c.maxWidth - 24) / 7,
                      child: _WeekDay(
                        day: today.add(Duration(days: n)),
                        items: next,
                      ),
                    ),
                ],
              ),
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
        ],
      ),
    );
  }
}

class _WeekDay extends StatelessWidget {
  final DateTime day;
  final List<DueItem> items;
  const _WeekDay({required this.day, required this.items});
  @override
  Widget build(BuildContext context) {
    final count = items
        .where((i) => DueDates.daysLeft(i.dueDate, day) == 0)
        .length;
    return Semantics(
      label: '${DateFormat('EEEE d MMMM').format(day)}, $count obligations',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go(
          '/calendar?date=${DateFormat('yyyy-MM-dd').format(day)}',
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(
                DateFormat('EEEEE').format(day),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${day.day}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: count > 0
                      ? AppColors.primary
                      : Theme.of(context).dividerColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
