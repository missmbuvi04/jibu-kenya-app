"""Django Admin Configuration - Manage infrastructure reports and duplicates.

Allows system administrators to view, edit, and manage:
- Reports submitted by citizens
- Status change history
- Detected duplicate flags

Accessible at /admin/ for users with is_staff=True
"""
from django.contrib import admin
from .models import Report, ReportStatus, DuplicateFlag


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    """Manage citizen-submitted infrastructure reports.
    
    Displays reports with key information and allows filtering/searching
    for quick investigation and status updates.
    """
    # Columns shown in list view
    list_display = ('id', 'category', 'status', 'county', 'citizen', 'created_at')
    
    # Add filters for quick navigation
    list_filter = ('category', 'status', 'county', 'created_at')
    
    # Make these fields searchable
    search_fields = ('citizen__email', 'county', 'description')
    
    # Organization into sections
    fieldsets = (
        ('Report Details', {
            'fields': ('citizen', 'category', 'description'),
        }),
        ('Location & Media', {
            'fields': ('location', 'photo_reference', 'photo_hash'),
        }),
        ('Routing & Status', {
            'fields': ('assigned_department', 'status', 'county'),
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )
    
    # Prevent accidental changes to these fields
    readonly_fields = ('created_at', 'updated_at', 'photo_hash')


@admin.register(ReportStatus)
class ReportStatusAdmin(admin.ModelAdmin):
    """View status change history for reports.
    
    Shows the audit trail of all status changes - who changed it, when, and notes.
    Useful for understanding workflow and debugging.
    """
    # Columns shown in list view
    list_display = ('report', 'status', 'updated_by', 'timestamp')
    
    # Add filters
    list_filter = ('status', 'timestamp')
    
    # Searchable fields
    search_fields = ('report__id', 'updated_by__email')
    
    # Prevent modification of audit trail
    readonly_fields = ('report', 'status', 'updated_by', 'timestamp', 'notes')


@admin.register(DuplicateFlag)
class DuplicateFlagAdmin(admin.ModelAdmin):
    """Manage suspected duplicate reports.
    
    Shows automatically-detected duplicates with similarity scores.
    Admins can review and resolve flags by merging or dismissing.
    """
    # Columns shown in list view
    list_display = ('original_report', 'duplicate_report', 'detection_method', 
                    'similarity_score', 'resolved', 'flagged_at')
    
    # Add filters
    list_filter = ('detection_method', 'resolved', 'flagged_at')
    
    # Searchable by report ID
    search_fields = ('original_report__id', 'duplicate_report__id')
    
    # Organize form
    fieldsets = (
        ('Duplicate Detection', {
            'fields': ('original_report', 'duplicate_report'),
        }),
        ('Analysis', {
            'fields': ('detection_method', 'similarity_score'),
        }),
        ('Status', {
            'fields': ('resolved',),
            'description': 'Mark as resolved after merging or dismissing'
        }),
        ('Timestamp', {
            'fields': ('flagged_at',),
            'classes': ('collapse',),
        }),
    )
    
    # Prevent modification of detection data
    readonly_fields = ('original_report', 'duplicate_report', 'detection_method', 
                       'similarity_score', 'flagged_at')