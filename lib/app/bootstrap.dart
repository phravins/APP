import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../core/api/api_client.dart';
import '../core/config/environment.dart';
import '../core/storage/local_store.dart';
import 'app.dart';
import 'providers.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    AppConfig.validate();
    tz.initializeTimeZones();
    await Hive.initFlutter();
    final prefs = await SharedPreferences.getInstance();
    final records = await Hive.openBox<String>(
      '${AppConfig.environmentName}-workspace',
    );
    final files = await Hive.openBox<List<int>>(
      '${AppConfig.environmentName}-files',
    );
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    runApp(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          localStoreProvider.overrideWithValue(HiveLocalStore(records, files)),
          apiClientProvider.overrideWithValue(
            ApiClient(TokenStore(const FlutterSecureStorage())),
          ),
        ],
        child: const DueDeskApp(),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 48),
                    const SizedBox(height: 20),
                    const Text(
                      'DueDesk could not start.',
                      style: TextStyle(fontSize: 22),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Check the app configuration and available device storage, then try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: bootstrap,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
