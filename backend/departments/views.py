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
    queryset = Department.objects.filter(is_active=True)
    serializer_class = DepartmentSerializer

    def get_permissions(self):
        """Different permissions for GET vs POST."""
        if self.request.method == 'POST':
            return [IsAdmin()]  # Only admins can create departments
        return [IsAdminOrCountyOfficer()]  # Officers can view


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