import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/illustrations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  int page = 0;
  static const slides = [
    (
      'Welcome to DueDesk.',
      'Keep every business obligation organised in one place.',
      Icons.space_dashboard_outlined,
    ),
    (
      'Track what matters.',
      'Renewals, filings, licences, contracts, and compliance. Every deadline has a home.',
      Icons.task_alt_rounded,
    ),
    (
      'Stay ahead.',
      'Set reminders before deadlines become problems.',
      Icons.notifications_active_outlined,
    ),
    (
      'Know who owns it.',
      'Clear assignments and shared accountability keep your business moving.',
      Icons.people_outline_rounded,
    ),
    (
      'You’re ready.',
      'A clear view of what is due. A little more room to focus.',
      Icons.verified_outlined,
    ),
  ];
  Future<void> finish() async {
    await ref.read(preferencesProvider).setBool('onboarding', true);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final (title, description, icon) = slides[page];
    return DueDeskScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Row(
                  children: [
                    const BrandMark(),
                    const Spacer(),
                    TextButton(onPressed: finish, child: const Text('Skip')),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Column(
                          key: ValueKey(page),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GlassCard(
                              blur: true,
                              padding: const EdgeInsets.all(24),
                              child: IllustratedIcon(icon: icon, size: 90),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < 5; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == page ? 24 : 7,
                        height: 7,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: i == page ? 1 : .2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: page == 4 ? 'Go to Dashboard' : 'Continue',
                    onPressed: () =>
                        page == 4 ? finish() : setState(() => page++),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
