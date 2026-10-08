import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/utils/permissions.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/due_widgets.dart';

class CompanyScreen extends ConsumerStatefulWidget {
  const CompanyScreen({super.key});
  @override
  ConsumerState<CompanyScreen> createState() => _CompanyState();
}

class _CompanyState extends ConsumerState<CompanyScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      industry = TextEditingController(),
      address = TextEditingController();
  String timezone = 'Asia/Kolkata', year = 'April – March';
  String? logo;
  bool busy = false, initialized = false;
  @override
  void dispose() {
    name.dispose();
    industry.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final org = ref.watch(organisationProvider),
        actor = ref.watch(currentUserProvider);
    if (!initialized && ref.watch(workspaceProvider).hasValue) {
      initialized = true;
      name.text = org.name;
      industry.text = org.industry;
      address.text = org.address;
      timezone = org.timezone;
      year = org.financialYear;
      logo = org.logoUrl;
    }
    final allowed = Permissions.manage(actor, org.id);
    return DueDeskScaffold(
      title: 'Company',
      child: WorkspaceBody(
        child: !allowed
            ? EmptyState(
                title: org.name,
                message: 'Company settings are managed by an owner or admin.',
                icon: Icons.business_outlined,
              )
            : Form(
                key: form,
                child: PageBody(
                  eager: true,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          UserAvatar(name: name.text, image: logo, radius: 38),
                          TextButton(
                            onPressed: () async {
                              await runAction(context, () async {
                                final f = await ImagePicker().pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 320,
                                  maxHeight: 320,
                                  imageQuality: 80,
                                );
                                if (f == null) return;
                                final bytes = await f.readAsBytes();
                                if (mounted) {
                                  setState(
                                    () => logo =
                                        'data:image/jpeg;base64,${base64Encode(bytes)}',
                                  );
                                }
                              });
                            },
                            child: const Text('Change logo'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GlassTextField(
                      controller: name,
                      label: 'Company name',
                      required: true,
                    ),
                    GlassTextField(controller: industry, label: 'Industry'),
                    GlassDropdown<String>(
                      label: 'Timezone',
                      value: timezone,
                      options: {
                        for (final z in {
                          'Asia/Kolkata',
                          'UTC',
                          'Europe/London',
                          'America/New_York',
                          'America/Los_Angeles',
                          'Asia/Dubai',
                          'Asia/Singapore',
                          'Australia/Sydney',
                          timezone,
                        })
                          z: z,
                      },
                      onChanged: (v) => setState(() => timezone = v!),
                    ),
                    GlassDropdown<String>(
                      label: 'Financial year',
                      value: year,
                      options: {
                        for (final y in {
                          'April – March',
                          'January – December',
                          'July – June',
                          year,
                        })
                          y: y,
                      },
                      onChanged: (v) => setState(() => year = v!),
                    ),
                    GlassTextField(
                      controller: address,
                      label: 'Business address',
                      maxLines: 3,
                    ),
                    PrimaryButton(
                      label: 'Save company',
                      loading: busy,
                      onPressed: () async {
                        if (!form.currentState!.validate()) return;
                        setState(() => busy = true);
                        await runAction(
                          context,
                          () => ref
                              .read(workspaceProvider.notifier)
                              .act(
                                (r, a) => r.saveCompany(
                                  a,
                                  Organisation(
                                    id: org.id,
                                    name: name.text.trim(),
                                    slug: org.slug,
                                    industry: industry.text.trim(),
                                    timezone: timezone,
                                    financialYear: year,
                                    address: address.text.trim(),
                                    logoUrl: logo,
                                  ),
                                ),
                              ),
                          success: 'Company updated',
                        );
                        if (mounted) setState(() => busy = false);
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manage = Permissions.manage(
      ref.watch(currentUserProvider),
      ref.watch(organisationProvider).id,
    );
    return DueDeskScaffold(
      title: 'Categories',
      actions: [
        if (manage)
          IconButton(
            tooltip: 'Add category',
            onPressed: () => glassSheet(context, const CategorySheet()),
            icon: const Icon(Icons.add),
          ),
      ],
      child: WorkspaceBody(
        child: PageBody(
          eager: true,
          children: [
            const Text('A simple structure for everything that is due.'),
            const SizedBox(height: 20),
            for (final c in ref.watch(categoriesProvider))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Icon(categoryIcon(c.name), color: Color(c.accent)),
                    title: Text(c.name),
                    subtitle: Text(
                      c.active
                          ? c.description.isEmpty
                                ? 'Active category'
                                : c.description
                          : 'Inactive · history retained',
                    ),
                    trailing: manage
                        ? const Icon(Icons.edit_outlined, size: 18)
                        : null,
                    onTap: manage
                        ? () => glassSheet(context, CategorySheet(category: c))
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CategorySheet extends ConsumerStatefulWidget {
  final DueCategory? category;
  const CategorySheet({super.key, this.category});
  @override
  ConsumerState<CategorySheet> createState() => _CategoryState();
}

class _CategoryState extends ConsumerState<CategorySheet> {
  final name = TextEditingController(), description = TextEditingController();
  bool active = true, busy = false;
  int accent = 0xFF6C63FF;
  @override
  void initState() {
    super.initState();
    name.text = widget.category?.name ?? '';
    description.text = widget.category?.description ?? '';
    active = widget.category?.active ?? true;
    accent = widget.category?.accent ?? accent;
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        widget.category == null ? 'New category' : 'Edit category',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 24),
      GlassTextField(controller: name, label: 'Name', required: true),
      GlassTextField(
        controller: description,
        label: 'Description',
        maxLines: 2,
      ),
      Wrap(
        spacing: 8,
        children: [
          for (final color in [
            0xFF6C63FF,
            0xFF3B82F6,
            0xFF229B6C,
            0xFFAD7916,
            0xFF6881A7,
          ])
            IconButton(
              tooltip:
                  'Select accent ${[0xFF6C63FF, 0xFF3B82F6, 0xFF229B6C, 0xFFAD7916, 0xFF6881A7].indexOf(color) + 1}',
              onPressed: () => setState(() => accent = color),
              icon: Icon(
                accent == color ? Icons.check_circle : Icons.circle,
                color: Color(color),
              ),
            ),
        ],
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: active,
        onChanged: (v) => setState(() => active = v),
        title: const Text('Active category'),
        subtitle: const Text('Inactive categories remain in history.'),
      ),
      const SizedBox(height: 20),
      PrimaryButton(
        label: 'Save category',
        loading: busy,
        onPressed: () async {
          setState(() => busy = true);
          final ok = await runAction(
            context,
            () => ref
                .read(workspaceProvider.notifier)
                .act(
                  (r, a) => r.saveCategory(
                    a,
                    DueCategory(
                      id: widget.category?.id ?? newId(),
                      organisationId: ref.read(organisationProvider).id,
                      name: name.text.trim(),
                      description: description.text.trim(),
                      active: active,
                      accent: accent,
                    ),
                  ),
                ),
            success: 'Category saved',
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
