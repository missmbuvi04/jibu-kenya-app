class DepartmentModel {
  final int id;
  final String name;
  final String type;
  final String county;
  final bool isActive;
  final String contactPhone;

  const DepartmentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.county,
    required this.isActive,
    required this.contactPhone,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      county: json['county'] ?? '',
      isActive: json['is_active'] ?? true,
      contactPhone: json['contact_phone'] ?? '',
    );
  }
}

class AuditLogModel {
  final int id;
  final String userLabel;
  final String action;
  final String tableName;
  final String timestamp;
  final String ipAddress;

  const AuditLogModel({
    required this.id,
    required this.userLabel,
    required this.action,
    required this.tableName,
    required this.timestamp,
    required this.ipAddress,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] ?? 0,
      userLabel: json['user_email'] ?? json['user']?.toString() ?? 'Unknown',
      action: json['action'] ?? '',
      tableName: json['table_name'] ?? '',
      timestamp: json['timestamp'] ?? '',
      ipAddress: json['ip_address'] ?? '',
    );
  }

  String get formattedTime {
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp;
    }
  }
}