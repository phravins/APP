import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../shared/models/models.dart';

abstract final class DueDates {
  // Due dates are civil dates, not instants. UTC arithmetic avoids DST gaps.
  static DateTime date(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
  static DateTime today(String timezone, {DateTime? now}) {
    final local = tz.TZDateTime.from(
      now ?? DateTime.now(),
      tz.getLocation(timezone),
    );
    return date(local);
  }

  static int daysLeft(DateTime due, DateTime today) =>
      date(due).difference(date(today)).inDays;
  static DueStatus urgency(DueItem item, DateTime today, {int? warningDays}) {
    if (item.isClosed) return item.status;
    final days = daysLeft(item.dueDate, today);
    if (days < 0) return DueStatus.overdue;
    if (days == 0) return DueStatus.dueToday;
    final reminders = item.reminderConfiguration;
    final window =
        warningDays ??
        (reminders.enabled && reminders.daysBefore.isNotEmpty
            ? reminders.daysBefore.reduce((a, b) => a > b ? a : b)
            : 15);
    if (days <= window) return DueStatus.dueSoon;
    return DueStatus.upcoming;
  }

  static DueStatus status(DueItem item, DateTime today) {
    final u = urgency(item, today);
    if ([DueStatus.overdue, DueStatus.dueToday].contains(u) || item.isClosed) {
      return u;
    }
    return item.status == DueStatus.inProgress ? DueStatus.inProgress : u;
  }

  static String relative(DateTime due, DateTime today) {
    final days = daysLeft(due, today);
    if (days < 0) return '${-days} ${days == -1 ? 'day' : 'days'} overdue';
    if (days == 0) return 'Due today';
    if (days == 1) return '1 day left';
    return '$days days left';
  }

  static String format(DateTime date, {bool year = false}) =>
      DateFormat(year ? 'd MMM yyyy' : 'd MMM').format(date);
  static DateTime? next(DueItem item) {
    final d = date(item.dueDate);
    if (item.frequency == Frequency.oneTime) return null;
    if (item.frequency == Frequency.weekly) {
      return d.add(const Duration(days: 7));
    }
    if (item.frequency == Frequency.custom) {
      final days = int.tryParse(item.recurrenceRule ?? '');
      if (days == null || days < 1) {
        throw ArgumentError(
          'Custom recurrence must be a positive number of days.',
        );
      }
      return d.add(Duration(days: days));
    }
    final months = switch (item.frequency) {
      Frequency.monthly => 1,
      Frequency.quarterly => 3,
      Frequency.halfYearly => 6,
      _ => 12,
    };
    final target = DateTime.utc(d.year, d.month + months, 1);
    final last = DateTime.utc(target.year, target.month + 1, 0).day;
    // Preserve an end-of-month schedule, including February and leap years.
    final wasEnd = d.day == DateTime.utc(d.year, d.month + 1, 0).day;
    return DateTime.utc(
      target.year,
      target.month,
      wasEnd || d.day > last ? last : d.day,
    );
  }
}

class DueFilter {
  final String query, segment;
  final DueStatus? status;
  final String? categoryId, assigneeId;
  final Priority? priority;
  final DateTime? from, to;
  const DueFilter({
    this.query = '',
    this.segment = 'All',
    this.status,
    this.categoryId,
    this.assigneeId,
    this.priority,
    this.from,
    this.to,
  });
  List<DueItem> apply(List<DueItem> items, DateTime today, String userId) {
    final q = query.trim().toLowerCase();
    return items.where((i) {
      final s = DueDates.status(i, today), u = DueDates.urgency(i, today);
      if (status == null && i.status == DueStatus.archived) return false;
      if (segment == 'My Items' && i.assignedToUserId != userId) return false;
      if (segment == 'Overdue' && u != DueStatus.overdue) return false;
      if (segment == 'Due Soon' && u != DueStatus.dueSoon) return false;
      if (segment == 'Completed' &&
          ![DueStatus.completed, DueStatus.renewed].contains(i.status)) {
        return false;
      }
      if (segment == 'Today' && u != DueStatus.dueToday) return false;
      if (segment == 'Upcoming' && u != DueStatus.upcoming) return false;
      if (segment == 'Attention' &&
          ![
            DueStatus.overdue,
            DueStatus.dueToday,
            DueStatus.dueSoon,
          ].contains(u)) {
        return false;
      }
      if (segment == 'This Week' &&
          (i.isClosed ||
              DueDates.daysLeft(i.dueDate, today) < 0 ||
              DueDates.daysLeft(i.dueDate, today) > 7 - today.weekday)) {
        return false;
      }
      if (status != null && s != status) return false;
      if (categoryId != null && i.categoryId != categoryId) return false;
      if (assigneeId != null && i.assignedToUserId != assigneeId) return false;
      if (priority != null && i.priority != priority) return false;
      if (from != null &&
          DueDates.date(i.dueDate).isBefore(DueDates.date(from!))) {
        return false;
      }
      if (to != null && DueDates.date(i.dueDate).isAfter(DueDates.date(to!))) {
        return false;
      }
      return q.isEmpty ||
          [
            i.title,
            i.categoryName,
            i.referenceNumber,
            i.authority,
            i.assignedToName,
          ].any((v) => v.toLowerCase().contains(q));
    }).toList();
  }
}
