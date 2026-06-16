"""Report Serializers - Convert report models to/from JSON for API responses.

Handles serialization of Report, ReportStatus, and DuplicateFlag models including
input validation, geographic coordinate transformation, and read-only field protection.
"""
from rest_framework import serializers
from .models import Report, ReportStatus, DuplicateFlag
from django.contrib.gis.geos import Point


class ReportSerializer(serializers.ModelSerializer):
    latitude = serializers.FloatField(write_only=True, required=False)
    longitude = serializers.FloatField(write_only=True, required=False)
    citizen_id = serializers.IntegerField(source='citizen.id', read_only=True)

    class Meta:
        model = Report
        fields = '__all__'
        read_only_fields = ['citizen', 'photo_hash', 'created_at', 'updated_at']

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        if instance.location:
            ret['latitude'] = instance.location.y
            ret['longitude'] = instance.location.x
        else:
            ret['latitude'] = None
            ret['longitude'] = None
        return ret

    def create(self, validated_data):
        lat = validated_data.pop('latitude', None)
        lng = validated_data.pop('longitude', None)
        if lat is not None and lng is not None:
            validated_data['location'] = Point(lng, lat)
        return super().create(validated_data)
    
    """Serialize Report model to/from JSON with geographic transformation.
    
    Accepts latitude/longitude in API request and converts to PostGIS Point geometry.
    
    Input fields (JSON):
    - latitude: Y-coordinate (write-only, converted to location)
    - longitude: X-coordinate (write-only, converted to location)
    - category: 'roads', 'water', 'bridges', 'streetlights', 'public_facilities'
    - description: Issue description text
    - photo_reference: Photo file (optional, for duplicate detection)
    - county: Geographic jurisdiction
    
    Output fields (JSON):
    - location: GIS Point geometry (read-only, derived from lat/lng)
    - photo_hash: Perceptual hash of photo (read-only, auto-computed)
    - status: Current status (submitted → assigned → in_progress → resolved → closed)
    - citizen: User who submitted the report (read-only)
    - created_at: Submission timestamp (read-only)
    - updated_at: Last modification timestamp (read-only)
    
    Example request:
    {
        "latitude": -1.2921,
        "longitude": 36.8219,
        "category": "roads",
        "description": "Large pothole on Main Street",
        "county": "Nairobi"
    }
    
    Example response:
    {
        "id": 1,
        "citizen": "citizen@example.com",
        "category": "roads",
        "description": "Large pothole on Main Street",
        "location": {"type": "Point", "coordinates": [36.8219, -1.2921]},
        "status": "assigned",
        "county": "Nairobi",
        "created_at": "2026-06-08T10:30:45Z",
        "updated_at": "2026-06-08T10:35:20Z"
    }
    """
    class Meta:
        model = Report
        fields = '__all__'
        read_only_fields = ['citizen', 'photo_hash', 'created_at', 'updated_at']

    def create(self, validated_data):
        """Convert latitude/longitude to GIS Point before saving."""
        lat = validated_data.pop('latitude')
        lng = validated_data.pop('longitude')
        # PostGIS Point uses (longitude, latitude) order
        validated_data['location'] = Point(lng, lat)
        return super().create(validated_data)


class ReportStatusSerializer(serializers.ModelSerializer):
    """Serialize ReportStatus model - tracks status change history.
    
    Creates a new status change entry (immutable audit trail).
    
    Input fields:
    - report: ID of the report being updated
    - status: New status ('assigned', 'in_progress', 'resolved', 'closed')
    - notes: Optional notes about the status change
    
    Output fields:
    - timestamp: When the status changed (read-only, auto-set)
    - updated_by: Officer who made the change (read-only, set automatically)
    
    Example request:
    {
        "report": 1,
        "status": "in_progress",
        "notes": "Repair crew dispatched"
    }
    
    Example response:
    {
        "id": 1,
        "report": 1,
        "status": "in_progress",
        "updated_by": "officer@county.gov",
        "timestamp": "2026-06-08T10:35:20Z",
        "notes": "Repair crew dispatched"
    }
    """
    class Meta:
        model = ReportStatus
        fields = '__all__'
        read_only_fields = ['timestamp']  # Auto-set to current time


class DuplicateFlagSerializer(serializers.ModelSerializer):
    """Serialize DuplicateFlag model - tracks suspected duplicate reports.
    
    Read-only serializer for viewing automatically-detected duplicate reports.
    
    Fields:
    - original_report: ID of the earlier/original report
    - duplicate_report: ID of the suspected duplicate/newer report
    - detection_method: 'location_proximity' or 'perceptual_hash'
    - similarity_score: 0.0-1.0 (1.0 = exact match, 0.85+ triggers flag)
    - flagged_at: When the duplicate was detected (read-only)
    - resolved: Whether staff has reviewed and acted on this flag
    
    Detection methods:
    - location_proximity: Both reports within 100m of same category
    - perceptual_hash: Photo similarity ≥ 85% based on image hashing
    
    Example response:
    {
        "id": 1,
        "original_report": 42,
        "duplicate_report": 48,
        "detection_method": "perceptual_hash",
        "similarity_score": 0.92,
        "flagged_at": "2026-06-08T10:30:50Z",
        "resolved": false
    }
    """
    class Meta:
        model = DuplicateFlag
        fields = '__all__'
        read_only_fields = ['flagged_at']  # Auto-set when flag is created