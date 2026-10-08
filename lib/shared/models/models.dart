import 'package:uuid/uuid.dart';

String newId() => const Uuid().v4();
typedef Json = Map<String, dynamic>;
DateTime? dateValue(dynamic value) =>
    value == null ? null : DateTime.parse(value as String);

enum Role { owner, admin, member }

enum DueStatus {
  upcoming,
  dueSoon,
  dueToday,
  overdue,
  inProgress,
  completed,
  renewed,
  archived,
}

enum Priority { low, medium, high, critical }

enum Frequency {
  oneTime,
  weekly,
  monthly,
  quarterly,
  halfYearly,
  yearly,
  custom,
}

extension EnumLabel on Enum {
  String get label => switch (name) {
    'dueSoon' => 'Due Soon',
    'dueToday' => 'Due Today',
    'inProgress' => 'In Progress',
    'oneTime' => 'One time',
    'halfYearly' => 'Half yearly',
    _ => '${name[0].toUpperCase()}${name.substring(1)}',
  };
}

class User {
  final String id, name, email, phone, currentOrganisationId, status;
  final String? avatarUrl;
  final DateTime createdAt;
  final Map<String, Role> memberships;
  final Map<String, bool> membershipActive;
  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.avatarUrl,
    this.currentOrganisationId = 'realoffice',
    this.status = 'active',
    DateTime? createdAt,
    this.memberships = const {'realoffice': Role.member},
    this.membershipActive = const {},
  }) : createdAt = createdAt ?? DateTime.now();
  Role? roleIn(String org) =>
      status == 'active' && (membershipActive[org] ?? true)
      ? memberships[org]
      : null;
  String statusIn(String org) => status != 'active'
      ? status
      : (membershipActive[org] ?? true)
      ? 'active'
      : 'inactive';
  Json toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'currentOrganisationId': currentOrganisationId,
    'status': status,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'memberships': memberships.map((k, v) => MapEntry(k, v.name)),
    'membershipActive': membershipActive,
  };
  factory User.fromJson(Json j) => User(
    id: j['id'],
    name: j['name'],
    email: j['email'],
    phone: j['phone'] ?? '',
    avatarUrl: j['avatarUrl'],
    currentOrganisationId: j['currentOrganisationId'] ?? 'realoffice',
    status: j['status'] ?? 'active',
    createdAt: dateValue(j['createdAt']),
    membershipActive: Map<String, bool>.from(j['membershipActive'] ?? {}),
    memberships: (j['memberships'] as Map? ?? {}).map(
      (k, v) => MapEntry(k.toString(), Role.values.byName(v)),
    ),
  );
  User copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    String? status,
    Map<String, Role>? memberships,
    Map<String, bool>? membershipActive,
  }) => User.fromJson({
    ...toJson(),
    'name': ?name,
    'phone': ?phone,
    'avatarUrl': ?avatarUrl,
    'status': ?status,
    'membershipActive': ?membershipActive,
    if (memberships != null)
      'memberships': memberships.map((k, v) => MapEntry(k, v.name)),
  });
}

class Organisation {
  final String id,
      name,
      slug,
      industry,
      timezone,
      financialYear,
      status,
      address;
  final String? logoUrl;
  const Organisation({
    required this.id,
    required this.name,
    required this.slug,
    this.industry = 'Professional services',
    this.timezone = 'Asia/Kolkata',
    this.financialYear = 'April – March',
    this.status = 'active',
    this.address = '',
    this.logoUrl,
  });
  Json toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'industry': industry,
    'timezone': timezone,
    'financialYear': financialYear,
    'status': status,
    'address': address,
    'logoUrl': logoUrl,
  };
  factory Organisation.fromJson(Json j) => Organisation(
    id: j['id'],
    name: j['name'],
    slug: j['slug'],
    industry: j['industry'] ?? '',
    timezone: j['timezone'] ?? 'UTC',
    financialYear: j['financialYear'] ?? '',
    status: j['status'] ?? 'active',
    address: j['address'] ?? '',
    logoUrl: j['logoUrl'],
  );
}

class DueCategory {
  final String id, organisationId, name, icon, description;
  final int accent;
  final bool active;
  const DueCategory({
    required this.id,
    required this.name,
    this.organisationId = 'realoffice',
    this.icon = 'folder',
    this.accent = 0xFF6C63FF,
    this.description = '',
    this.active = true,
  });
  Json toJson() => {
    'id': id,
    'organisationId': organisationId,
    'name': name,
    'icon': icon,
    'accent': accent,
    'description': description,
    'active': active,
  };
  factory DueCategory.fromJson(Json j) => DueCategory(
    id: j['id'],
    name: j['name'],
    organisationId: j['organisationId'],
    icon: j['icon'] ?? 'folder',
    accent: j['accent'] ?? 0xFF6C63FF,
    description: j['description'] ?? '',
    active: j['active'] ?? true,
  );
}

class ReminderConfiguration {
  final bool enabled;
  final List<int> daysBefore;
  final List<String> notificationMethods;
  const ReminderConfiguration({
    this.enabled = true,
    this.daysBefore = const [7, 3, 1, 0],
    this.notificationMethods = const ['push', 'email'],
  });
  Json toJson() => {
    'enabled': enabled,
    'daysBefore': daysBefore,
    'notificationMethods': notificationMethods,
  };
  factory ReminderConfiguration.fromJson(Json j) => ReminderConfiguration(
    enabled: j['enabled'] ?? true,
    daysBefore: List<int>.from(j['daysBefore'] ?? [7, 3, 1, 0]),
    notificationMethods: List<String>.from(
      j['notificationMethods'] ?? ['push', 'email'],
    ),
  );
}

class DueItem {
  final String id, organisationId, title, description, categoryId, categoryName;
  final DateTime dueDate, createdAt, updatedAt;
  final DateTime? startDate, completionDate, nextDueDate, archivedAt;
  final Frequency frequency;
  final String? recurrenceRule;
  final Priority priority;
  final DueStatus status;
  final String assignedToUserId,
      assignedToName,
      createdByUserId,
      referenceNumber,
      authority,
      currency,
      notes;
  final String? completedBy;
  final double? amount;
  final int documentCount;
  final ReminderConfiguration reminderConfiguration;
  const DueItem({
    required this.id,
    required this.organisationId,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    required this.dueDate,
    required this.assignedToUserId,
    required this.assignedToName,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.startDate,
    this.frequency = Frequency.oneTime,
    this.recurrenceRule,
    this.priority = Priority.medium,
    this.status = DueStatus.upcoming,
    this.referenceNumber = '',
    this.authority = '',
    this.amount,
    this.currency = 'INR',
    this.notes = '',
    this.completionDate,
    this.completedBy,
    this.nextDueDate,
    this.documentCount = 0,
    this.reminderConfiguration = const ReminderConfiguration(),
    this.archivedAt,
  });
  bool get isClosed => [
    DueStatus.completed,
    DueStatus.renewed,
    DueStatus.archived,
  ].contains(status);
  Json toJson() => {
    'id': id,
    'organisationId': organisationId,
    'title': title,
    'description': description,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'dueDate': dueDate.toIso8601String(),
    'startDate': startDate?.toIso8601String(),
    'frequency': frequency.name,
    'recurrenceRule': recurrenceRule,
    'priority': priority.name,
    'status': status.name,
    'assignedToUserId': assignedToUserId,
    'assignedToName': assignedToName,
    'createdByUserId': createdByUserId,
    'referenceNumber': referenceNumber,
    'authority': authority,
    'amount': amount,
    'currency': currency,
    'notes': notes,
    'completionDate': completionDate?.toIso8601String(),
    'completedBy': completedBy,
    'nextDueDate': nextDueDate?.toIso8601String(),
    'documentCount': documentCount,
    'reminderConfiguration': reminderConfiguration.toJson(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'archivedAt': archivedAt?.toIso8601String(),
  };
  factory DueItem.fromJson(Json j) => DueItem(
    id: j['id'],
    organisationId: j['organisationId'],
    title: j['title'],
    description: j['description'] ?? '',
    categoryId: j['categoryId'],
    categoryName: j['categoryName'],
    dueDate: DateTime.parse(j['dueDate']),
    startDate: dateValue(j['startDate']),
    frequency: Frequency.values.byName(j['frequency'] ?? 'oneTime'),
    recurrenceRule: j['recurrenceRule'],
    priority: Priority.values.byName(j['priority'] ?? 'medium'),
    status: DueStatus.values.byName(j['status'] ?? 'upcoming'),
    assignedToUserId: j['assignedToUserId'],
    assignedToName: j['assignedToName'],
    createdByUserId: j['createdByUserId'],
    referenceNumber: j['referenceNumber'] ?? '',
    authority: j['authority'] ?? '',
    amount: (j['amount'] as num?)?.toDouble(),
    currency: j['currency'] ?? 'INR',
    notes: j['notes'] ?? '',
    completionDate: dateValue(j['completionDate']),
    completedBy: j['completedBy'],
    nextDueDate: dateValue(j['nextDueDate']),
    documentCount: j['documentCount'] ?? 0,
    reminderConfiguration: ReminderConfiguration.fromJson(
      Map<String, dynamic>.from(j['reminderConfiguration'] ?? {}),
    ),
    createdAt: DateTime.parse(j['createdAt']),
    updatedAt: DateTime.parse(j['updatedAt']),
    archivedAt: dateValue(j['archivedAt']),
  );
  DueItem patch(Json changes) => DueItem.fromJson({
    ...toJson(),
    ...changes,
    'updatedAt': DateTime.now().toIso8601String(),
  });
}

class Document {
  final String id,
      organisationId,
      dueItemId,
      filename,
      fileType,
      mimeType,
      url,
      uploadedBy;
  final int fileSize;
  final DateTime uploadedAt;
  const Document({
    required this.id,
    required this.organisationId,
    required this.dueItemId,
    required this.filename,
    required this.fileType,
    required this.fileSize,
    required this.mimeType,
    required this.url,
    required this.uploadedBy,
    required this.uploadedAt,
  });
  Json toJson() => {
    'id': id,
    'organisationId': organisationId,
    'dueItemId': dueItemId,
    'filename': filename,
    'fileType': fileType,
    'fileSize': fileSize,
    'mimeType': mimeType,
    'url': url,
    'uploadedBy': uploadedBy,
    'uploadedAt': uploadedAt.toUtc().toIso8601String(),
  };
  factory Document.fromJson(Json j) => Document(
    id: j['id'],
    organisationId: j['organisationId'],
    dueItemId: j['dueItemId'],
    filename: j['filename'],
    fileType: j['fileType'],
    fileSize: j['fileSize'],
    mimeType: j['mimeType'],
    url: j['url'],
    uploadedBy: j['uploadedBy'],
    uploadedAt: DateTime.parse(j['uploadedAt']),
  );
}

class ActivityEvent {
  final String id, organisationId, dueItemId, type, description, actor;
  final DateTime timestamp;
  final Json metadata;
  const ActivityEvent({
    required this.id,
    required this.organisationId,
    required this.dueItemId,
    required this.type,
    required this.description,
    required this.actor,
    required this.timestamp,
    this.metadata = const {},
  });
  Json toJson() => {
    'id': id,
    'organisationId': organisationId,
    'dueItemId': dueItemId,
    'type': type,
    'description': description,
    'actor': actor,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'metadata': metadata,
  };
  factory ActivityEvent.fromJson(Json j) => ActivityEvent(
    id: j['id'],
    organisationId: j['organisationId'],
    dueItemId: j['dueItemId'],
    type: j['type'],
    description: j['description'],
    actor: j['actor'],
    timestamp: DateTime.parse(j['timestamp']),
    metadata: Map<String, dynamic>.from(j['metadata'] ?? {}),
  );
}

class DueNotification {
  final String id, organisationId, dueItemId, type, message;
  final DateTime timestamp;
  final bool read;
  const DueNotification({
    required this.id,
    required this.organisationId,
    required this.dueItemId,
    required this.type,
    required this.message,
    required this.timestamp,
    this.read = false,
  });
  Json toJson() => {
    'id': id,
    'organisationId': organisationId,
    'dueItemId': dueItemId,
    'type': type,
    'message': message,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'read': read,
  };
  factory DueNotification.fromJson(Json j) => DueNotification(
    id: j['id'],
    organisationId: j['organisationId'],
    dueItemId: j['dueItemId'],
    type: j['type'],
    message: j['message'],
    timestamp: DateTime.parse(j['timestamp']),
    read: j['read'] ?? false,
  );
}

class WorkspaceData {
  final String? cachedForUserId;
  final List<Organisation> organisations;
  final List<User> users;
  final List<DueCategory> categories;
  final List<DueItem> items;
  final List<Document> documents;
  final List<ActivityEvent> activities;
  final List<DueNotification> notifications;
  const WorkspaceData({
    this.cachedForUserId,
    this.organisations = const [],
    this.users = const [],
    this.categories = const [],
    this.items = const [],
    this.documents = const [],
    this.activities = const [],
    this.notifications = const [],
  });
  Json toJson() => {
    'cachedForUserId': cachedForUserId,
    'organisations': organisations.map((e) => e.toJson()).toList(),
    'users': users.map((e) => e.toJson()).toList(),
    'categories': categories.map((e) => e.toJson()).toList(),
    'items': items.map((e) => e.toJson()).toList(),
    'documents': documents.map((e) => e.toJson()).toList(),
    'activities': activities.map((e) => e.toJson()).toList(),
    'notifications': notifications.map((e) => e.toJson()).toList(),
  };
  factory WorkspaceData.fromJson(Json j) => WorkspaceData(
    cachedForUserId: j['cachedForUserId'],
    organisations: (j['organisations'] as List? ?? [])
        .map((e) => Organisation.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    users: (j['users'] as List? ?? [])
        .map((e) => User.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    categories: (j['categories'] as List? ?? [])
        .map((e) => DueCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    items: (j['items'] as List? ?? [])
        .map((e) => DueItem.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    documents: (j['documents'] as List? ?? [])
        .map((e) => Document.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    activities: (j['activities'] as List? ?? [])
        .map((e) => ActivityEvent.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    notifications: (j['notifications'] as List? ?? [])
        .map((e) => DueNotification.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
  WorkspaceData copyWith({
    String? cachedForUserId,
    List<Organisation>? organisations,
    List<User>? users,
    List<DueCategory>? categories,
    List<DueItem>? items,
    List<Document>? documents,
    List<ActivityEvent>? activities,
    List<DueNotification>? notifications,
  }) => WorkspaceData(
    cachedForUserId: cachedForUserId ?? this.cachedForUserId,
    organisations: organisations ?? this.organisations,
    users: users ?? this.users,
    categories: categories ?? this.categories,
    items: items ?? this.items,
    documents: documents ?? this.documents,
    activities: activities ?? this.activities,
    notifications: notifications ?? this.notifications,
  );
}
