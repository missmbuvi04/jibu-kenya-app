"""Django Admin Configuration - Manage government departments.

Allows administrators to:
- Create and edit departments (Public Works, Police)
- Set up geographic jurisdictions (counties)
- Control which departments are active and accepting reports
- Update contact information

Accessible at /admin/ for users with is_staff=True
"""
from django.contrib import admin
from .models import Department


@admin.register(Department)
class DepartmentAdmin(admin.ModelAdmin):
    """Manage departments that handle report routing.
    
    Displays department information and allows enabling/disabling
    for quick control over which departments receive new reports.
    """
    # Columns shown in list view
    list_display = ('name', 'type', 'county', 'is_active', 'contact_phone')
    
    # Add filters for quick navigation
    list_filter = ('type', 'is_active', 'county')
    
    # Make these fields searchable
    search_fields = ('name', 'county', 'contact_phone')
    
    # Organize form into sections
    fieldsets = (
        ('Department Information', {
            'fields': ('name', 'type', 'county'),
        }),
        ('Contact', {
            'fields': ('contact_phone',),
        }),
        ('Status', {
            'fields': ('is_active',),
            'description': 'Uncheck to prevent new reports being routed to this department'
        }),
    )