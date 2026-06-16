"""Django Admin Configuration - View audit logs (read-only).

Allows administrators to view the complete audit trail of all system modifications
for compliance, security investigations, and debugging purposes.

Audit logs are IMMUTABLE - they cannot be edited or deleted, only viewed.
This ensures the integrity of the compliance record.

Accessible at /admin/ for users with is_staff=True
"""
from django.contrib import admin
from .models import AuditLog


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    """View immutable audit trail of all system modifications.
    
    Shows who changed what, when they changed it, and where they were
    for compliance audits and security investigations.
    """
    # Columns shown in list view (newest first)
    list_display = ('user', 'action', 'table_name', 'record_id', 'ip_address', 'timestamp')
    
    # Add filters for quick navigation
    list_filter = ('action', 'timestamp', 'table_name')
    
    # Searchable fields
    search_fields = ('user__email', 'ip_address', 'table_name')
    
    # Sort by timestamp, newest first
    ordering = ('-timestamp',)
    
    # ALL FIELDS READ-ONLY - This is an immutable audit trail
    readonly_fields = ('user', 'action', 'table_name', 'record_id', 
                       'timestamp', 'ip_address', 'user_agent')
    
    # Prevent users from adding/deleting audit records
    def has_add_permission(self, request):
        """Audit logs are auto-generated, cannot be manually created."""
        return False
    
    def has_delete_permission(self, request, obj=None):
        """Audit logs are immutable, cannot be deleted."""
        return False
    
    def has_change_permission(self, request, obj=None):
        """Audit logs are immutable, cannot be modified."""
        return False