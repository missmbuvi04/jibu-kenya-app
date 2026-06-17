"""Report Models - Core application models for citizen-submitted infrastructure reports."""
from django.contrib.gis.db import models
from django.conf import settings

class Report(models.Model):
    """Main Report model for storing citizen-submitted infrastructure issues.
    
    Citizens submit reports about issues like roads, water, bridges, etc. with photos
    and location data. Reports are automatically routed to appropriate departments,
    checked for duplicates, and tracked through status workflows.
    """
    CATEGORY_CHOICES = [
        ('roads', 'Roads'),
        ('water', 'Water'),
        ('bridges', 'Bridges'),
        ('streetlights', 'Streetlights'),
        ('public_facilities', 'Public Facilities'),
        ('safety', 'Safety/crime'),
        ('other', 'Other'),
    ]

    STATUS_CHOICES = [
        ('submitted', 'Submitted'),
        ('assigned', 'Assigned'),
        ('in_progress', 'In Progress'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
    ]

    citizen = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reports'
    )
    assigned_department = models.ForeignKey(
        'departments.Department',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reports'
    )
    # Issue categorization
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    description = models.TextField()
    
    # Geographic data with spatial indexing for efficient proximity queries
    location = models.PointField(geography=True, null=True, blank=True, db_index=True)
    
    # Photo upload and perceptual hashing for duplicate detection
    photo_reference = models.ImageField(upload_to='reports/', null=True, blank=True)
    photo_hash = models.CharField(max_length=255, null=True, blank=True)
    
    # Workflow status tracking
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='submitted')
    
    # County reference for geographic organization and officer filtering
    county = models.CharField(max_length=100)
    
    # Timestamps for audit trail
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.category} - {self.status} ({self.county})"
    
    class Meta:
        """Database optimizations for Report queries."""
        indexes = [
            models.Index(fields=['county', 'status']),  # Common filter combination
            models.Index(fields=['citizen', 'created_at']),  # User report history
        ]


class ReportStatus(models.Model):
    """Audit trail for report status transitions.
    
    Tracks every status change to a report, who made the change, when, and with notes.
    Enables full workflow history and accountability.
    """
    STATUS_CHOICES = [
        ('submitted', 'Submitted'),
        ('assigned', 'Assigned'),
        ('in_progress', 'In Progress'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
    ]

    report = models.ForeignKey(
        Report,
        on_delete=models.CASCADE,
        related_name='status_history'
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES)
    updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='status_updates'
    )
    timestamp = models.DateTimeField(auto_now_add=True)
    notes = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"{self.report} - {self.status}"
class DuplicateFlag(models.Model):
    """Tracks suspected duplicate reports detected automatically.
    
    When a new report is submitted, it's checked against existing reports using:
    1. Geographic proximity (100m radius, same category)
    2. Perceptual image hashing (85%+ similarity with photos)
    
    Allows staff to merge/dismiss duplicates to reduce clutter and improve data quality.
    """
    original_report = models.ForeignKey(
        Report,
        on_delete=models.CASCADE,
        related_name='original_flags',
        help_text="The original/earlier report"
    )
    duplicate_report = models.ForeignKey(
        Report,
        on_delete=models.CASCADE,
        related_name='duplicate_flags',
        help_text="The suspected duplicate/newer report"
    )
    # Detection method: 'location_proximity' or 'perceptual_hash'
    detection_method = models.CharField(max_length=100)
    # Similarity score: 0.0-1.0 for image hashing, always 1.0 for location
    similarity_score = models.FloatField()
    flagged_at = models.DateTimeField(auto_now_add=True)
    # Whether staff has reviewed and resolved this flag
    resolved = models.BooleanField(default=False)

    def __str__(self):
        return f"Duplicate: {self.duplicate_report} of {self.original_report}"