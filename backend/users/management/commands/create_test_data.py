"""
Django management command to create test data for all user roles and departments.

Creates:
- 1 Citizen user
- 1 County Officer user
- 1 Police Officer user
- 2 Test Departments (Public Works, Police)

Allows testing of all features without manual data entry.
Usage: python manage.py create_test_data
"""

from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from departments.models import Department

User = get_user_model()


class Command(BaseCommand):
    """Management command to seed test data."""
    
    help = 'Create test users for all roles and test departments'

    def handle(self, *args, **options):
        """Execute command to create test data."""
        self.stdout.write('Creating test data...\n')
        
        # Create test departments
        self._create_departments()
        
        # Create test users
        self._create_users()
        
        self.stdout.write(self.style.SUCCESS('✅ Test data created successfully!\n'))
        self.stdout.write(self.style.WARNING('\nTest Credentials:\n'))
        self.stdout.write('━' * 50)
        self.print_test_credentials()

    def _create_departments(self):
        """Create test departments."""
        departments_data = [
            {
                'name': 'Nairobi Public Works',
                'type': 'public_works',
                'county': 'Nairobi',
                'contact_phone': '+254700123456',
            },
            {
                'name': 'Nairobi Police',
                'type': 'police',
                'county': 'Nairobi',
                'contact_phone': '+254700654321',
            },
            {
                'name': 'Nakuru Public Works',
                'type': 'public_works',
                'county': 'Nakuru',
                'contact_phone': '+254700789123',
            },
        ]

        for dept_data in departments_data:
            dept, created = Department.objects.get_or_create(
                name=dept_data['name'],
                county=dept_data['county'],
                defaults=dept_data
            )
            if created:
                self.stdout.write(f"  ✓ Created department: {dept.name}")
            else:
                self.stdout.write(f"  - Department exists: {dept.name}")

    def _create_users(self):
        """Create test users for each role."""
        test_users = [
            {
                'email': 'citizen@test.com',
                'password': 'TestCitizen@123',
                'name': 'John Citizen',
                'role': 'citizen',
                'county': 'Nairobi',
            },
            {
                'email': 'officer@test.com',
                'password': 'TestOfficer@123',
                'name': 'Jane County Officer',
                'role': 'county_officer',
                'county': 'Nairobi',
            },
            {
                'email': 'police@test.com',
                'password': 'TestPolice@123',
                'name': 'Bob Police Officer',
                'role': 'police_officer',
                'county': 'Nairobi',
            },
        ]

        for user_data in test_users:
            email = user_data['email']
            if not User.objects.filter(email=email).exists():
                User.objects.create_user(**user_data)
                self.stdout.write(f"  ✓ Created {user_data['role']}: {email}")
            else:
                self.stdout.write(f"  - User exists: {email}")

    def print_test_credentials(self):
        """Print test credentials in a nice format."""
        credentials = [
            ('Citizen', 'citizen@test.com', 'TestCitizen@123'),
            ('County Officer', 'officer@test.com', 'TestOfficer@123'),
            ('Police Officer', 'police@test.com', 'TestPolice@123'),
        ]
        
        for role, email, password in credentials:
            self.stdout.write(f"\n{role}:")
            self.stdout.write(f"  Email:    {email}")
            self.stdout.write(f"  Password: {password}")

        self.stdout.write('\n' + '━' * 50)
        self.stdout.write('\nNext steps:')
        self.stdout.write('  1. Start server: python manage.py runserver')
        self.stdout.write('  2. Login at: http://localhost:8000/api/users/login/')
        self.stdout.write('  3. View API docs: http://localhost:8000/api/docs/')
