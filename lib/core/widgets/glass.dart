import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/providers.dart';
import '../errors/failures.dart';
import '../theme/app_theme.dart';
import 'illustrations.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;
  final VoidCallback? onTap;
  final Color? tint;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 12,
    this.blur = false,
    this.onTap,
    this.tint,
  });
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget content = Container(
      decoration: BoxDecoration(
        color:
            tint ??
            (dark
                ? const Color(0xF01D2433)
                : Colors.white.withValues(alpha: .94)),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: .11)
              : const Color(0xFFDCE2ED),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .06 : .025),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    if (blur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: content,
        ),
      );
    }
    return content;
  }
}

class DueDeskBackground extends StatelessWidget {
  final Widget child;
  const DueDeskBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF121322), Color(0xFF0D1119), Color(0xFF101723)]
              : const [Color(0xFFEBEDFC), Color(0xFFF4F6FA), Color(0xFFEAF2F8)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -130,
            right: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: dark ? .13 : .09),
                    AppColors.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class DueDeskScaffold extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottom;
  final bool back;
  const DueDeskScaffold({
    super.key,
    this.title,
    required this.child,
    this.actions,
    this.bottom,
    this.back = true,
  });
  @override
  Widget build(BuildContext context) => DueDeskBackground(
    child: Scaffold(
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              automaticallyImplyLeading: back,
              leading: back
                  ? IconButton(
                      tooltip: 'Back',
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/home'),
                    )
                  : null,
              actions: actions,
            ),
      body: SafeArea(
        top: title == null,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: bottom,
    ),
  );
}

class GlassBottomNavigation extends StatelessWidget {
  final String location;
  const GlassBottomNavigation({super.key, required this.location});
  static const entries = [
    ('/home', 'Home', Icons.space_dashboard_outlined),
    ('/due', 'Due', Icons.task_alt_rounded),
    ('/calendar', 'Calendar', Icons.calendar_month_outlined),
    ('/documents', 'Docs', Icons.folder_outlined),
    ('/more', 'More', Icons.grid_view_rounded),
  ];
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: GlassCard(
            blur: true,
            padding: const EdgeInsets.all(7),
            radius: 14,
            child: Row(
              children: [
                for (final (path, label, icon) in entries)
                  Expanded(
                    child: Semantics(
                      selected: location.startsWith(path),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => context.go(path),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 2,
                          ),
                          decoration: BoxDecoration(
                            color: location.startsWith(path)
                                ? AppColors.primary.withValues(alpha: .13)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 23,
                                color: location.startsWith(path)
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: location.startsWith(path)
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: location.startsWith(path)
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
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
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class AppShell extends ConsumerWidget {
  final Widget child;
  final String location;
  const AppShell({super.key, required this.child, required this.location});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline =
        ref
            .watch(connectivityProvider)
            .value
            ?.contains(ConnectivityResult.none) ??
        false;
    return DueDeskBackground(
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (offline)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: AppColors.warning.withValues(alpha: .15),
                  child: const Text(
                    "You're offline. Showing the latest available data.",
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 900) return child;
                    return Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: NavigationRail(
                              backgroundColor: Colors.transparent,
                              leading: const Padding(
                                padding: EdgeInsets.only(bottom: 20),
                                child: BrandMark(size: 36),
                              ),
                              labelType: NavigationRailLabelType.all,
                              selectedIndex: GlassBottomNavigation.entries
                                  .indexWhere((e) => location.startsWith(e.$1))
                                  .clamp(0, 4),
                              onDestinationSelected: (i) => context.go(
                                GlassBottomNavigation.entries[i].$1,
                              ),
                              destinations: [
                                for (final e in GlassBottomNavigation.entries)
                                  NavigationRailDestination(
                                    icon: Icon(e.$3),
                                    label: Text(e.$2),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(child: child),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
            ? GlassBottomNavigation(location: location)
            : null,
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 44});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'DueDesk',
    image: true,
    child: SvgPicture.asset(
      'assets/branding/duedesk_mark.svg',
      height: size,
      width: size,
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 19),
          const SizedBox(width: 9),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    ),
  );
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: loading ? null : onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (icon != null)
          Icon(icon, size: 18),
        if (loading || icon != null) const SizedBox(width: 8),
        Flexible(child: Text(label)),
      ],
    ),
  );
}

class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool required, obscure;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  const GlassTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.required = false,
    this.obscure = false,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.suffix,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      decoration: InputDecoration(
        labelText: '$label${required ? ' *' : ''}',
        hintText: hint,
        suffixIcon: suffix,
      ),
      validator:
          validator ??
          (required
              ? (value) => value == null || value.trim().isEmpty
                    ? 'Enter ${label.toLowerCase()}.'
                    : null
              : null),
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
    ),
  );
}

class GlassDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final Map<T, String> options;
  final ValueChanged<T?>? onChanged;
  final bool required;
  const GlassDropdown({
    super.key,
    required this.label,
    required this.options,
    this.value,
    this.onChanged,
    this.required = false,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<T>(
      key: ValueKey('$label-$value-${options.length}'),
      initialValue: options.containsKey(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: '$label${required ? ' *' : ''}'),
      items: options.entries
          .map(
            (e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: required
          ? (v) => v == null ? 'Select ${label.toLowerCase()}.' : null
          : null,
    ),
  );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final String title, message;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState({
    super.key,
    this.title = "You're all clear.",
    this.message = 'Nothing to show here yet.',
    this.icon = Icons.check_circle_outline_rounded,
    this.action,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DeskIllustration(
          kind: icon == Icons.cloud_off_outlined
              ? DeskArt.connection
              : message.toLowerCase().contains('document')
              ? DeskArt.documents
              : message.toLowerCase().contains('search')
              ? DeskArt.search
              : DeskArt.clear,
          size: 112,
          monochrome: true,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: 20),
          PrimaryButton(label: action!, onPressed: onAction),
        ],
      ],
    ),
  );
}

class ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const ErrorState({super.key, required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => EmptyState(
    title: 'Something went wrong.',
    message: friendlyError(error),
    icon: Icons.cloud_off_outlined,
    action: 'Try again',
    onAction: onRetry,
  );
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    highlightColor: Theme.of(context).colorScheme.surface,
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        for (int i = 0; i < 5; i++)
          Container(
            height: i == 0 ? 160 : 90,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
      ],
    ),
  );
}

class WorkspaceBody extends ConsumerWidget {
  final Widget child;
  const WorkspaceBody({super.key, required this.child});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(workspaceProvider)
      .when(
        data: (_) => child,
        loading: () => const LoadingSkeleton(),
        error: (e, st) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(workspaceProvider),
        ),
      );
}

class PageBody extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final bool eager;
  const PageBody({
    super.key,
    required this.children,
    this.onRefresh,
    this.eager = false,
  });
  @override
  Widget build(BuildContext context) {
    final body = LayoutBuilder(
      builder: (context, c) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          c.maxWidth > 700 ? 24 : 16,
          14,
          c.maxWidth > 700 ? 24 : 16,
          28,
        ),
        children: eager
            ? [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ]
            : children,
      ),
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: onRefresh == null
            ? body
            : RefreshIndicator(
                onRefresh: () async {
                  await runAction(context, onRefresh!);
                },
                child: body,
              ),
      ),
    );
  }
}

Future<T?> glassSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
            child: child,
          ),
        ),
      ),
    );
void feedback(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) feedback(context, success);
    return true;
  } catch (e) {
    if (context.mounted) feedback(context, friendlyError(e));
    return false;
  }
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message, {
  String confirm = 'Confirm',
}) async =>
    await glassSheet<bool>(
      context,
      Builder(
        builder: (sheetContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(message),
            const SizedBox(height: 24),
            PrimaryButton(
              label: confirm,
              onPressed: () => Navigator.pop(sheetContext, true),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ) ??
    false;
