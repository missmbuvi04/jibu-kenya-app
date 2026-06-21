"""
Report Tests — Jibu Kenya
Covers: automatic routing logic, report submission, and status update access control
"""
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model
from reports.models import Report
from reports.views import auto_route_report
from departments.models import Department

User = get_user_model()


class ReportRoutingUnitTests(TestCase):
    """Unit tests for the automatic category-based department routing logic."""

    def setUp(self):
        self.citizen = User.objects.create_user(
            email='citizen@jibutest.com',
            password='SecurePass123!',
            name='Njeri Waweru',
            county='Nairobi',
            role='citizen'
        )
        self.police_dept = Department.objects.create(
            name='Nairobi Central Police Station',
            type='police',
            county='Nairobi',
            is_active=True
        )
        self.public_works_dept = Department.objects.create(
            name='Nairobi County Public Works',
            type='public_works',
            county='Nairobi',
            is_active=True
        )

    def test_safety_report_routes_to_police_department(self):
        """Safety/crime reports are automatically routed to the police department."""
        report = Report.objects.create(
            citizen=self.citizen,
            category='safety',
            description='Robbery reported near Kencom bus stage',
            county='Nairobi',
            status='submitted'
        )
        auto_route_report(report)
        report.refresh_from_db()
        self.assertEqual(report.assigned_department, self.police_dept)
        self.assertEqual(report.status, 'assigned')

    def test_road_report_routes_to_public_works_department(self):
        """Roads category reports are automatically routed to public works."""
        report = Report.objects.create(
            citizen=self.citizen,
            category='roads',
            description='Large pothole on Uhuru Highway causing accidents',
            county='Nairobi',
            status='submitted'
        )
        auto_route_report(report)
        report.refresh_from_db()
        self.assertEqual(report.assigned_department, self.public_works_dept)
        self.assertEqual(report.status, 'assigned')


class ReportSubmissionIntegrationTests(TestCase):
    """Integration tests for the report submission API endpoint."""

    def setUp(self):
        self.client = APIClient()
        self.citizen = User.objects.create_user(
            email='citizen@jibutest.com',
            password='SecurePass123!',
            name='Kamau Mwangi',
            county='Nairobi',
            role='citizen'
        )
        self.officer = User.objects.create_user(
            email='officer@jibutest.com',
            password='SecurePass123!',
            name='Officer Kipchoge',
            county='Nairobi',
            role='county_officer'
        )

    def test_citizen_can_submit_report(self):
        """Authenticated citizen successfully submits an infrastructure report."""
        self.client.force_authenticate(user=self.citizen)
        data = {
            'category': 'roads',
            'description': 'Deep pothole on Tom Mboya Street near Archives roundabout causing traffic accidents',
            'county': 'Nairobi',
            'latitude': -1.2921,
            'longitude': 36.8219,
        }
        response = self.client.post('/api/reports/', data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Report.objects.count(), 1)

    def test_officer_cannot_submit_report(self):
        """County officers are blocked from submitting reports — citizens only."""
        self.client.force_authenticate(user=self.officer)
        data = {
            'category': 'water',
            'description': 'Burst pipe on Moi Avenue',
            'county': 'Nairobi',
        }
        response = self.client.post('/api/reports/', data, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_citizen_only_sees_their_own_reports(self):
        """Citizens cannot see reports submitted by other citizens."""
        other_citizen = User.objects.create_user(
            email='other@jibutest.com',
            password='SecurePass123!',
            name='Other Citizen',
            county='Nairobi',
            role='citizen'
        )
        Report.objects.create(
            citizen=other_citizen,
            category='water',
            description='Burst pipe — belongs to another citizen',
            county='Nairobi'
        )
        self.client.force_authenticate(user=self.citizen)
        response = self.client.get('/api/reports/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 0)


class ReportStatusIntegrationTests(TestCase):
    """Integration tests for officer status update access control."""

    def setUp(self):
        self.client = APIClient()
        self.citizen = User.objects.create_user(
            email='citizen@jibutest.com',
            password='SecurePass123!',
            name='Aisha Mohamed',
            county='Nairobi',
            role='citizen'
        )
        self.officer = User.objects.create_user(
            email='officer@jibutest.com',
            password='SecurePass123!',
            name='Officer Omondi',
            county='Nairobi',
            role='county_officer'
        )
        self.report = Report.objects.create(
            citizen=self.citizen,
            category='bridges',
            description='Bridge on Ngong Road showing structural cracks',
            county='Nairobi',
            status='submitted'
        )

    def test_officer_can_update_report_status(self):
        """County officer can successfully update a report status to In Progress."""
        self.client.force_authenticate(user=self.officer)
        data = {
            'report': self.report.id,
            'status': 'in_progress',
            'notes': 'Structural team dispatched to assess bridge condition'
        }
        response = self.client.post('/api/reports/status/', data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_citizen_cannot_update_report_status(self):
        """Citizens are blocked from updating report statuses — officers only."""
        self.client.force_authenticate(user=self.citizen)
        data = {
            'report': self.report.id,
            'status': 'resolved',
            'notes': 'Attempting to close my own report'
        }
        response = self.client.post('/api/reports/status/', data, format='json')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)