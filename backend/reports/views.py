"""Report Views - API endpoints for managing citizen infrastructure reports."""
import logging
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from django.contrib.gis.geos import Point
from django.contrib.gis.measure import D
import imagehash
from PIL import Image
from .models import Report, ReportStatus, DuplicateFlag
from .serializers import ReportSerializer, ReportStatusSerializer, DuplicateFlagSerializer
from departments.models import Department
from users.permissions import IsCitizen, IsOfficer, IsAdminOrCountyOfficer
from rest_framework.permissions import IsAuthenticated


logger = logging.getLogger(__name__)


def auto_route_report(report):
    """Automatically assign report to the appropriate department.
    
    Logic:
    - Infrastructure issues (roads, water, bridges, etc.) -> Public Works
    - Other issues -> Police
    - Finds nearest active department in the same county
    - Updates report status from 'submitted' to 'assigned'
    
    Args:
        report: Report instance to route
    """
    # Determine which department type handles this category
    if report.category in ['roads', 'water', 'bridges', 'streetlights', 'public_facilities']:
        dept_type = 'public_works'
    else:
        dept_type = 'police'

    # Find an active department of the correct type in the same county
    department = Department.objects.filter(
        type=dept_type,
        county=report.county,
        is_active=True
    ).first()

    # Assign and update status if department found
    if department:
        report.assigned_department = department
        report.status = 'assigned'
        report.save()
        logger.info(f"Report {report.id} auto-routed to department {department.id}")
    else:
        logger.warning(f"No {dept_type} department found for county {report.county}. Report {report.id} remains unassigned.")


def check_duplicate(new_report):
    """Detect and flag duplicate reports using location and image analysis.
    
    Two-phase duplicate detection:
    1. LOCATION PROXIMITY: Find reports within 100m of same category in same county
    2. IMAGE HASHING: Compare photo perceptual hashes for 85%+ similarity
    
    Does not auto-merge duplicates - flags them for staff review to maintain data integrity.
    
    Args:
        new_report: Newly created Report instance to check
    """
    
    # PHASE 1: Location-based duplicate detection
    # Works even without photos - useful for reporting clusters
    if new_report.location:
        try:
            # Find similar reports: same category, same county, within 100m
            nearby_reports = Report.objects.filter(
                category=new_report.category,
                county=new_report.county,
                location__distance_lte=(new_report.location, D(m=100))
            ).exclude(id=new_report.id)

            for report in nearby_reports:
                # Prevent creating duplicate flags for the same pair
                already_flagged = DuplicateFlag.objects.filter(
                    original_report=report,
                    duplicate_report=new_report
                ).exists()

                if not already_flagged:
                    DuplicateFlag.objects.create(
                        original_report=report,
                        duplicate_report=new_report,
                        detection_method='location_proximity',
                        similarity_score=1.0,  # Perfect match for same location
                        resolved=False
                    )
                    logger.info(f"Duplicate flag: {new_report.id} near {report.id}")
        except Exception as e:
            logger.error(f"Location proximity check error for report {new_report.id}: {str(e)}", exc_info=True)

    # PHASE 2: Perceptual image hashing for visual duplicate detection
    # Only runs if a photo was uploaded
    if not new_report.photo_reference:
        return

    try:
        # Generate perceptual hash of the photo
        # pHash is robust to common image modifications (scaling, rotation, compression)
        new_hash = imagehash.phash(Image.open(new_report.photo_reference.path))
        new_report.photo_hash = str(new_hash)
        new_report.save()
        logger.info(f"Computed perceptual hash for report {new_report.id}")

        # Compare against all other reports in the county that have photos
        existing_reports = Report.objects.filter(
            county=new_report.county
        ).exclude(id=new_report.id).exclude(photo_hash=None)

        for report in existing_reports:
            if report.photo_hash:
                # Calculate similarity between hashes
                existing_hash = imagehash.hex_to_hash(report.photo_hash)
                diff = new_hash - existing_hash  # Hamming distance
                # Convert distance to similarity: 0 diff = 1.0 (100%), 64 diff = 0.0 (0%)
                similarity = 1 - (diff / 64.0)

                # Flag if very similar (85% threshold to avoid false positives)
                if similarity >= 0.85:
                    already_flagged = DuplicateFlag.objects.filter(
                        original_report=report,
                        duplicate_report=new_report
                    ).exists()

                    if not already_flagged:
                        DuplicateFlag.objects.create(
                            original_report=report,
                            duplicate_report=new_report,
                            detection_method='perceptual_hash',
                            similarity_score=round(similarity, 4),
                            resolved=False
                        )
                        logger.warning(f"Duplicate photos detected: {new_report.id} vs {report.id} ({similarity:.1%})")
    except Exception as e:
        logger.error(f"Image hash check error for report {new_report.id}: {str(e)}", exc_info=True)


class ReportListCreateView(generics.ListCreateAPIView):
    """List/create infrastructure reports with role-based filtering.
    
    GET /api/reports/: List reports visible to user
    - Citizens: Only see their own reports
    - County officers & admins: See all reports in their county
    - Police officers: See police-type reports in their county
    
    POST /api/reports/: Submit new report (citizens only)
    - Auto-routes to appropriate department
    - Detects and flags potential duplicates
    """
    serializer_class = ReportSerializer

    def get_permissions(self):
        """Different permissions for GET vs POST."""
        if self.request.method == 'POST':
            return [IsCitizen()]  # Only citizens can submit
        return [permissions.IsAuthenticated()]  # Any authenticated user — queryset filters by role

    def get_queryset(self):
        """Return reports based on user role and county.
        
        Uses role-based filtering to ensure users only see appropriate reports.
        """
        user = self.request.user
        if user.role == 'citizen':
            # Citizens only see their own submissions
            return Report.objects.filter(citizen=user)
        elif user.role in ['county_officer', 'admin']:
            # Officers/admins see all reports in their county
            return Report.objects.filter(county=user.county)
        elif user.role == 'police_officer':
            # Police see only police-type reports in their county
            return Report.objects.filter(
                assigned_department__type='police',
                assigned_department__county=user.county
            )
        return Report.objects.none()

    def perform_create(self, serializer):
        status_update = serializer.save(updated_by=self.request.user)
        report = status_update.report
        report.status = status_update.status
        report.save(update_fields=['status', 'updated_at'])
        logger.info(f"Report {report.id} status changed to {status_update.status} by {self.request.user.email}")

class ReportDetailView(generics.RetrieveUpdateAPIView):
    """Retrieve and update individual report.

    GET /api/reports/{id}/: View report details
    - Citizens see their own reports
    - Officers see reports in their county
    
    PATCH /api/reports/{id}/: Update report (officers/admins only)
    - Typically used to change status or assignment
    """
    serializer_class = ReportSerializer
    queryset = Report.objects.all()

    def get_permissions(self):
        """Only officers/admins can modify; authenticated users can view."""
        if self.request.method in ['PUT', 'PATCH']:
            return [IsAdminOrCountyOfficer()]
        return [permissions.IsAuthenticated()]


class ReportStatusUpdateView(generics.CreateAPIView):
    """Create status change entry for a report.
    
    POST /api/reports/status/: Record status change with notes
    - Only officers can change status
    - Creates audit trail entry
    - Preserves workflow history
    """
    serializer_class = ReportStatusSerializer
    permission_classes = [IsOfficer]

    def perform_create(self, serializer):
        """Save status change and record who made the change."""
        status_update = serializer.save(updated_by=self.request.user)
        logger.info(f"Report {status_update.report.id} status changed to {status_update.status} by {self.request.user.email}")


class DuplicateFlagListView(generics.ListAPIView):
    """List flagged duplicate reports for staff review.
    
    GET /api/reports/duplicates/: See all flagged duplicates
    - Officers/admins can review and merge/dismiss duplicates
    - Shows similarity score and detection method
    - Only shows unresolved flags
    """
    serializer_class = DuplicateFlagSerializer
    permission_classes = [IsAdminOrCountyOfficer]
    queryset = DuplicateFlag.objects.filter(resolved=False)  # Only show unresolved flags