"""Department Views - API endpoints for managing government departments.

Departments are the organizations that handle reports:
- Public Works: handles roads, water, bridges, streetlights, public facilities
- Police: handles non-public-works issues (security, etc.)

Each department:
- Has geographic jurisdiction (county)
- Has contact information
- Can be active/inactive
"""
from rest_framework import generics
from .models import Department
from .serializers import DepartmentSerializer
from users.permissions import IsAdmin, IsAdminOrCountyOfficer
from django.core.cache import cache


class DepartmentListView(generics.ListCreateAPIView):
    """List all active departments or create a new department.
    
    GET /api/departments/: List all active departments
    - Accessible by: county officers, admins
    - Filtered to show only active departments
    - Used by reports view to auto-route to department
    
    POST /api/departments/: Create new department
    - Accessible by: admins only
    - Sets up new department for a county
    - Required before reports can be auto-routed
    """
    serializer_class = DepartmentSerializer

    def get_queryset(self):
        cached = cache.get('departments:active')
        if cached is not None:
            return cached
        result = list(Department.objects.filter(is_active=True))
        cache.set('departments:active', result, timeout=600)  # 10 minutes — rarely changes
        return result

    def get_permissions(self):
        if self.request.method == 'POST':
            return [IsAdmin()]
        return [IsAdminOrCountyOfficer()]

    def perform_create(self, serializer):
        serializer.save()
        cache.delete('departments:active')


class DepartmentDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Retrieve, update, or delete a specific department.
    
    GET /api/departments/{id}/: View department details
    - Accessible by: admins only
    - Returns: department info, contact phone, active status
    
    PATCH /api/departments/{id}/: Update department
    - Accessible by: admins only
    - Can change: name, type, contact_phone, is_active status
    
    DELETE /api/departments/{id}/: Delete department
    - Accessible by: admins only
    - WARNING: May affect report routing if reports reference this department
    """
    queryset = Department.objects.all()
    serializer_class = DepartmentSerializer
    permission_classes = [IsAdmin]  # Only admins can modify

    def perform_update(self, serializer):
        serializer.save()
        cache.delete('departments:active')

    def perform_destroy(self, instance):
        instance.delete()
        cache.delete('departments:active')