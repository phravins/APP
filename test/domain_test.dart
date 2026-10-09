import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:duedesk/shared/models/models.dart';
import 'package:duedesk/core/utils/due_dates.dart';
import 'package:duedesk/features/due_items/data/demo_seed.dart';
import 'package:duedesk/features/dashboard/domain/dashboard_summary.dart';
import 'package:duedesk/features/auth/domain/auth_repository.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  final today = DateTime.utc(2026, 10, 7);
  DueItem item(
    DateTime due, {
    DueStatus status = DueStatus.upcoming,
    Frequency frequency = Frequency.oneTime,
  }) => demoSeed(now: today).items.first.patch({
    'dueDate': due.toIso8601String(),
    'status': status.name,
    'frequency': frequency.name,
  });
  test('Civil-date differences ignore hours', () {
    expect(DueDates.daysLeft(DateTime(2026, 10, 7, 23, 59), today), 0);
    expect(DueDates.daysLeft(DateTime(2026, 10, 6), today), -1);
  });
  test('Organisation timezone controls the business day', () {
    expect(
      DueDates.today('Asia/Kolkata', now: DateTime.utc(2026, 10, 6, 20)),
      today,
    );
    expect(
      DueDates.today('America/New_York', now: DateTime.utc(2026, 10, 7, 2)),
      DateTime.utc(2026, 10, 6),
    );
  });
  test('DST boundaries preserve civil day distance', () {
    expect(DueDates.daysLeft(DateTime(2026, 3, 9), DateTime(2026, 3, 8)), 1);
  });
  test('Status transitions at date boundaries', () {
    expect(
      DueDates.status(item(today.subtract(const Duration(days: 1))), today),
      DueStatus.overdue,
    );
    expect(DueDates.status(item(today), today), DueStatus.dueToday);
    expect(
      DueDates.status(item(today.add(const Duration(days: 15))), today),
      DueStatus.dueSoon,
    );
    expect(
      DueDates.status(item(today.add(const Duration(days: 16))), today),
      DueStatus.upcoming,
    );
  });
  test('Due-soon window follows configured reminders', () {
    final due = item(today.add(const Duration(days: 20))).patch({
      'reminderConfiguration': const ReminderConfiguration(
        daysBefore: [30, 7, 0],
      ).toJson(),
    });
    expect(DueDates.urgency(due, today), DueStatus.dueSoon);
    expect(
      DueDates.urgency(
        due.patch({
          'reminderConfiguration': const ReminderConfiguration(
            daysBefore: [7, 0],
          ).toJson(),
        }),
        today,
      ),
      DueStatus.upcoming,
    );
  });
  test('Overdue urgency outranks in-progress', () {
    expect(
      DueDates.status(
        item(
          today.subtract(const Duration(days: 2)),
          status: DueStatus.inProgress,
        ),
        today,
      ),
      DueStatus.overdue,
    );
    expect(
      DueDates.status(
        item(today.add(const Duration(days: 2)), status: DueStatus.inProgress),
        today,
      ),
      DueStatus.inProgress,
    );
  });
  test('Closed records never become overdue', () {
    for (final s in [
      DueStatus.completed,
      DueStatus.renewed,
      DueStatus.archived,
    ]) {
      expect(DueDates.status(item(DateTime.utc(2020), status: s), today), s);
    }
  });
  test('Monthly recurrence handles end-of-month without overflow', () {
    expect(
      DueDates.next(
        item(DateTime.utc(2026, 1, 31), frequency: Frequency.monthly),
      ),
      DateTime.utc(2026, 2, 28),
    );
    expect(
      DueDates.next(
        item(DateTime.utc(2026, 2, 28), frequency: Frequency.monthly),
      ),
      DateTime.utc(2026, 3, 31),
    );
  });
  test('Yearly recurrence handles leap day', () {
    expect(
      DueDates.next(
        item(DateTime.utc(2024, 2, 29), frequency: Frequency.yearly),
      ),
      DateTime.utc(2025, 2, 28),
    );
  });
  test('All recurrence types advance predictably', () {
    final expected = {
      Frequency.weekly: DateTime.utc(2026, 10, 14),
      Frequency.monthly: DateTime.utc(2026, 11, 7),
      Frequency.quarterly: DateTime.utc(2027, 1, 7),
      Frequency.halfYearly: DateTime.utc(2027, 4, 7),
      Frequency.yearly: DateTime.utc(2027, 10, 7),
    };
    for (final f in expected.keys) {
      expect(DueDates.next(item(today, frequency: f)), expected[f]);
    }
    expect(DueDates.next(item(today)), null);
    expect(
      DueDates.next(
        item(
          today,
          frequency: Frequency.custom,
        ).patch({'recurrenceRule': '10'}),
      ),
      DateTime.utc(2026, 10, 17),
    );
    expect(
      () => DueDates.next(item(today, frequency: Frequency.custom)),
      throwsArgumentError,
    );
  });
  test('Search matches title, category, reference, authority, assignee', () {
    final data = demoSeed(
      now: today,
    ).items.where((i) => i.organisationId == 'realoffice').toList();
    for (final q in ['gstr', 'gst', 'RO-GST', 'GST Portal', 'Arun']) {
      expect(DueFilter(query: q).apply(data, today, 'management'), isNotEmpty);
    }
    expect(
      const DueFilter(query: 'zzmissing').apply(data, today, 'management'),
      isEmpty,
    );
  });
  test('Filters combine status, owner, priority and inclusive date range', () {
    final data = demoSeed(now: today).items;
    final result = DueFilter(
      assigneeId: 'arun',
      priority: Priority.high,
      from: DateTime.utc(2026, 10, 20),
      to: DateTime.utc(2026, 10, 20),
    ).apply(data, today, 'management');
    expect(result.map((i) => i.id), ['gst']);
    expect(
      const DueFilter(
        segment: 'Completed',
      ).apply(data, today, 'management').single.id,
      'roc',
    );
  });
  test('Archived history is available only with explicit status filter', () {
    final archived = item(today, status: DueStatus.archived);
    expect(const DueFilter().apply([archived], today, 'management'), isEmpty);
    expect(
      const DueFilter(
        status: DueStatus.archived,
      ).apply([archived], today, 'management'),
      hasLength(1),
    );
  });
  test('Dashboard counts derive from the same obligation data', () {
    final data = demoSeed(
      now: today,
    ).items.where((i) => i.organisationId == 'realoffice').toList();
    final s = DashboardSummary.fromItems(data, today);
    expect(s.overdue, 1);
    expect(s.today, 1);
    expect(s.dueSoon, 3);
    expect(s.upcoming, 2);
    expect(s.completed, 1);
    expect(s.attention, 5);
  });
  test('Snapshot serialization preserves every entity', () {
    final data = demoSeed(now: today);
    expect(WorkspaceData.fromJson(data.toJson()).toJson(), data.toJson());
  });
  test('Indian mobile numbers normalise like the web sign-up', () {
    for (final raw in [
      '98765 43210',
      '09876543210',
      '+91 98765 43210',
      '919876543210',
      '98765-43210',
    ]) {
      expect(normaliseIndianMobile(raw), '+919876543210', reason: raw);
    }
    for (final raw in ['', '12345 67890', '98765 4321', '+1 98765 43210']) {
      expect(normaliseIndianMobile(raw), isNull, reason: raw);
    }
  });
}
