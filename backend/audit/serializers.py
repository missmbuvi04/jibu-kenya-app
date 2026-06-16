"""Audit Log Serializers - Convert audit log entries to JSON for API responses.

Handles serialization of immutable audit logs for compliance viewing and analysis.
"""
from rest_framework import serializers
from .models import AuditLog


class AuditLogSerializer(serializers.ModelSerializer):
    """Serialize AuditLog model to JSON for compliance viewing.
    
    Fields:
    - user: Email of user who performed the action
    - action: 'create', 'read', 'update', or 'delete'
    - table_name: Name of model/table that was modified
    - record_id: ID of the specific record affected
    - timestamp: When the action occurred (read-only, auto-set)
    - ip_address: IP address of request
    - user_agent: Browser/app user agent string
    
    All fields are read-only (immutable audit trail).
    
    Example response:
    {
        "id": 1,
        "user": "officer@county.gov",
        "action": "update",
        "table_name": "reports",
        "record_id": 42,
        "timestamp": "2026-06-08T10:30:45Z",
        "ip_address": "192.168.1.100",
        "user_agent": "Mozilla/5.0 (Mobile)"
    }
    """
    class Meta:
        model = AuditLog
        fields = '__all__'
        read_only_fields = ['timestamp']  # Timestamp is auto-set, cannot be modified