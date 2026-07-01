import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class ReportModel {
  final int id;
  final String category;
  final String description;
  final String status;
  final String county;
  final double? latitude;
  final double? longitude;
  final XFile? photo;
  final String? photoReference;
  final String? photoHash;
  final int? assignedDepartmentId;
  final String createdAt;
  final String updatedAt;
  final int citizenId;

  const ReportModel({
    required this.id,
    required this.category,
    required this.description,
    required this.status,
    required this.county,
    this.latitude,
    this.longitude,
    this.photo,
    this.photoReference,
    this.photoHash,
    this.assignedDepartmentId,
    required this.createdAt,
    required this.updatedAt,
    required this.citizenId,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? 0,
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'submitted',
      county: json['county'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      photoReference: json['photo_reference'],
      photoHash: json['photo_hash'],
      assignedDepartmentId: json['assigned_department_id'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      citizenId: json['citizen_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'description': description,
      'county': county,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (photoReference != null) 'photo_reference': photoReference,
    };
  }

  // Display helpers
  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'submitted':
        return 'Submitted';
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  String get categoryLabel {
    switch (category.toLowerCase()) {
      case 'roads':
        return 'Roads';
      case 'water':
        return 'Water';
      case 'bridges':
        return 'Bridges';
      case 'streetlights':
        return 'Streetlights';
      case 'public_facilities':
        return 'Facilities';
      case 'safety':
        return 'Safety / Crime';
      case 'other':
        return 'Other';
      default:
        return category;
    }
  }
  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }

  String get referenceNumber =>
      '#JK-${createdAt.substring(0, 4)}-${id.toString().padLeft(6, '0')}';
}

// Submit request model
class SubmitReportRequest {
  final String category;
  final String description;
  final String county;
  final String urgency;
  final double? latitude;
  final double? longitude;
  final XFile? photo;
  final String? photoUrl;

  const SubmitReportRequest({
    required this.category,
    required this.description,
    required this.county,
    required this.urgency,
    this.latitude,
    this.longitude,
    this.photo,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'description': description,
      'county': county,
      'urgency': urgency,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
      if (photoUrl != null) 'photo_reference': photoUrl,
    };
  }

  Future<FormData> toFormData() async {
    final map = <String, dynamic>{
      'category': category,
      'description': description,
      'county': county,
      'urgency': urgency,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
      if (photoUrl != null) 'photo_reference': photoUrl,
    };

    if (photo != null && photoUrl == null) {
      final bytes = await photo!.readAsBytes();
      map['photo_reference'] = MultipartFile.fromBytes(
        bytes,
        filename: photo!.name,
      );
    }

    return FormData.fromMap(map);
  }
}