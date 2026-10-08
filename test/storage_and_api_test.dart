import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:duedesk/core/api/api_client.dart';
import 'package:duedesk/core/errors/failures.dart';
import 'package:duedesk/core/storage/local_store.dart';
import 'package:duedesk/features/due_items/data/api_repository.dart';
import 'package:duedesk/features/due_items/data/demo_seed.dart';

class FakeAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  FakeAdapter(this.handler);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody response(Object data, int status) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  test(
    'Hive snapshot and evidence survive closing and reopening boxes',
    () async {
      final dir = await Directory.systemTemp.createTemp('duedesk-test-');
      Hive.init(dir.path);
      final records = await Hive.openBox<String>('records');
      final files = await Hive.openBox<List<int>>('files');
      final store = HiveLocalStore(records, files);
      final seed = demoSeed();
      final bytes = Uint8List.fromList([0, 20, 255, 10]);
      await store.write(seed);
      await store.putFile('proof', bytes);
      await records.close();
      await files.close();
      final reopened = HiveLocalStore(
        await Hive.openBox<String>('records'),
        await Hive.openBox<List<int>>('files'),
      );
      expect((await reopened.read())!.toJson(), seed.toJson());
      expect(await reopened.getFile('proof'), bytes);
      await Hive.close();
      await dir.delete(recursive: true);
    },
  );
  test(
    'Dio attaches bearer token, refreshes 401 once and replays request',
    () async {
      final tokens = TokenStore(const FlutterSecureStorage());
      await tokens.save('old', 'refresh');
      final api = ApiClient(tokens, baseUrl: 'https://api.example.test/api/v1');
      int refreshes = 0, reads = 0;
      api.dio.httpClientAdapter = FakeAdapter((o) async {
        if (o.path == '/auth/refresh') {
          refreshes++;
          expect(o.extra['public'], true);
          return response({
            'access_token': 'new',
            'refresh_token': 'rotated',
          }, 200);
        }
        reads++;
        if (o.headers['Authorization'] == 'Bearer old') {
          return response({}, 401);
        }
        expect(o.headers['Authorization'], 'Bearer new');
        return response({'ok': true}, 200);
      });
      final r = await api.guard(() => api.dio.get('/private'));
      expect(r.data['ok'], true);
      expect(reads, 2);
      expect(refreshes, 1);
      expect(await tokens.refresh(), 'rotated');
    },
  );
  test(
    'API cache is available offline only for its authenticated account',
    () async {
      final store = MemoryLocalStore(), seed = demoSeed();
      final owner = seed.users.first, member = seed.users[2];
      await store.write(seed.copyWith(cachedForUserId: owner.id));
      final api = ApiClient(
        TokenStore(const FlutterSecureStorage()),
        baseUrl: 'https://api.example.test',
      );
      api.dio.httpClientAdapter = FakeAdapter(
        (o) async => throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionError,
        ),
      );
      final repo = ApiDueItemRepository(api, store);
      expect((await repo.load(owner)).items, isNotEmpty);
      expect(repo.showingCached, true);
      await expectLater(repo.load(member), throwsA(isA<NetworkFailure>()));
    },
  );
  test('API failures do not expose raw server responses', () async {
    final api = ApiClient(
      TokenStore(const FlutterSecureStorage()),
      baseUrl: 'https://api.example.test',
    );
    api.dio.httpClientAdapter = FakeAdapter(
      (o) async => response({'debug': 'private database trace'}, 403),
    );
    await expectLater(
      api.guard(() => api.dio.get('/private')),
      throwsA(isA<PermissionFailure>()),
    );
  });
  test('Session-only tokens are not restored by another TokenStore', () async {
    final tokens = TokenStore(const FlutterSecureStorage());
    await tokens.save('access', 'refresh', remember: false);
    expect(await tokens.access(), 'access');
    expect(await TokenStore(const FlutterSecureStorage()).access(), null);
  });
}
