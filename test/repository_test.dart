import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:duedesk/core/storage/local_store.dart';
import 'package:duedesk/core/errors/failures.dart';
import 'package:duedesk/shared/models/models.dart';
import 'package:duedesk/features/due_items/data/demo_seed.dart';
import 'package:duedesk/features/due_items/data/mock_repository.dart';
import 'package:duedesk/features/auth/data/auth_repositories.dart';

void main() {
  late MemoryLocalStore store;
  late MockDueItemRepository repo;
  late User owner, member;
  late WorkspaceData seed;
  setUp(() async {
    tz.initializeTimeZones();
    store = MemoryLocalStore();
    seed = demoSeed();
    await store.write(seed);
    repo = MockDueItemRepository(store);
    owner = seed.users.first;
    member = seed.users.firstWhere((u) => u.id == 'priya');
  });
  test('Create, edit and persistence across repository instances', () async {
    final item = seed.items.first.patch({'id': 'new', 'title': 'New licence'});
    await repo.createDueItem(owner, item);
    await repo.updateDueItem(owner, item.patch({'title': 'Updated licence'}));
    final fresh = MockDueItemRepository(store);
    expect((await fresh.getDueItem(owner, 'new')).title, 'Updated licence');
    expect(
      (await fresh.load(owner)).activities.where((e) => e.dueItemId == 'new'),
      hasLength(2),
    );
  });
  test(
    'Member list is restricted and direct access cannot bypass permission',
    () async {
      final data = await repo.load(member);
      expect(
        data.items.every(
          (i) => i.assignedToUserId == member.id || i.organisationId == 'rootd',
        ),
        true,
      );
      await expectLater(
        repo.getDueItem(member, 'gst'),
        throwsA(isA<PermissionFailure>()),
      );
      await expectLater(
        repo.createDueItem(member, seed.items.first.patch({'id': 'bad'})),
        throwsA(isA<PermissionFailure>()),
      );
    },
  );
  test('Member can start, add notes and complete an assigned item', () async {
    await repo.startDueItem(member, 'tax');
    await repo.setProgress(member, 'tax', DueStatus.upcoming);
    expect((await repo.getDueItem(member, 'tax')).status, DueStatus.upcoming);
    await expectLater(
      repo.setProgress(member, 'tax', DueStatus.completed),
      throwsA(isA<ValidationFailure>()),
    );
    await repo.addNote(member, 'tax', 'Paid in portal');
    await repo.completeDueItem(
      member,
      'tax',
      date: DateTime.now(),
      notes: 'Recorded',
      reference: 'ACK-123',
      renew: false,
    );
    expect((await repo.getDueItem(member, 'tax')).status, DueStatus.completed);
  });
  test('Completion renews atomically and preserves proof/history', () async {
    final child = await repo.completeDueItem(
      owner,
      'gst',
      date: DateTime.now(),
      notes: 'Filed',
      reference: 'ACK-1',
    );
    final old = await repo.getDueItem(owner, 'gst');
    expect(old.status, DueStatus.renewed);
    expect(old.completedBy, owner.name);
    expect(child, isNotNull);
    expect(child!.documentCount, 0);
    expect(old.documentCount, 1);
    expect(
      (await repo.load(owner)).documents.where((d) => d.dueItemId == 'gst'),
      hasLength(1),
    );
    expect(
      (await repo.load(owner)).activities.any(
        (e) =>
            e.type == 'completed' && e.metadata['acknowledgement'] == 'ACK-1',
      ),
      true,
    );
    await expectLater(
      repo.completeDueItem(
        owner,
        'gst',
        date: DateTime.now(),
        notes: '',
        reference: '',
      ),
      throwsA(isA<PermissionFailure>()),
    );
  });
  test('Concurrent completion cannot create duplicate renewals', () async {
    final results = await Future.wait([
      for (int i = 0; i < 2; i++)
        repo
            .completeDueItem(
              owner,
              'gst',
              date: DateTime.now(),
              notes: '',
              reference: '',
            )
            .then<Object?>((v) => v)
            .catchError((Object e) => e),
    ]);
    expect(results.whereType<DueItem>(), hasLength(1));
    expect(results.whereType<PermissionFailure>(), hasLength(1));
  });
  test('Archive retains completed records and all documents', () async {
    await repo.archiveDueItem(owner, 'roc');
    final data = await repo.load(owner);
    expect(
      data.items.firstWhere((i) => i.id == 'roc').status,
      DueStatus.archived,
    );
    expect(
      data.items.firstWhere((i) => i.id == 'roc').completionDate,
      isNotNull,
    );
    expect(data.documents.any((d) => d.dueItemId == 'roc'), true);
  });
  test('Cross-organisation assignment is rejected', () async {
    final item = seed.items.first.patch({
      'id': 'invalid',
      'organisationId': 'osworks',
    });
    await expectLater(
      repo.createDueItem(owner, item),
      throwsA(isA<ValidationFailure>()),
    );
  });
  test('Member cannot escalate role through profile', () async {
    await repo.saveProfile(
      member,
      member.copyWith(memberships: {'realoffice': Role.owner}),
    );
    final data = await repo.load(member);
    expect(
      data.users.firstWhere((u) => u.id == member.id).roleIn('realoffice'),
      Role.member,
    );
  });
  test('File validation and replacement maintain attachment counts', () async {
    await expectLater(
      repo.uploadDocument(owner, 'gst', 'danger.exe', Uint8List.fromList([1])),
      throwsA(isA<ValidationFailure>()),
    );
    await expectLater(
      repo.uploadDocument(
        owner,
        'gst',
        'fake.pdf',
        Uint8List.fromList([1, 2, 3]),
      ),
      throwsA(isA<ValidationFailure>()),
    );
    final doc = await repo.uploadDocument(
      owner,
      'gst',
      'notes.txt',
      Uint8List.fromList('Evidence'.codeUnits),
    );
    expect((await repo.getDueItem(owner, 'gst')).documentCount, 2);
    final replaced = await repo.uploadDocument(
      owner,
      'gst',
      'new.txt',
      Uint8List.fromList('New evidence'.codeUnits),
      replaceId: doc.id,
    );
    expect((await repo.getDueItem(owner, 'gst')).documentCount, 2);
    expect(
      await repo.readDocument(owner, replaced),
      Uint8List.fromList('New evidence'.codeUnits),
    );
    await repo.removeDocument(owner, replaced.id);
    expect((await repo.getDueItem(owner, 'gst')).documentCount, 1);
  });
  test('Category deactivation retains existing items', () async {
    final c = seed.categories.firstWhere((c) => c.name == 'GST');
    await repo.saveCategory(
      owner,
      DueCategory.fromJson({...c.toJson(), 'active': false}),
    );
    expect((await repo.getDueItem(owner, 'gst')).categoryId, c.id);
  });
  test('Notification read state persists', () async {
    await repo.markRead(owner, 'realoffice');
    expect(
      (await repo.load(owner)).notifications
          .where((n) => n.organisationId == 'realoffice')
          .every((n) => n.read),
      true,
    );
  });
  test('Demo invitation is explicit and inactive until activated', () async {
    await repo.inviteUser(
      owner,
      'realoffice',
      'New colleague',
      'new@example.com',
      Role.member,
    );
    final u = (await repo.load(
      owner,
    )).users.firstWhere((u) => u.email == 'new@example.com');
    expect(u.status, 'invited');
    expect(u.roleIn('realoffice'), null);
  });
  test('Deactivation is scoped to one organisation', () async {
    final arun = seed.users.firstWhere((u) => u.id == 'arun');
    await repo.updateMember(owner, 'realoffice', arun.id, Role.admin, false);
    final updated = (await store.read())!.users.firstWhere(
      (u) => u.id == arun.id,
    );
    expect(updated.roleIn('realoffice'), null);
    expect(updated.roleIn('osworks'), Role.member);
  });
  test(
    'Completed evidence cannot be replaced through a direct repository call',
    () async {
      await expectLater(
        repo.uploadDocument(
          owner,
          'roc',
          'replacement.txt',
          Uint8List.fromList([65]),
          replaceId: 'doc-roc',
        ),
        throwsA(isA<PermissionFailure>()),
      );
    },
  );
  test(
    'Registered demo account can sign in after logout without plaintext password storage',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final auth = DemoAuthRepository(prefs, store);
      final user = await auth.register(
        name: 'New Owner',
        email: 'owner@example.com',
        password: 'local-password-123',
        phone: '+919876543210',
      );
      await auth.signOut();
      expect(
        (await auth.signIn('owner@example.com', 'local-password-123')).id,
        user.id,
      );
      expect(
        prefs.getString('demo-account-owner@example.com'),
        isNot(contains('local-password-123')),
      );
      await expectLater(
        auth.signIn('owner@example.com', 'wrong'),
        throwsA(isA<AuthenticationFailure>()),
      );
    },
  );
  test('Demo login, remember-session, logout and restore', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = DemoAuthRepository(prefs, store);
    await expectLater(
      auth.signIn('wrong@example.com', 'wrong'),
      throwsA(isA<AuthenticationFailure>()),
    );
    await auth.signIn('demo@duedesk.app', 'demo123');
    expect((await auth.restore())!.id, owner.id);
    await auth.signOut();
    expect(await auth.restore(), null);
    await auth.signIn('demo@duedesk.app', 'demo123', remember: false);
    expect(await auth.restore(), null);
  });
}
