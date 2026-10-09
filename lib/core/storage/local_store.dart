import 'dart:convert';
import 'dart:typed_data';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../shared/models/models.dart';

abstract interface class LocalStore {
  Future<WorkspaceData?> read();
  Future<void> write(WorkspaceData data);
  Future<void> putFile(String id, Uint8List bytes);
  Future<Uint8List?> getFile(String id);
  Future<void> removeFile(String id);

  /// Where the data lives, shown to the user in Settings › Storage.
  String get location;

  /// Approximate bytes used by records and attached files.
  Future<int> sizeInBytes();

  /// Removes every record and file this store holds.
  Future<void> clear();
}

class HiveLocalStore implements LocalStore {
  final Box<String> records;
  final Box<List<int>> files;
  HiveLocalStore(this.records, this.files);
  @override
  Future<WorkspaceData?> read() async {
    final raw = records.get('workspace-v1');
    return raw == null ? null : WorkspaceData.fromJson(jsonDecode(raw) as Json);
  }

  @override
  Future<void> write(WorkspaceData data) =>
      records.put('workspace-v1', jsonEncode(data.toJson()));
  @override
  Future<void> putFile(String id, Uint8List bytes) =>
      files.put(id, bytes.toList());
  @override
  Future<Uint8List?> getFile(String id) async {
    final b = files.get(id);
    return b == null ? null : Uint8List.fromList(b);
  }

  @override
  Future<void> removeFile(String id) => files.delete(id);
  @override
  Future<void> clear() async {
    await records.clear();
    await files.clear();
  }

  @override
  String get location => records.path ?? 'This browser';
  @override
  Future<int> sizeInBytes() async =>
      (records.get('workspace-v1')?.length ?? 0) +
      files.values.fold<int>(0, (sum, b) => sum + b.length);
}

class MemoryLocalStore implements LocalStore {
  WorkspaceData? data;
  final Map<String, Uint8List> files = {};
  @override
  Future<WorkspaceData?> read() async => data;
  @override
  Future<void> write(WorkspaceData data) async {
    this.data = WorkspaceData.fromJson(data.toJson());
  }

  @override
  Future<void> putFile(String id, Uint8List bytes) async {
    files[id] = bytes;
  }

  @override
  Future<Uint8List?> getFile(String id) async => files[id];
  @override
  Future<void> removeFile(String id) async {
    files.remove(id);
  }

  @override
  Future<void> clear() async {
    data = null;
    files.clear();
  }

  @override
  String get location => 'Memory';
  @override
  Future<int> sizeInBytes() async =>
      files.values.fold<int>(0, (sum, b) => sum + b.length);
}
