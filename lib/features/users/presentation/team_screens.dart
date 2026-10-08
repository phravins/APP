import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/config/environment.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/due_widgets.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final org = ref.watch(organisationProvider),
        user = ref.watch(currentUserProvider);
    final manage = Permissions.manage(user, org.id);
    return DueDeskScaffold(
      title: 'Team',
      actions: [
        if (manage)
          IconButton(
            tooltip: 'Invite member',
            onPressed: () => context.push('/team/invite'),
            icon: const Icon(Icons.person_add_outlined),
          ),
      ],
      child: WorkspaceBody(
        child: PageBody(
          eager: true,
          children: [
            Text(
              'Clear ownership starts with your people.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            for (final member in ref.watch(teamProvider))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  child: Row(
                    children: [
                      UserAvatar(
                        name: member.name,
                        image: member.avatarUrl,
                        radius: 22,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              member.email,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${member.memberships[org.id]?.label} · ${member.statusIn(org.id)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (manage && member.id != user.id)
                        IconButton(
                          tooltip: 'Manage ${member.name}',
                          onPressed: () =>
                              glassSheet(context, MemberSheet(member: member)),
                          icon: const Icon(Icons.more_horiz),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MemberSheet extends ConsumerStatefulWidget {
  final User member;
  const MemberSheet({super.key, required this.member});
  @override
  ConsumerState<MemberSheet> createState() => _MemberState();
}

class _MemberState extends ConsumerState<MemberSheet> {
  late Role role;
  late bool active;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    role = widget.member.memberships[ref.read(organisationProvider).id]!;
    active = widget.member.roleIn(ref.read(organisationProvider).id) != null;
  }

  @override
  Widget build(BuildContext context) {
    final org = ref.watch(organisationProvider),
        user = ref.watch(currentUserProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.member.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        GlassDropdown<Role>(
          label: 'Role',
          value: role,
          options: {
            for (final r in Role.values.where(
              (r) =>
                  r != Role.owner ||
                  Permissions.owner(user, org.id) ||
                  role == Role.owner,
            ))
              r: r.label,
          },
          onChanged: (v) => setState(() => role = v!),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            widget.member.status == 'invited'
                ? 'Activate demo member'
                : 'Active member',
          ),
          value: active,
          onChanged: (v) => setState(() => active = v),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Save access',
          loading: busy,
          onPressed: () async {
            setState(() => busy = true);
            final ok = await runAction(
              context,
              () => ref
                  .read(workspaceProvider.notifier)
                  .act(
                    (r, a) => r.updateMember(
                      a,
                      org.id,
                      widget.member.id,
                      role,
                      active,
                    ),
                  ),
              success: 'Member access updated',
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
}

class InviteMemberScreen extends ConsumerStatefulWidget {
  const InviteMemberScreen({super.key});
  @override
  ConsumerState<InviteMemberScreen> createState() => _InviteState();
}

class _InviteState extends ConsumerState<InviteMemberScreen> {
  final form = GlobalKey<FormState>(),
      name = TextEditingController(),
      email = TextEditingController();
  Role role = Role.member;
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final org = ref.watch(organisationProvider),
        actor = ref.watch(currentUserProvider);
    return DueDeskScaffold(
      title: 'Invite member',
      child: !Permissions.manage(actor, org.id)
          ? const EmptyState(
              title: 'Access restricted',
              message: 'An owner or admin can invite members.',
            )
          : Form(
              key: form,
              child: PageBody(
                eager: true,
                children: [
                  const Text('Give your team a shared view of what matters.'),
                  const SizedBox(height: 26),
                  GlassTextField(
                    controller: name,
                    label: 'Full name',
                    required: true,
                  ),
                  GlassTextField(
                    controller: email,
                    label: 'Work email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v ?? '')
                        ? null
                        : 'Enter a valid email.',
                  ),
                  GlassDropdown<Role>(
                    label: 'Role',
                    value: role,
                    options: {
                      for (final r in Role.values.where(
                        (r) =>
                            r != Role.owner || Permissions.owner(actor, org.id),
                      ))
                        r: r.label,
                    },
                    onChanged: (v) => setState(() => role = v!),
                  ),
                  if (AppConfig.isDemo)
                    const GlassCard(
                      child: Text(
                        'Demo invitations are saved locally. No email is sent.',
                      ),
                    ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Send Invitation',
                    loading: busy,
                    onPressed: () async {
                      if (!form.currentState!.validate()) return;
                      setState(() => busy = true);
                      final ok = await runAction(
                        context,
                        () => ref
                            .read(workspaceProvider.notifier)
                            .act(
                              (r, a) => r.inviteUser(
                                a,
                                org.id,
                                name.text.trim(),
                                email.text.trim(),
                                role,
                              ),
                            ),
                        success: AppConfig.isDemo
                            ? 'Demo invitation created'
                            : 'Invitation sent',
                      );
                      if (context.mounted) {
                        if (ok) {
                          context.pop();
                        } else {
                          setState(() => busy = false);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
