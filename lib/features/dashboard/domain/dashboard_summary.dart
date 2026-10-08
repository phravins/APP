import '../../../core/utils/due_dates.dart';
import '../../../shared/models/models.dart';

class DashboardSummary {
  final int overdue, today, thisWeek, dueSoon, upcoming, completed;
  const DashboardSummary({
    required this.overdue,
    required this.today,
    required this.thisWeek,
    required this.dueSoon,
    required this.upcoming,
    required this.completed,
  });
  int get attention => overdue + today + dueSoon;
  factory DashboardSummary.fromItems(List<DueItem> items, DateTime date) {
    int count(DueStatus status) =>
        items.where((i) => DueDates.urgency(i, date) == status).length;
    return DashboardSummary(
      overdue: count(DueStatus.overdue),
      today: count(DueStatus.dueToday),
      dueSoon: count(DueStatus.dueSoon),
      upcoming: count(DueStatus.upcoming),
      thisWeek: items
          .where(
            (i) =>
                !i.isClosed &&
                DueDates.daysLeft(i.dueDate, date) >= 0 &&
                DueDates.daysLeft(i.dueDate, date) <= 7 - date.weekday,
          )
          .length,
      completed: items
          .where(
            (i) => [DueStatus.completed, DueStatus.renewed].contains(i.status),
          )
          .length,
    );
  }
}
