import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/config/environment.dart';
import '../../../core/widgets/glass.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => DueDeskScaffold(
    child: Center(
      child: ref.watch(authProvider).hasError
          ? ErrorState(
              error: ref.watch(authProvider).error!,
              onRetry: () => ref.invalidate(authProvider),
            )
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: .7, end: 1),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.scale(scale: value, child: child),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrandMark(size: 76),
                  SizedBox(height: 24),
                  Text(
                    'DueDesk',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 12),
                  Text('Never miss what is due.'),
                  SizedBox(height: 32),
                  SizedBox(width: 100, child: LinearProgressIndicator()),
                ],
              ),
            ),
    ),
  );
}

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});
  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeState();
}

class _WelcomeState extends ConsumerState<WelcomeScreen> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => DueDeskScaffold(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  BrandMark(size: 36),
                  SizedBox(width: 12),
                  Text(
                    'DueDesk',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 62),
              GlassCard(
                blur: true,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const Spacer(),
                        const Text(
                          'ALL UNDER CONTROL',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'A little clarity.\nA lot of peace of mind.',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.8,
                      ),
                    ),
                    const SizedBox(height: 22),
                    for (final text in [
                      'Deadlines, in one place',
                      'Clear ownership, every time',
                      'Evidence that stays with the work',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                text,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 38),
              Text(
                'Never miss\nwhat is due.',
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(fontSize: 38, height: 1.15),
              ),
              const SizedBox(height: 14),
              Text(
                'Your business obligations. Organised, assigned, and always one step ahead.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Sign in',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.push('/login'),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Create account',
                onPressed: () => context.push('/register'),
              ),
              if (AppConfig.isDemo) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          setState(() => busy = true);
                          await runAction(
                            context,
                            () => ref.read(authProvider.notifier).demo(),
                          );
                          if (mounted) setState(() => busy = false);
                        },
                  child: Text(
                    busy ? 'Opening your workspace…' : 'Continue in demo mode',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Built for businesses that stay ahead.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AuthFormScreen extends ConsumerStatefulWidget {
  final String mode;
  const AuthFormScreen({super.key, required this.mode});
  @override
  ConsumerState<AuthFormScreen> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<AuthFormScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController(),
      name = TextEditingController(),
      company = TextEditingController();
  bool hidden = true,
      remember = true,
      terms = false,
      busy = false,
      sent = false;
  String? formError;
  @override
  void dispose() {
    for (final c in [email, password, confirm, name, company]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    setState(() => formError = null);
    if (!form.currentState!.validate()) return;
    if (widget.mode == 'register' && !terms) {
      setState(() => formError = 'Please accept the terms to continue.');
      return;
    }
    setState(() => busy = true);
    await runAction(context, () async {
      if (widget.mode == 'login') {
        await ref
            .read(authProvider.notifier)
            .login(email.text.trim(), password.text, remember);
      } else if (widget.mode == 'register') {
        await ref
            .read(authProvider.notifier)
            .register(
              name.text.trim(),
              email.text.trim(),
              password.text,
              company.text.trim(),
            );
        if (mounted) context.go('/onboarding');
      } else {
        await ref
            .read(authRepositoryProvider)
            .forgotPassword(email.text.trim());
        if (mounted) setState(() => sent = true);
      }
    });
    if (mounted) {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final register = widget.mode == 'register',
        forgot = widget.mode == 'forgot';
    return DueDeskScaffold(
      title: register
          ? 'Create your account'
          : forgot
          ? 'Reset password'
          : 'Welcome back',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: sent
                ? EmptyState(
                    title: AppConfig.isDemo
                        ? 'Demo request recorded'
                        : 'Check your inbox',
                    message: AppConfig.isDemo
                        ? 'Demo mode does not send email. Use demo@duedesk.app with password demo123 to sign in.'
                        : 'If an account exists for this address, you will receive password reset instructions.',
                    icon: Icons.mark_email_read_outlined,
                    action: 'Back to sign in',
                    onAction: () => context.go('/login'),
                  )
                : Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const BrandMark(size: 52),
                        const SizedBox(height: 24),
                        Text(
                          register
                              ? 'A calmer way to stay on top.'
                              : forgot
                              ? 'Let’s get you back in.'
                              : 'Your obligations, in focus.',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          forgot
                              ? 'Enter your work email to request a reset.'
                              : register
                              ? 'Set up your workspace and give every deadline a home.'
                              : 'Sign in to see what needs your attention.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (AppConfig.isDemo) ...[
                          const SizedBox(height: 18),
                          GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              register
                                  ? 'Local demo workspace · No email is sent and no production account is created.'
                                  : 'Local demo · demo@duedesk.app / demo123',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        if (register)
                          GlassTextField(
                            controller: name,
                            label: 'Full name',
                            required: true,
                          ),
                        GlassTextField(
                          controller: email,
                          label: 'Work email',
                          required: true,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              RegExp(
                                r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                              ).hasMatch(v?.trim() ?? '')
                              ? null
                              : 'Enter a valid email address.',
                        ),
                        if (!forgot) ...[
                          GlassTextField(
                            controller: password,
                            label: 'Password',
                            required: true,
                            obscure: hidden,
                            suffix: IconButton(
                              tooltip: hidden
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () => setState(() => hidden = !hidden),
                              icon: Icon(
                                hidden
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                            validator: (v) =>
                                (v?.length ?? 0) < (register ? 8 : 1)
                                ? register
                                      ? 'Use at least 8 characters.'
                                      : 'Enter your password.'
                                : null,
                          ),
                        ],
                        if (register) ...[
                          GlassTextField(
                            controller: confirm,
                            label: 'Confirm password',
                            obscure: hidden,
                            validator: (v) => v != password.text
                                ? 'Passwords must match.'
                                : null,
                          ),
                          GlassTextField(
                            controller: company,
                            label: 'Company name',
                            required: true,
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: terms,
                            onChanged: (v) => setState(() => terms = v!),
                            controlAffinity: ListTileControlAffinity.leading,
                            title: const Text(
                              'I accept the terms of use',
                              style: TextStyle(fontSize: 13),
                            ),
                            subtitle: TextButton(
                              onPressed: () => glassSheet(
                                context,
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Demo terms of use',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 14),
                                    Text(
                                      'DueDesk demo stores sample and entered data on this device. It does not submit filings, send reminders or invitations, or provide legal or tax advice. Use non-sensitive test information. Production terms and privacy policy are supplied by your service operator.',
                                    ),
                                  ],
                                ),
                              ),
                              child: const Text('Read terms'),
                            ),
                          ),
                        ],
                        if (!register && !forgot)
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: remember,
                                    onChanged: (v) =>
                                        setState(() => remember = v!),
                                  ),
                                  const Text(
                                    'Remember session',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () =>
                                    context.push('/forgot-password'),
                                child: const Text('Forgot password?'),
                              ),
                            ],
                          ),
                        if (formError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              formError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: register
                              ? 'Create account'
                              : forgot
                              ? 'Send reset instructions'
                              : 'Sign in',
                          onPressed: submit,
                          loading: busy,
                        ),
                        const SizedBox(height: 14),
                        if (!forgot)
                          TextButton(
                            onPressed: () =>
                                context.go(register ? '/login' : '/register'),
                            child: Text(
                              register
                                  ? 'Already have an account? Sign in'
                                  : 'New to DueDesk? Create an account',
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
