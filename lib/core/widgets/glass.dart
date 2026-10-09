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
    this.radius = AppSizes.radiusLg,
    this.blur = false,
    this.onTap,
    this.tint,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: tint ?? scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: scheme.outlineVariant),
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
  }
}

class DueDeskBackground extends StatelessWidget {
  final Widget child;
  const DueDeskBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: Theme.of(context).colorScheme.surface, child: child);
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
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

/// Phones keep the bottom bar in every orientation; only tablets and
/// desktops get the side rail.
bool useNavigationRail(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.shortestSide >= AppSizes.railBreakpoint &&
      size.width >= AppSizes.railBreakpoint;
}

class GlassBottomNavigation extends StatelessWidget {
  final String location;
  const GlassBottomNavigation({super.key, required this.location});
  static const entries = [
    (
      '/home',
      'Home',
      Icons.space_dashboard_outlined,
      Icons.space_dashboard_rounded,
    ),
    ('/due', 'Due', Icons.task_alt_rounded, Icons.check_circle_rounded),
    (
      '/calendar',
      'Calendar',
      Icons.calendar_month_outlined,
      Icons.calendar_month_rounded,
    ),
    ('/documents', 'Docs', Icons.folder_outlined, Icons.folder_rounded),
    ('/more', 'More', Icons.grid_view_outlined, Icons.grid_view_rounded),
  ];
  static int indexOf(String location) =>
      entries.indexWhere((e) => location.startsWith(e.$1)).clamp(0, 4);
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = entries.indexWhere((e) => location.startsWith(e.$1));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                children: [
                  for (final (i, (path, label, icon, activeIcon))
                      in entries.indexed)
                    Expanded(
                      child: Semantics(
                        selected: i == selected,
                        button: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                          onTap: () => context.go(path),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  width: 52,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: i == selected
                                        ? scheme.surfaceContainerHigh
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    i == selected ? activeIcon : icon,
                                    size: AppSizes.iconMd + 2,
                                    color: i == selected
                                        ? scheme.onSurface
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: i == selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: i == selected
                                        ? scheme.onSurface
                                        : scheme.onSurfaceVariant,
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
    final rail = useNavigationRail(context);
    final scheme = Theme.of(context).colorScheme;
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
                child: !rail
                    ? child
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final extended =
                              constraints.maxWidth >=
                              AppSizes.extendedRailBreakpoint;
                          return Row(
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerLow,
                                  border: Border(
                                    right: BorderSide(
                                      color: scheme.outlineVariant,
                                    ),
                                  ),
                                ),
                                child: NavigationRail(
                                  extended: extended,
                                  minExtendedWidth: 220,
                                  groupAlignment: -1,
                                  leading: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      0,
                                      12,
                                      0,
                                      20,
                                    ),
                                    child: extended
                                        ? Row(
                                            children: [
                                              const BrandMark(size: 32),
                                              const SizedBox(width: 12),
                                              Text(
                                                'DueDesk',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleLarge,
                                              ),
                                            ],
                                          )
                                        : const BrandMark(size: 32),
                                  ),
                                  labelType: extended
                                      ? NavigationRailLabelType.none
                                      : NavigationRailLabelType.all,
                                  selectedIndex: GlassBottomNavigation.indexOf(
                                    location,
                                  ),
                                  onDestinationSelected: (i) => context.go(
                                    GlassBottomNavigation.entries[i].$1,
                                  ),
                                  destinations: [
                                    for (final e
                                        in GlassBottomNavigation.entries)
                                      NavigationRailDestination(
                                        icon: Icon(e.$3),
                                        selectedIcon: Icon(e.$4),
                                        label: Text(e.$2),
                                      ),
                                  ],
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
        bottomNavigationBar: rail
            ? null
            : GlassBottomNavigation(location: location),
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
          SizedBox(
            width: 18,
            height: 18,
            child: Builder(
              builder: (context) => CircularProgressIndicator(
                strokeWidth: 2,
                color: IconTheme.of(context).color,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: AppSizes.iconMd),
          const SizedBox(width: 8),
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
          Icon(icon, size: AppSizes.iconMd),
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
    padding: const EdgeInsets.only(top: 22, bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(action!),
          ),
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
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
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
          c.maxWidth >= 1000 ? 32 : (c.maxWidth > 700 ? 24 : 16),
          14,
          c.maxWidth >= 1000 ? 32 : (c.maxWidth > 700 ? 24 : 16),
          32,
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
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
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
