"""User Serializers - Input validation and sanitization for user endpoints."""
import re
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError

User = get_user_model()

class RegisterSerializer(serializers.ModelSerializer):
    """User registration with comprehensive input validation.
    
    Validates:
    - Email format and uniqueness
    - Password strength (12+ chars, complexity)
    - Name doesn't contain invalid characters
    - Role is one of the allowed choices
    """
    password = serializers.CharField(
        write_only=True,
        min_length=12,
        style={'input_type': 'password'},
        help_text='Password must be at least 12 characters with uppercase, lowercase, and numbers'
    )
    password_confirm = serializers.CharField(
        write_only=True,
        style={'input_type': 'password'},
        help_text='Must match password field'
    )

    class Meta:
        model = User
        fields = ['id', 'name', 'email', 'password', 'password_confirm', 'role', 'county']
        extra_kwargs = {
            'email': {'required': True},
            'name': {'required': True},
            'role': {'required': True},
            'county': {'required': True},
        }

    def validate_email(self, value):
        """Validate email format and uniqueness."""
        # Check if email already exists
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError(
                "This email is already registered. Please log in instead."
            )
        
        # Check email format with strict regex
        email_regex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_regex, value):
            raise serializers.ValidationError("Enter a valid email address.")
        
        return value.lower()  # Normalize to lowercase

    def validate_name(self, value):
        """Validate name - prevent XSS and injection."""
        # Remove leading/trailing whitespace
        value = value.strip()
        
        # Check length
        if len(value) < 2:
            raise serializers.ValidationError("Name must be at least 2 characters.")
        if len(value) > 255:
            raise serializers.ValidationError("Name must not exceed 255 characters.")
        
        # Allow only letters, numbers, spaces, and basic punctuation
        if not re.match(r"^[a-zA-Z0-9\s\-'.]*$", value):
            raise serializers.ValidationError(
                "Name can only contain letters, numbers, spaces, hyphens, and apostrophes."
            )
        
        return value

    def validate_role(self, value):
        """Validate role is one of allowed choices."""
        allowed_roles = ['citizen', 'county_officer', 'police_officer', 'admin']
        if value not in allowed_roles:
            raise serializers.ValidationError(
                f"Role must be one of: {', '.join(allowed_roles)}"
            )
        return value

    def validate_county(self, value):
        """Validate county field."""
        value = value.strip()
        if not value:
            raise serializers.ValidationError("County is required.")
        if len(value) > 100:
            raise serializers.ValidationError("County name too long.")
        return value

    def validate(self, data):
        """Validate password strength and confirmation."""
        password = data.get('password')
        password_confirm = data.get('password_confirm')
        
        # Check passwords match
        if password != password_confirm:
            raise serializers.ValidationError({
                'password': 'Password and password confirmation do not match.'
            })
        
        # Use Django's built-in password validators
        user = User(email=data['email'])
        try:
            validate_password(password, user=user)
        except ValidationError as e:
            raise serializers.ValidationError({'password': list(e.messages)})
        
        return data

    def create(self, validated_data):
        """Create user, removing confirmation field."""
        validated_data.pop('password_confirm', None)
        return User.objects.create_user(**validated_data)


class UserSerializer(serializers.ModelSerializer):
    """Read-only user profile serializer."""
    class Meta:
        model = User
        fields = ['id', 'name', 'email', 'role', 'county', 'is_active', 'created_at']
        read_only_fields = ['id', 'created_at', 'email', 'role']  # Email/role shouldn't change


class AdminUserUpdateSerializer(serializers.ModelSerializer):
    """Serializer for admin updating other users — allows role editing."""
    class Meta:
        model = User
        fields = ['name', 'role', 'county', 'is_active']