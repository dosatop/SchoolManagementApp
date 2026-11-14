// ====================================================================
// ANNOUNCEMENT MODELS
// ====================================================================
// Tolerant parsing: camelCase or PascalCase, ints or enum names.

dynamic _pick(dynamic json, List<String> keys) {
  if (json is! Map) return null;
  for (final key in keys) {
    if (json[key] != null) return json[key];
    final pascal = key[0].toUpperCase() + key.substring(1);
    if (json[pascal] != null) return json[pascal];
  }
  return null;
}

String _str(dynamic json, List<String> keys, [String fallback = '']) {
  final v = _pick(json, keys);
  final s = v == null ? '' : '$v'.trim();
  return s.isEmpty ? fallback : s;
}

String? _strOrNull(dynamic json, List<String> keys) {
  final s = _str(json, keys);
  return s.isEmpty ? null : s;
}

int _int(dynamic json, List<String> keys, [int fallback = 0]) {
  final v = _pick(json, keys);
  if (v is num) return v.toInt();
  return int.tryParse('${v ?? ''}') ?? fallback;
}

int? _intOrNull(dynamic json, List<String> keys) {
  final v = _pick(json, keys);
  if (v is num) return v.toInt();
  return int.tryParse('${v ?? ''}');
}

bool _bool(dynamic json, List<String> keys) {
  final v = _pick(json, keys);
  if (v is bool) return v;
  return '$v'.toLowerCase() == 'true';
}

DateTime? _date(dynamic json, List<String> keys) {
  final v = _pick(json, keys);
  if (v == null) return null;
  return DateTime.tryParse('$v')?.toLocal();
}

List<T> _list<T>(dynamic json, List<String> keys, T Function(dynamic) map) {
  final v = _pick(json, keys);
  if (v is! List) return <T>[];
  final out = <T>[];
  for (final item in v) {
    try {
      out.add(map(item));
    } catch (_) {}
  }
  return out;
}

// ====================================================================
// AUDIENCE + PRIORITY (match the backend enums)
// ====================================================================

class Audience {
  static const everyone = 1;
  static const teachers = 2;
  static const students = 3;
  static const parents = 4;
  static const studentsAndParents = 5;
  static const admins = 6;

  static String label(int value) {
    switch (value) {
      case teachers:
        return 'Teachers';
      case students:
        return 'Students';
      case parents:
        return 'Parents';
      case studentsAndParents:
        return 'Students & parents';
      case admins:
        return 'School admins';
      default:
        return 'Everyone';
    }
  }

  static int parse(dynamic v) {
    if (v is num) return v.toInt();
    final s = '${v ?? ''}'.toLowerCase();
    final n = int.tryParse(s);
    if (n != null) return n;
    if (s.contains('and')) return studentsAndParents;
    if (s.startsWith('teach')) return teachers;
    if (s.startsWith('stud')) return students;
    if (s.startsWith('par')) return parents;
    if (s.startsWith('adm')) return admins;
    return everyone;
  }
}

class Priority {
  static const normal = 1;
  static const important = 2;
  static const urgent = 3;

  static String label(int value) {
    switch (value) {
      case important:
        return 'Important';
      case urgent:
        return 'Urgent';
      default:
        return 'Normal';
    }
  }

  static int parse(dynamic v) {
    if (v is num) return v.toInt();
    final s = '${v ?? ''}'.toLowerCase();
    final n = int.tryParse(s);
    if (n != null) return n;
    if (s.startsWith('imp')) return important;
    if (s.startsWith('urg')) return urgent;
    return normal;
  }
}

// ====================================================================
// ANNOUNCEMENT
// ====================================================================

class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final int audience;
  final String audienceLabel;
  final int priority;
  final bool isPinned;
  final String? schoolId;
  final String? schoolName;
  final String? classId;
  final String? className;
  final String createdByName;
  final String createdByRole;
  final bool isMine;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final bool isRead;
  final bool canManage;
  final int? readCount;
  final int? pushSentCount;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    this.audience = Audience.everyone,
    this.audienceLabel = 'Everyone',
    this.priority = Priority.normal,
    this.isPinned = false,
    this.schoolId,
    this.schoolName,
    this.classId,
    this.className,
    this.createdByName = '',
    this.createdByRole = '',
    this.isMine = false,
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
    this.isRead = false,
    this.canManage = false,
    this.readCount,
    this.pushSentCount,
  });

  bool get isUrgent => priority == Priority.urgent;
  bool get isImportant => priority == Priority.important;
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  /// "JSS 1 · Students & parents" or "All schools · Everyone".
  String get targetLabel {
    final scope = className ?? schoolName;
    return scope == null ? audienceLabel : '$scope · $audienceLabel';
  }

  AnnouncementModel copyWith({bool? isRead}) => AnnouncementModel(
    id: id,
    title: title,
    body: body,
    audience: audience,
    audienceLabel: audienceLabel,
    priority: priority,
    isPinned: isPinned,
    schoolId: schoolId,
    schoolName: schoolName,
    classId: classId,
    className: className,
    createdByName: createdByName,
    createdByRole: createdByRole,
    isMine: isMine,
    createdAt: createdAt,
    updatedAt: updatedAt,
    expiresAt: expiresAt,
    isRead: isRead ?? this.isRead,
    canManage: canManage,
    readCount: readCount,
    pushSentCount: pushSentCount,
  );

  factory AnnouncementModel.fromJson(dynamic json) {
    final audience = Audience.parse(_pick(json, ['audience']));
    return AnnouncementModel(
      id: _str(json, ['id', 'announcementId']),
      title: _str(json, ['title'], 'Announcement'),
      body: _str(json, ['body', 'message']),
      audience: audience,
      audienceLabel: _str(json, ['audienceLabel'], Audience.label(audience)),
      priority: Priority.parse(_pick(json, ['priority'])),
      isPinned: _bool(json, ['isPinned']),
      schoolId: _strOrNull(json, ['schoolId']),
      schoolName: _strOrNull(json, ['schoolName']),
      classId: _strOrNull(json, ['classId']),
      className: _strOrNull(json, ['className']),
      createdByName: _str(json, ['createdByName'], 'School'),
      createdByRole: _str(json, ['createdByRole']),
      isMine: _bool(json, ['isMine']),
      createdAt: _date(json, ['createdAt']),
      updatedAt: _date(json, ['updatedAt']),
      expiresAt: _date(json, ['expiresAt']),
      isRead: _bool(json, ['isRead']),
      canManage: _bool(json, ['canManage']),
      readCount: _intOrNull(json, ['readCount']),
      pushSentCount: _intOrNull(json, ['pushSentCount']),
    );
  }
}

class AnnouncementPage {
  final List<AnnouncementModel> items;
  final int page;
  final bool hasMore;
  final int total;
  final int unreadCount;

  const AnnouncementPage({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.total,
    required this.unreadCount,
  });

  factory AnnouncementPage.fromJson(dynamic json) => AnnouncementPage(
    items: _list(json, ['items'], AnnouncementModel.fromJson),
    page: _int(json, ['page'], 1),
    hasMore: _bool(json, ['hasMore']),
    total: _int(json, ['total']),
    unreadCount: _int(json, ['unreadCount']),
  );
}

// ====================================================================
// COMPOSE OPTIONS — what the signed-in user may target
// ====================================================================

class ComposeOption {
  final String id;
  final String name;
  final String? schoolId;

  const ComposeOption({required this.id, required this.name, this.schoolId});
}

class AudienceOption {
  final int value;
  final String label;

  const AudienceOption({required this.value, required this.label});
}

class ComposeOptions {
  final String role;
  final String? schoolId;
  final bool requiresClass;
  final bool canTargetAllSchools;
  final List<AudienceOption> audiences;
  final List<ComposeOption> schools;
  final List<ComposeOption> classes;

  const ComposeOptions({
    required this.role,
    this.schoolId,
    this.requiresClass = false,
    this.canTargetAllSchools = false,
    this.audiences = const [],
    this.schools = const [],
    this.classes = const [],
  });

  factory ComposeOptions.fromJson(dynamic json) => ComposeOptions(
    role: _str(json, ['role']),
    schoolId: _strOrNull(json, ['schoolId']),
    requiresClass: _bool(json, ['requiresClass']),
    canTargetAllSchools: _bool(json, ['canTargetAllSchools']),
    audiences: _list(json, ['audiences'], (a) {
      final v = Audience.parse(_pick(a, ['value', 'name']));
      return AudienceOption(
        value: v,
        label: _str(a, ['label'], Audience.label(v)),
      );
    }),
    schools: _list(
      json,
      ['schools'],
      (s) => ComposeOption(
        id: _str(s, ['schoolId', 'id']),
        name: _str(s, ['schoolName', 'name'], 'School'),
      ),
    ),
    classes: _list(
      json,
      ['classes'],
      (c) => ComposeOption(
        id: _str(c, ['classId', 'id']),
        name: _str(c, ['className', 'name'], 'Class'),
        schoolId: _strOrNull(c, ['schoolId']),
      ),
    ),
  );
}
