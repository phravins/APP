import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/due_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<ProfileScreen> {
  final form = GlobalKey<FormState>(),
      name = TextEditingController(),
      phone = TextEditingController();
  String? avatar;
  bool initialized = false, busy = false;
  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider),
        org = ref.watch(organisationProvider);
    if (!initialized && user.id.isNotEmpty) {
      initialized = true;
      name.text = user.name;
      phone.text = user.phone;
      avatar = user.avatarUrl;
    }
    return DueDeskScaffold(
      title: 'Profile',
      child: WorkspaceBody(
        child: Form(
          key: form,
          child: PageBody(
            eager: true,
            children: [
              Center(
                child: Column(
                  children: [
                    UserAvatar(name: user.name, image: avatar, radius: 44),
                    TextButton(
                      onPressed: () => runAction(context, () async {
                        final image = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 320,
                          maxHeight: 320,
                          imageQuality: 80,
                        );
                        if (image == null) return;
                        final bytes = await image.readAsBytes();
                        if (mounted) {
                          setState(
                            () => avatar =
                                'data:image/jpeg;base64,${base64Encode(bytes)}',
                          );
                        }
                      }),
                      child: const Text('Change photo'),
                    ),
                    Text(
                      '${user.roleIn(org.id)?.label} · ${org.name}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              GlassTextField(
                controller: name,
                label: 'Full name',
                required: true,
              ),
              GlassCard(
                child: Row(
                  children: [
                    const Icon(Icons.mail_outline, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(user.email)),
                    const Icon(Icons.lock_outline, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassTextField(
                controller: phone,
                label: 'Phone',
                keyboardType: TextInputType.phone,
              ),
              PrimaryButton(
                label: 'Save profile',
                loading: busy,
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  setState(() => busy = true);
                  await runAction(
                    context,
                    () => ref
                        .read(workspaceProvider.notifier)
                        .act(
                          (r, a) => r.saveProfile(
                            a,
                            user.copyWith(
                              name: name.text.trim(),
                              phone: phone.text.trim(),
                              avatarUrl: avatar,
                            ),
                          ),
                        ),
                    success: 'Profile updated',
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
