import '../../../shared/models/models.dart';

class DueTemplate {
  final String id, title, category, description;
  final Frequency frequency;
  final Priority priority;
  const DueTemplate(
    this.id,
    this.title,
    this.category,
    this.description,
    this.frequency,
    this.priority,
  );
  static const all = [
    DueTemplate(
      'gst',
      'GSTR-3B Filing',
      'GST',
      'Prepare, review and submit the return. Attach the filing acknowledgement.',
      Frequency.monthly,
      Priority.high,
    ),
    DueTemplate(
      'insurance',
      'Insurance Renewal',
      'Insurance',
      'Review coverage and renew the policy. Attach the renewed policy document.',
      Frequency.yearly,
      Priority.high,
    ),
    DueTemplate(
      'licence',
      'Licence Renewal',
      'Licence',
      'Confirm renewal requirements and record the renewed licence.',
      Frequency.yearly,
      Priority.high,
    ),
    DueTemplate(
      'contract',
      'Contract Review',
      'Contract',
      'Review terms, confirm ownership and record the renewal decision.',
      Frequency.oneTime,
      Priority.medium,
    ),
  ];
  static DueTemplate? find(String? id) {
    for (final template in all) {
      if (template.id == id) return template;
    }
    return null;
  }
}
