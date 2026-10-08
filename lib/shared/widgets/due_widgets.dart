import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/illustrations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/due_dates.dart';
import '../models/models.dart';

Color statusColor(DueStatus status) => switch (status) {
  DueStatus.overdue => const Color(0xFFBA3448),
  DueStatus.dueToday => const Color(0xFFA4540B),
  DueStatus.dueSoon => const Color(0xFF8E6411),
  DueStatus.completed || DueStatus.renewed => const Color(0xFF14794F),
  DueStatus.inProgress => const Color(0xFF5950D7),
  _ => const Color(0xFF506A8D),
};
Color statusTextColor(BuildContext context, DueStatus status) =>
    Theme.of(context).brightness == Brightness.dark
    ? Color.lerp(statusColor(status), Colors.white, .45)!
    : statusColor(status);
IconData categoryIcon(String category) => switch (category.toLowerCase()) {
  'gst' || 'tax' => Icons.receipt_long_outlined,
  'licence' || 'certificate' || 'registration' => Icons.verified_outlined,
  'insurance' => Icons.shield_outlined,
  'contract' => Icons.handshake_outlined,
  'hr' => Icons.badge_outlined,
  'subscription' => Icons.autorenew_rounded,
  'finance' => Icons.account_balance_outlined,
  'statutory' || 'compliance' => Icons.policy_outlined,
  _ => Icons.folder_outlined,
};

class DueStatusBadge extends StatelessWidget {
  final DueStatus status;
  const DueStatusBadge({super.key, required this.status});
  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: statusTextColor(context, status),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final String? image;
  const UserAvatar({
    super.key,
    required this.name,
    this.radius = 17,
    this.image,
  });
  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.take(2).map((s) => s[0]).join();
    ImageProvider? photo;
    if (image?.startsWith('data:image') ?? false) {
      try {
        photo = MemoryImage(base64Decode(image!.split(',').last));
      } catch (_) {}
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: .14),
      backgroundImage: photo,
      child: photo == null
          ? Text(
              initials.toUpperCase(),
              style: TextStyle(
                fontSize: radius * .65,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : null,
    );
  }
}

class DueItemCard extends ConsumerWidget {
  final DueItem item;
  const DueItemCard({super.key, required this.item});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider),
        status = DueDates.status(item, ref.watch(todayProvider));
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final pinned = ref.watch(pinnedItemsProvider).contains(item.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: () => context.push('/due/${item.id}'),
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IllustratedIcon(
                  icon: categoryIcon(item.categoryName),
                  color: statusColor(status),
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              item.categoryName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .8,
                                color: muted,
                              ),
                            ),
                            if (item.priority == Priority.high ||
                                item.priority == Priority.critical)
                              Text(
                                '• ${item.priority.label}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: item.priority == Priority.critical
                                      ? statusTextColor(
                                          context,
                                          DueStatus.overdue,
                                        )
                                      : muted,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: pinned ? 'Unpin obligation' : 'Pin obligation',
                  isSelected: pinned,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.bookmark_border_rounded,
                    size: AppSizes.iconMd,
                  ),
                  selectedIcon: Icon(
                    Icons.bookmark_rounded,
                    size: AppSizes.iconMd,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => runAction(
                    context,
                    () =>
                        ref.read(pinnedItemsProvider.notifier).toggle(item.id),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: AppSizes.iconXs,
                      color: muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DueDates.format(item.dueDate, year: true),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
                Text(
                  item.isClosed
                      ? status.label
                      : DueDates.relative(item.dueDate, today),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusTextColor(context, status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final owner = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UserAvatar(name: item.assignedToName, radius: 12),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          item.assignedToName,
                          style: TextStyle(fontSize: 12, color: muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                  final meta = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.documentCount > 0) ...[
                        Icon(
                          Icons.attach_file_rounded,
                          size: AppSizes.iconXs,
                          color: muted,
                        ),
                        Text(
                          '${item.documentCount}',
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (item.frequency != Frequency.oneTime) ...[
                        Icon(
                          Icons.repeat_rounded,
                          size: AppSizes.iconXs,
                          color: muted,
                        ),
                        const SizedBox(width: 8),
                      ],
                      DueStatusBadge(status: status),
                    ],
                  );
                  if (MediaQuery.textScalerOf(context).scale(14) > 18) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [owner, const SizedBox(height: 8), meta],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: owner),
                      const SizedBox(width: 6),
                      meta,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompanySwitcher extends ConsumerWidget {
  const CompanySwitcher({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final org = ref.watch(organisationProvider);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => glassSheet(
        context,
        Consumer(
          builder: (context, ref, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Switch organisation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              for (final company
                  in ref.watch(workspaceProvider).value?.organisations ??
                      <Organisation>[])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const IllustratedIcon(
                    icon: Icons.business_rounded,
                    size: 38,
                  ),
                  title: Text(company.name),
                  subtitle: Text(
                    ref.watch(currentUserProvider).roleIn(company.id)?.label ??
                        '',
                  ),
                  trailing: company.id == org.id
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () async {
                    await ref
                        .read(currentOrganisationProvider.notifier)
                        .select(company.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                org.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .8,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: AppSizes.iconSm,
            ),
          ],
        ),
      ),
    );
  }
}

class ScreenHeading extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;
  const ScreenHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}
