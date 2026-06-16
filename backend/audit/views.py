"""Audit Views - Compliance and accountability log viewing.

The audit log tracks all data modifications for compliance audits:
- Who made the change (user email)
- What they changed (table/model name, record ID)
- When they changed it (timestamp)
- Where they were (IP address, user agent)

Immutable: Audit logs cannot be edited or deleted, only viewed.
"""
from rest_framework import generics
from .models import AuditLog
from .serializers import AuditLogSerializer
from users.permissions import IsAdmin


class AuditLogListView(generics.ListAPIView):
    """List all audit logs - most recent first.
    
    GET /api/audit/: Retrieve audit trail
    - Accessible by: admins only
    - Returns: all audit events sorted by timestamp (newest first)
    - Includes: user email, action, table name, record ID, IP, user agent
    
    Use cases:
    - Compliance audits (show who changed what)
    - Security investigations (detect unauthorized access)
    - Debugging (track when changes occurred)
    
    Example response:
    {
        "user": "officer@county.gov",
        "action": "update",
        "table_name": "reports",
        "record_id": 123,
        "timestamp": "2026-06-08T10:30:45Z",
        "ip_address": "192.168.1.100",
        "user_agent": "Mozilla/5.0..."
    }
    """
    serializer_class = AuditLogSerializer
    permission_classes = [IsAdmin]  # Only admins can view audit logs

    def get_queryset(self):
        """Return audit logs newest first."""
        return AuditLog.objects.all().order_by('-timestamp')