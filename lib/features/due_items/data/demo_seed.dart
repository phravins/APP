import '../../../shared/models/models.dart';
import '../../../core/utils/due_dates.dart';

WorkspaceData demoSeed({DateTime? now}) {
  final today = DueDates.date(now ?? DateTime.now());
  const orgs = [
    Organisation(
      id: 'realoffice',
      name: 'REALOFFICE',
      slug: 'realoffice',
      address: 'Anna Salai, Chennai, Tamil Nadu',
    ),
    Organisation(
      id: 'osworks',
      name: 'OSWORKS',
      slug: 'osworks',
      industry: 'Technology',
    ),
    Organisation(
      id: 'rootd',
      name: 'Rootd Consulting',
      slug: 'rootd',
      industry: 'Consulting',
      timezone: 'Europe/London',
    ),
  ];
  final users = [
    User(
      id: 'management',
      name: 'Management',
      email: 'demo@duedesk.app',
      memberships: const {
        'realoffice': Role.owner,
        'osworks': Role.admin,
        'rootd': Role.member,
      },
    ),
    User(
      id: 'arun',
      name: 'Arun Kumar',
      email: 'arun@example.com',
      phone: '+91 98765 43210',
      memberships: const {'realoffice': Role.admin, 'osworks': Role.member},
    ),
    User(
      id: 'priya',
      name: 'Priya S',
      email: 'priya@example.com',
      memberships: const {'realoffice': Role.member, 'rootd': Role.owner},
    ),
  ];
  const categoryNames = [
    'Tax',
    'GST',
    'Statutory',
    'Licence',
    'Insurance',
    'Contract',
    'Finance',
    'HR',
    'Compliance',
    'Registration',
    'Certificate',
    'Subscription',
    'Other',
  ];
  final categories = [
    for (final o in orgs)
      for (final name in categoryNames)
        DueCategory(
          id: '${o.id}-${name.toLowerCase()}',
          organisationId: o.id,
          name: name,
        ),
  ];
  final specs = <List<dynamic>>[
    [
      'gst',
      'GSTR-3B Filing',
      'GST',
      13,
      'arun',
      Frequency.monthly,
      Priority.high,
      'GST Portal',
      24500.0,
    ],
    [
      'tax',
      'Professional Tax Payment',
      'Tax',
      0,
      'priya',
      Frequency.halfYearly,
      Priority.high,
      'Greater Chennai Corporation',
      2500.0,
    ],
    [
      'shop',
      'Shop & Establishment Licence',
      'Licence',
      -4,
      'management',
      Frequency.yearly,
      Priority.critical,
      'Tamil Nadu Labour Department',
      null,
    ],
    [
      'fire',
      'Fire Safety Certificate',
      'Certificate',
      38,
      'arun',
      Frequency.yearly,
      Priority.medium,
      'Fire & Rescue Services',
      null,
    ],
    [
      'insurance',
      'Insurance Renewal',
      'Insurance',
      5,
      'priya',
      Frequency.yearly,
      Priority.high,
      'Business insurance',
      48000.0,
    ],
    [
      'vendor',
      'Vendor Agreement Renewal',
      'Contract',
      24,
      'management',
      Frequency.yearly,
      Priority.medium,
      'Northstar Services',
      null,
    ],
    [
      'roc',
      'Annual ROC Filing',
      'Statutory',
      -8,
      'arun',
      Frequency.yearly,
      Priority.medium,
      'Ministry of Corporate Affairs',
      null,
    ],
    [
      'subscription',
      'Workspace Subscription',
      'Subscription',
      3,
      'management',
      Frequency.monthly,
      Priority.low,
      'Workspace Suite',
      1200.0,
    ],
  ];
  final items = [
    for (final s in specs)
      DueItem(
        id: s[0],
        organisationId: 'realoffice',
        title: s[1],
        categoryId: 'realoffice-${(s[2] as String).toLowerCase()}',
        categoryName: s[2],
        description:
            'Review the supporting records, confirm all details with the responsible team, and record the acknowledgement once complete.',
        dueDate: today.add(Duration(days: s[3])),
        frequency: s[5],
        priority: s[6],
        assignedToUserId: s[4],
        assignedToName: users.firstWhere((u) => u.id == s[4]).name,
        createdByUserId: 'management',
        authority: s[7],
        amount: s[8],
        referenceNumber: 'RO-${s[0].toUpperCase()}-${today.year}',
        createdAt: today.subtract(const Duration(days: 20)),
        updatedAt: today.subtract(const Duration(days: 1)),
        status: s[0] == 'roc' ? DueStatus.completed : DueStatus.upcoming,
        completionDate: s[0] == 'roc'
            ? today.subtract(const Duration(days: 2))
            : null,
        completedBy: s[0] == 'roc' ? 'Arun Kumar' : null,
        reminderConfiguration: const ReminderConfiguration(
          daysBefore: [15, 7, 3, 1, 0],
        ),
        documentCount: s[0] == 'gst' || s[0] == 'roc' ? 1 : 0,
        notes: s[0] == 'gst'
            ? 'Reconcile input tax credit before submission.'
            : '',
      ),
  ];
  for (final o in orgs.skip(1)) {
    items.add(
      DueItem(
        id: '${o.id}-annual',
        organisationId: o.id,
        title: o.id == 'rootd'
            ? 'Professional Indemnity Renewal'
            : 'Annual Business Registration',
        categoryId: '${o.id}-registration',
        categoryName: 'Registration',
        dueDate: today.add(const Duration(days: 9)),
        assignedToUserId: 'management',
        assignedToName: 'Management',
        createdByUserId: 'management',
        createdAt: today,
        updatedAt: today,
        frequency: Frequency.yearly,
      ),
    );
  }
  return WorkspaceData(
    organisations: orgs,
    users: users,
    categories: categories,
    items: items,
    documents: [
      for (final id in ['gst', 'roc'])
        Document(
          id: 'doc-$id',
          organisationId: 'realoffice',
          dueItemId: id,
          filename: id == 'gst'
              ? 'GSTR3B_working_paper.pdf'
              : 'ROC_acknowledgement.pdf',
          fileType: 'pdf',
          fileSize: 830,
          mimeType: 'application/pdf',
          url: 'asset:assets/demo/evidence.pdf',
          uploadedBy: 'Priya S',
          uploadedAt: today.subtract(const Duration(days: 2)),
        ),
    ],
    activities: [
      for (final i in items)
        ActivityEvent(
          id: 'created-${i.id}',
          organisationId: i.organisationId,
          dueItemId: i.id,
          type: 'created',
          description: 'DueItem created and assigned to ${i.assignedToName}',
          actor: 'Management',
          timestamp: i.createdAt,
        ),
      ActivityEvent(
        id: 'gst-note',
        organisationId: 'realoffice',
        dueItemId: 'gst',
        type: 'document_uploaded',
        description: 'Uploaded GSTR3B_working_paper.pdf',
        actor: 'Priya S',
        timestamp: today.subtract(const Duration(days: 2)),
      ),
      ActivityEvent(
        id: 'roc-complete',
        organisationId: 'realoffice',
        dueItemId: 'roc',
        type: 'completed',
        description: 'Filing completed. Acknowledgement recorded.',
        actor: 'Arun Kumar',
        timestamp: today.subtract(const Duration(days: 2)),
      ),
    ],
    notifications: [
      for (final i
          in items
              .where((i) => !i.isClosed && i.organisationId == 'realoffice')
              .take(5))
        DueNotification(
          id: 'notification-${i.id}',
          organisationId: i.organisationId,
          dueItemId: i.id,
          type: DueDates.urgency(i, today).name,
          message:
              '${i.title}: ${DueDates.relative(i.dueDate, today).toLowerCase()}.',
          timestamp: today.add(const Duration(hours: 8)),
          read: i.id == 'fire',
        ),
    ],
  );
}
