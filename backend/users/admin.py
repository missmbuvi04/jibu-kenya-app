"""Django Admin Configuration - Manage users and system data through admin panel.

Allows superusers to view and edit user accounts, permissions, and system configuration
through the Django admin interface at /admin/
"""
from django.contrib import admin
from .models import User


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    """Customize User admin panel for better usability.
    
    Displays important fields in admin list view and organizes edit form into sections.
    """
    # Columns shown in list view
    list_display = ('email', 'name', 'role', 'county', 'is_active', 'created_at')
    
    # Add filters to filter users by role or status
    list_filter = ('role', 'is_active', 'created_at')
    
    # Make these fields searchable
    search_fields = ('email', 'name', 'county')
    
    # Organize form into sections for easier editing
    fieldsets = (
        ('User Information', {
            'fields': ('email', 'name'),
        }),
        ('Authorization', {
            'fields': ('role', 'county', 'is_active', 'is_staff'),
            'description': 'Role determines what operations user can perform'
        }),
        ('Permissions', {
            'fields': ('groups', 'user_permissions'),
            'classes': ('collapse',),  # Hide by default
        }),
        ('Important Dates', {
            'fields': ('last_login', 'created_at'),
            'classes': ('collapse',),  # Hide by default
        }),
    )
    
    # Don't show password field in edit (use change password form instead)
    readonly_fields = ('last_login', 'created_at')