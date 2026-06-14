"""
Permission Classes - Role-based access control for API endpoints.

Defines 6 permission classes that check user roles:
- IsCitizen: Only citizens can perform action
- IsCountyOfficer: Only county officers can perform action
- IsPoliceOfficer: Only police officers can perform action
- IsAdmin: Only admins can perform action
- IsAdminOrCountyOfficer: Either admins or county officers
- IsOfficer: Any officer type (admin, county, or police)

Used as `permission_classes = [PermissionClass()]` on API views.
"""
from rest_framework.permissions import BasePermission


class IsCitizen(BasePermission):
    """Only authenticated users with 'citizen' role."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'citizen'


class IsCountyOfficer(BasePermission):
    """Only authenticated users with 'county_officer' role."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'county_officer'


class IsPoliceOfficer(BasePermission):
    """Only authenticated users with 'police_officer' role."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'police_officer'


class IsAdmin(BasePermission):
    """Only authenticated users with 'admin' role."""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'admin'


class IsAdminOrCountyOfficer(BasePermission):
    """Users with 'admin' or 'county_officer' roles.
    
    Used for endpoints that admin and county officers manage:
    - Report assignment
    - Department management
    - Duplicate flag review
    """
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in ['admin', 'county_officer']


class IsOfficer(BasePermission):
    """Any officer type: admin, county officer, or police officer.
    
    Used for endpoints that any officer can access:
    - Update report status
    - View assigned reports
    - Create status history entries
    """
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in ['admin', 'county_officer', 'police_officer']