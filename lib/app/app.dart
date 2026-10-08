import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import 'providers.dart';
import 'router.dart';

class DueDeskApp extends ConsumerStatefulWidget {
  const DueDeskApp({super.key});
  @override
  ConsumerState<DueDeskApp> createState() => _AppState();
}

class _AppState extends ConsumerState<DueDeskApp> with WidgetsBindingObserver {
  Timer? _clock;
  StreamSubscription<String>? _notifications;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = Timer.periodic(
      const Duration(minutes: 1),
      (_) => ref.invalidate(todayProvider),
    );
    _notifications = ref.read(notificationServiceProvider).dueItemLinks.listen((
      id,
    ) {
      if (mounted) {
        ref.read(routerProvider).go('/due/${Uri.encodeComponent(id)}');
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _notifications?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(todayProvider);
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'DueDesk',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.theme(Brightness.light),
    darkTheme: AppTheme.theme(Brightness.dark),
    themeMode: ref.watch(themeProvider),
    routerConfig: ref.watch(routerProvider),
  );
}
