"""Audit Models - Compliance and accountability logging."""
from django.db import models
from django.conf import settings
import logging

logger = logging.getLogger('audit')

class AuditLog(models.Model):
    """Immutable audit trail for compliance and accountability.
    
    Automatically captures all data modifications (create, update, delete) with:
    - Who performed the action (user)
    - What action was performed (create/update/delete)
    - What record was affected (table name + ID)
    - When it happened (timestamp)
    - Where it came from (IP address, user agent)
    
    Used for compliance audits, debugging, and security investigations.
    """
    ACTION_CHOICES = [
        ('create', 'Create'),
        ('read', 'Read'),
        ('update', 'Update'),
        ('delete', 'Delete'),
    ]

    # Who took the action (null if user was deleted)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='audit_logs'
    )
    # Type of data operation
    action = models.CharField(max_length=10, choices=ACTION_CHOICES)
    # Which model/table was affected
    table_name = models.CharField(max_length=100)
    # ID of the specific record modified
    record_id = models.IntegerField()
    # When the action occurred (auto-set, immutable)
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)
    # Request source for security analysis
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(null=True, blank=True)

    class Meta:
        """Audit logs are immutable - prevent accidental modification."""
        # Index on timestamp for efficient log queries
        indexes = [
            models.Index(fields=['-timestamp']),  # Most recent logs first
            models.Index(fields=['user', 'timestamp']),  # User activity timeline
        ]
    
    def __str__(self):
        return f"{self.user} - {self.action} on {self.table_name} ({self.timestamp})"