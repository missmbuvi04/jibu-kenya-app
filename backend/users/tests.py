"""
User Authentication Tests — Jibu Kenya
Covers: registration validation, login, and role-based access control
"""
from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from django.contrib.auth import get_user_model

User = get_user_model()


class RegistrationUnitTests(TestCase):
    """Unit tests for the user registration endpoint."""

    def setUp(self):
        self.client = APIClient()
        self.url = '/api/users/register/'

    def test_valid_registration_creates_account(self):
        """A valid registration payload creates a new citizen account."""
        data = {
            'name': 'Wanjiku Kamau',
            'email': 'wanjiku@jibutest.com',
            'password': 'SecurePass123!',
            'password_confirm': 'SecurePass123!',
            'role': 'citizen',
            'county': 'Nairobi'
        }
        response = self.client.post(self.url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(User.objects.filter(email='wanjiku@jibutest.com').exists())

    def test_registration_rejects_duplicate_email(self):
        """Registration fails when the email is already in use."""
        User.objects.create_user(
            email='taken@jibutest.com',
            password='SecurePass123!',
            name='Existing User',
            county='Nairobi',
            role='citizen'
        )
        data = {
            'name': 'New User',
            'email': 'taken@jibutest.com',
            'password': 'SecurePass123!',
            'password_confirm': 'SecurePass123!',
            'role': 'citizen',
            'county': 'Nairobi'
        }
        response = self.client.post(self.url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_registration_rejects_weak_password(self):
        """Registration fails when the password is less than 12 characters."""
        data = {
            'name': 'Test User',
            'email': 'weak@jibutest.com',
            'password': 'short',
            'password_confirm': 'short',
            'role': 'citizen',
            'county': 'Nairobi'
        }
        response = self.client.post(self.url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class LoginUnitTests(TestCase):
    """Unit tests for the JWT login endpoint."""

    def setUp(self):
        self.client = APIClient()
        self.url = '/api/users/login/'
        self.user = User.objects.create_user(
            email='otieno@jibutest.com',
            password='SecurePass123!',
            name='Otieno Odhiambo',
            county='Nairobi',
            role='citizen'
        )

    def test_valid_login_returns_jwt_tokens(self):
        """Valid credentials return both access and refresh JWT tokens."""
        data = {'email': 'otieno@jibutest.com', 'password': 'SecurePass123!'}
        response = self.client.post(self.url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)

    def test_wrong_password_returns_401(self):
        """Incorrect password returns HTTP 401 Unauthorized."""
        data = {'email': 'otieno@jibutest.com', 'password': 'wrongpassword'}
        response = self.client.post(self.url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_unauthenticated_request_to_reports_is_blocked(self):
        """Requests without a token cannot access the reports endpoint."""
        response = self.client.get('/api/reports/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class RoleBasedAccessIntegrationTests(TestCase):
    """Integration tests verifying role-based access control across endpoints."""

    def setUp(self):
        self.client = APIClient()
        self.citizen = User.objects.create_user(
            email='citizen@jibutest.com',
            password='SecurePass123!',
            name='Amina Hassan',
            county='Nairobi',
            role='citizen'
        )
        self.admin = User.objects.create_user(
            email='admin@jibutest.com',
            password='SecurePass123!',
            name='System Admin',
            county='Nairobi',
            role='admin',
            is_staff=True
        )

    def test_admin_can_access_user_list(self):
        """Administrators can retrieve the full list of system users."""
        self.client.force_authenticate(user=self.admin)
        response = self.client.get('/api/users/all/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_citizen_is_forbidden_from_user_list(self):
        """Citizens are blocked from accessing the admin-only user list."""
        self.client.force_authenticate(user=self.citizen)
        response = self.client.get('/api/users/all/')
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)