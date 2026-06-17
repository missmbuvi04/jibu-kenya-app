"""Department Serializers - Convert department model to/from JSON.

Handles serialization of Department objects for API responses and input validation.
"""
from rest_framework import serializers
from .models import Department


class DepartmentSerializer(serializers.ModelSerializer):
    """Serialize Department model to JSON.
    
    Fields:
    - id: Auto-generated database ID
    - name: Department name (e.g., "Nairobi Public Works")
    - type: 'public_works' or 'police'
    - county: Geographic jurisdiction (e.g., "Nairobi")
    - contact_phone: Department phone number
    - is_active: Whether department is currently accepting reports
    
    Example response:
    {
        "id": 1,
        "name": "Nairobi Public Works",
        "type": "public_works",
        "county": "Nairobi",
        "contact_phone": "+254700123456",
        "is_active": true
    }
    """
    class Meta:
        model = Department
        fields = '__all__'