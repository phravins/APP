import 'package:flutter/material.dart';
import '../../../core/utils/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/utils/due_dates.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/due_widgets.dart';
import '../../documents/presentation/document_widgets.dart';
import 'due_form_screen.dart';

class DueDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const DueDetailScreen({super.key, required this.id});
  @override
  ConsumerState<DueDetailScreen> createState() => _DetailState();
}

class _DetailState extends ConsumerState<DueDetailScreen> {
  bool busy = false;
  Future<void> action(Future<void> Function() callback, String success) async {
    setState(() => busy = true);
    await runAction(context, callback, success: success);
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(dueItemDetailProvider(widget.id)),
        user = ref.watch(currentUserProvider);
    if (item == null) {
      return DueDeskScaffold(
        title: 'Due Item',
        child: WorkspaceBody(
          child: EmptyState(
            title: 'DueItem unavailable',
            message:
                'It may belong to another organisation, or you may not have access.',
            action: 'Back to Due Items',
            onAction: () => context.go('/due'),
          ),
        ),
      );
    }
    final today = ref.watch(todayProvider),
        status = DueDates.status(item, today),
        canManage = Permissions.manage(user, item.organisationId),
        canUpdate = Permissions.update(user, item);
    final docs = ref
        .watch(documentsProvider)
        .where((d) => d.dueItemId == item.id)
        .toList();
    final events =
        ref
            .watch(workspaceProvider)
            .value
            ?.activities
            .where((e) => e.dueItemId == item.id)
            .toList() ??
        [];
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return DueDeskScaffold(
      title: 'Due Item',
      actions: [
        IconButton(
          tooltip: ref.watch(pinnedItemsProvider).contains(item.id)
              ? 'Unpin obligation'
              : 'Pin obligation',
          icon: Icon(
            ref.watch(pinnedItemsProvider).contains(item.id)
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
          ),
          onPressed: () => runAction(
            context,
            () => ref.read(pinnedItemsProvider.notifier).toggle(item.id),
          ),
        ),
        if (canManage)
          PopupMenuButton<String>(
            tooltip: 'DueItem actions',
            onSelected: (v) async {
              if (v == 'edit') {
                context.push('/due/${item.id}/edit');
              } else if (await confirmAction(
                    context,
                    'Archive this DueItem?',
                    'It will be removed from active lists but retained in history.',
                    confirm: 'Archive DueItem',
                  ) &&
                  context.mounted) {
                await action(
                  () => ref
                      .read(workspaceProvider.notifier)
                      .act((r, a) => r.archiveDueItem(a, item.id)),
                  'DueItem archived',
                );
              }
            },
            itemBuilder: (_) => [
              if (!item.isClosed)
                const PopupMenuItem(value: 'edit', child: Text('Edit DueItem')),
              if (item.status != DueStatus.archived)
                const PopupMenuItem(value: 'archive', child: Text('Archive')),
            ],
          ),
      ],
      bottom: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Row(
            children: [
              if (canUpdate && item.status != DueStatus.inProgress) ...[
                Expanded(
                  child: SecondaryButton(
                    label: 'Start',
                    loading: busy,
                    onPressed: () => action(
                      () => ref
                          .read(workspaceProvider.notifier)
                          .act((r, a) => r.startDueItem(a, item.id)),
                      'Work started',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (canUpdate)
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: 'Complete',
                    icon: Icons.check_rounded,
                    onPressed: busy
                        ? null
                        : () => glassSheet(context, CompleteSheet(item: item)),
                  ),
                )
              else if (item.status == DueStatus.completed &&
                  item.frequency != Frequency.oneTime)
                Expanded(
                  child: PrimaryButton(
                    label: 'Renew next obligation',
                    loading: busy,
                    onPressed: () => action(
                      () => ref
                          .read(workspaceProvider.notifier)
                          .act((r, a) => r.renewDueItem(a, item.id)),
                      'Next obligation created',
                    ),
                  ),
                )
              else
                Expanded(
                  child: SecondaryButton(
                    label: item.status == DueStatus.archived
                        ? 'View retained history'
                        : 'View completion',
                    onPressed: () => glassSheet(
                      context,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completion record',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item.completionDate == null
                                ? 'No completion recorded.'
                                : 'Completed ${DueDates.format(item.completionDate!, year: true)} by ${item.completedBy}',
                          ),
                          if (item.nextDueDate != null)
                            Text(
                              'Next due: ${DueDates.format(item.nextDueDate!, year: true)}',
                            ),
                          for (final e in events.where(
                            (e) => e.type == 'completed',
                          )) ...[
                            const SizedBox(height: 12),
                            Text(e.description),
                            if ((e.metadata['acknowledgement'] ?? '')
                                .toString()
                                .isNotEmpty)
                              Text(
                                'Acknowledgement: ${e.metadata['acknowledgement']}',
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      child: PageBody(
        children: [
          Row(
            children: [
              Icon(
                categoryIcon(item.categoryName),
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                item.categoryName.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_rounded,
                      size: 20,
                      color: statusTextColor(context, status),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEE, d MMM yyyy').format(item.dueDate),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            item.isClosed
                                ? item.status.label
                                : DueDates.relative(item.dueDate, today),
                            style: TextStyle(
                              color: statusTextColor(context, status),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DueStatusBadge(status: status),
                  ],
                ),
                const Divider(height: 22),
                Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final progress in [
                      DueStatus.upcoming,
                      DueStatus.inProgress,
                    ])
                      ChoiceChip(
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text(progress.label),
                        selected: item.status == progress,
                        onSelected: canUpdate && !busy
                            ? (_) => action(
                                () => ref
                                    .read(workspaceProvider.notifier)
                                    .act(
                                      (r, a) =>
                                          r.setProgress(a, item.id, progress),
                                    ),
                                'Progress updated',
                              )
                            : null,
                      ),
                    ChoiceChip(
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: const Text('Completed'),
                      selected: item.completionDate != null,
                      onSelected: canUpdate && !busy
                          ? (_) =>
                                glassSheet(context, CompleteSheet(item: item))
                          : null,
                    ),
                  ],
                ),
                const Divider(height: 22),
                Row(
                  children: [
                    UserAvatar(name: item.assignedToName, radius: 14),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Assigned to ',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            TextSpan(
                              text: item.assignedToName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _DetailRow('Priority', item.priority.label),
                _DetailRow(
                  'Frequency',
                  item.frequency == Frequency.custom
                      ? 'Every ${item.recurrenceRule} days'
                      : item.frequency.label,
                ),
                if (item.startDate != null)
                  _DetailRow(
                    'Starts',
                    DueDates.format(item.startDate!, year: true),
                  ),
                if (item.referenceNumber.isNotEmpty)
                  _DetailRow('Reference', item.referenceNumber),
                if (item.authority.isNotEmpty)
                  _DetailRow('Authority', item.authority),
                if (item.amount != null)
                  _DetailRow(
                    'Amount',
                    NumberFormat.currency(
                      name: item.currency,
                      symbol: '${item.currency} ',
                    ).format(item.amount),
                  ),
                _DetailRow(
                  'Reminders',
                  item.reminderConfiguration.enabled
                      ? item.reminderConfiguration.daysBefore
                            .map((d) => d == 0 ? 'On date' : '${d}d')
                            .join(', ')
                      : 'Off',
                ),
                if (item.nextDueDate != null)
                  _DetailRow(
                    'Next due',
                    DueDates.format(item.nextDueDate!, year: true),
                  ),
              ],
            ),
          ),
          SectionHeader(
            title: 'Documents (${docs.length})',
            action: item.status != DueStatus.archived ? 'Upload' : null,
            onAction: () => glassSheet(context, UploadSheet(itemId: item.id)),
          ),
          if (docs.isEmpty)
            const GlassCard(
              child: Text('No documents yet. Attach supporting evidence here.'),
            )
          else
            for (final d in docs) DocumentTile(document: d),
          SectionHeader(
            title: 'Notes',
            action: 'Add note',
            onAction: () => glassSheet(context, AddNoteSheet(itemId: item.id)),
          ),
          if (item.notes.isNotEmpty) GlassCard(child: Text(item.notes)),
          for (final e in events.where((e) => e.type == 'note_added'))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.description),
                    const SizedBox(height: 8),
                    Text(
                      '${e.actor} · ${DueDates.format(e.timestamp)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (item.notes.isEmpty && !events.any((e) => e.type == 'note_added'))
            const Text('Keep useful context with this obligation.'),
          const SectionHeader(title: 'Activity & history'),
          GlassCard(
            child: Column(
              children: [for (final e in events) ActivityTile(event: e)],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

class ActivityTile extends StatelessWidget {
  final ActivityEvent event;
  const ActivityTile({super.key, required this.event});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            event.type == 'completed'
                ? Icons.check
                : event.type == 'document_uploaded'
                ? Icons.attach_file
                : Icons.circle,
            size: 12,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.description, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '${event.actor} · ${DateFormat('d MMM, h:mm a').format(event.timestamp.toLocal())}',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class AddNoteSheet extends ConsumerStatefulWidget {
  final String itemId;
  const AddNoteSheet({super.key, required this.itemId});
  @override
  ConsumerState<AddNoteSheet> createState() => _NoteState();
}

class _NoteState extends ConsumerState<AddNoteSheet> {
  final text = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Add a note', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 24),
      GlassTextField(controller: text, label: 'Note', maxLines: 4),
      PrimaryButton(
        label: 'Save note',
        loading: busy,
        onPressed: () async {
          if (text.text.trim().isEmpty) {
            feedback(context, 'Enter a note.');
            return;
          }
          setState(() => busy = true);
          final ok = await runAction(
            context,
            () => ref
                .read(workspaceProvider.notifier)
                .act((r, a) => r.addNote(a, widget.itemId, text.text.trim())),
            success: 'Note added',
          );
          if (context.mounted) {
            if (ok) {
              Navigator.pop(context);
            } else {
              setState(() => busy = false);
            }
          }
        },
      ),
    ],
  );
}

class CompleteSheet extends ConsumerStatefulWidget {
  final DueItem item;
  const CompleteSheet({super.key, required this.item});
  @override
  ConsumerState<CompleteSheet> createState() => _CompleteState();
}

class _CompleteState extends ConsumerState<CompleteSheet> {
  final notes = TextEditingController(), reference = TextEditingController();
  late DateTime date;
  DateTime? next;
  bool renew = true, busy = false, done = false;
  @override
  void initState() {
    super.initState();
    date = ref.read(todayProvider);
    next = DueDates.next(widget.item);
  }

  @override
  void dispose() {
    notes.dispose();
    reference.dispose();
    super.dispose();
  }

  Future<void> complete() async {
    setState(() => busy = true);
    final ok = await runAction(
      context,
      () => ref
          .read(workspaceProvider.notifier)
          .act(
            (r, a) => r.completeDueItem(
              a,
              widget.item.id,
              date: date,
              notes: notes.text,
              reference: reference.text,
              renew: renew,
              nextDate: next,
            ),
          ),
    );
    if (mounted) {
      if (ok) {
        DueHaptics.confirm();
        if (mounted) setState(() => done = true);
      }
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => done
      ? Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .5, end: 1),
              duration: const Duration(milliseconds: 300),
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 72,
                color: Color(0xFF229B6C),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'One less thing to think about.',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              renew && next != null
                  ? 'Completion recorded. Your next obligation is ready.'
                  : 'Completion and evidence are retained in history.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Done',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Complete obligation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(widget.item.title),
            const SizedBox(height: 24),
            DateField(
              label: 'Completion date',
              value: date,
              lastDate: ref.watch(todayProvider),
              onChanged: (v) => setState(() => date = v),
            ),
            const SizedBox(height: 18),
            GlassTextField(
              controller: notes,
              label: 'Completion notes',
              maxLines: 3,
            ),
            GlassTextField(
              controller: reference,
              label: 'Acknowledgement / reference',
            ),
            SecondaryButton(
              label: 'Attach proof',
              icon: Icons.attach_file,
              onPressed: busy
                  ? null
                  : () => glassSheet(
                      context,
                      UploadSheet(itemId: widget.item.id),
                    ),
            ),
            const SizedBox(height: 12),
            if (next != null) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Create next obligation',
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: Text(widget.item.frequency.label),
                value: renew,
                onChanged: busy ? null : (v) => setState(() => renew = v),
              ),
              if (renew)
                DateField(
                  label: 'Next due date',
                  value: next,
                  onChanged: (v) => setState(() => next = v),
                ),
              const SizedBox(height: 20),
            ],
            PrimaryButton(
              label: 'Mark as Completed',
              loading: busy,
              onPressed: complete,
            ),
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
}
