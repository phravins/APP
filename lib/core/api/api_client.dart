import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/environment.dart';
import '../errors/failures.dart';

class TokenStore {
  final FlutterSecureStorage storage;
  String? _access, _refresh, _profile;
  bool _remember = true;
  TokenStore(this.storage);
  Future<String?> access() async =>
      _access ?? await storage.read(key: 'access_token');
  Future<String?> refresh() async =>
      _refresh ?? await storage.read(key: 'refresh_token');
  Future<void> save(String access, String refresh, {bool? remember}) async {
    _remember = remember ?? _remember;
    _access = access;
    _refresh = refresh;
    if (_remember) {
      await storage.write(key: 'access_token', value: access);
      await storage.write(key: 'refresh_token', value: refresh);
    } else {
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'refresh_token');
    }
  }

  Future<void> saveProfile(String json) async {
    _profile = json;
    if (_remember) await storage.write(key: 'session_profile', value: json);
  }

  Future<String?> profile() async =>
      _profile ?? await storage.read(key: 'session_profile');
  Future<void> clear() async {
    _profile = null;
    await storage.delete(key: 'session_profile');
    _access = null;
    _refresh = null;
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
  }
}

class ApiClient {
  final TokenStore tokens;
  late final Dio dio;
  Future<void>? _refreshing;
  ApiClient(this.tokens, {String? baseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['public'] != true) {
            final token = await tokens.access();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final options = error.requestOptions;
          if (error.response?.statusCode == 401 &&
              options.extra['public'] != true &&
              options.extra['retried'] != true) {
            try {
              await (_refreshing ??= _refresh().whenComplete(
                () => _refreshing = null,
              ));
              options.extra['retried'] = true;
              options.headers['Authorization'] =
                  'Bearer ${await tokens.access()}';
              if (options.data is FormData) {
                options.data = (options.data as FormData).clone();
              }
              handler.resolve(await dio.fetch(options));
              return;
            } catch (_) {
              await tokens.clear();
            }
          }
          handler.next(error);
        },
      ),
    );
  }
  Future<void> _refresh() async {
    final refresh = await tokens.refresh();
    if (refresh == null) throw const AuthenticationFailure();
    final result = await dio.post(
      '/auth/refresh',
      data: {'refresh_token': refresh},
      options: Options(extra: {'public': true}),
    );
    await tokens.save(
      result.data['access_token'],
      result.data['refresh_token'],
    );
  }

  Future<T> guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      switch (e.response?.statusCode) {
        case 401:
          throw const AuthenticationFailure();
        case 403:
          throw const PermissionFailure();
        case 400:
        case 422:
          throw const ValidationFailure(
            'Please check the entered details and try again.',
          );
        case 404:
          throw const ValidationFailure('This record is no longer available.');
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkFailure();
      }
      throw const ServerFailure();
    }
  }
}
