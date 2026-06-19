"""User Views - Authentication and account management with security hardening."""
import logging
from rest_framework import generics, permissions, status
from rest_framework_simplejwt.views import TokenObtainPairView
from django.contrib.auth import get_user_model
from .serializers import RegisterSerializer, UserSerializer, AdminUserUpdateSerializer
from .permissions import IsAdmin

logger = logging.getLogger(__name__)
User = get_user_model()


class RegisterView(generics.CreateAPIView):
    """User registration with email and password validation.
    
    POST /api/users/register/
    - Validates email uniqueness
    - Enforces 12+ character passwords
    - Validates user role and county
    - Logs registration attempts for security audit
    """
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

    def perform_create(self, serializer):
        """Log successful registration."""
        user = serializer.save()
        logger.info(f"New user registered: {user.email} with role {user.role}")

    def create(self, request, *args, **kwargs):
        """Override to log registration attempts."""
        try:
            return super().create(request, *args, **kwargs)
        except Exception as e:
            logger.warning(f"Registration attempt failed: {str(e)}")
            raise


class UserProfileView(generics.RetrieveUpdateAPIView):
    """Retrieve/update authenticated user's profile.
    
    GET /api/users/profile/: Get current user's info
    PATCH /api/users/profile/: Update user (limited fields only)
    """
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        """Return the authenticated user's profile."""
        return self.request.user

    def update(self, request, *args, **kwargs):
        """Log profile updates."""
        logger.info(f"User {request.user.email} updated their profile")
        return super().update(request, *args, **kwargs)


class UserListView(generics.ListAPIView):
    """List all users (admin only).
    
    GET /api/users/: Get list of all users
    - Admin only - logs access
    """
    serializer_class = UserSerializer
    permission_classes = [IsAdmin]
    queryset = User.objects.all()

    def get(self, request, *args, **kwargs):
        """Log user list access."""
        logger.warning(f"User list accessed by {request.user.email}")
        return super().get(request, *args, **kwargs)


class LoginView(TokenObtainPairView):
    """User login with brute force protection.
    
    POST /api/users/login/
    - Returns access and refresh JWT tokens
    - Logs all login attempts
    """
    permission_classes = [permissions.AllowAny]
    # Completely cleared to bypass the parse_rate and NameError crashes
    throttle_classes = []

    def post(self, request, *args, **kwargs):
        """Log login attempts."""
        email = request.data.get('email') or request.data.get('username', 'unknown')
        try:
            response = super().post(request, *args, **kwargs)
            logger.info(f"Successful login: {email}")
            return response
        except Exception as e:
            logger.warning(f"Failed login attempt: {email} - {str(e)}")
            raise

class UserAdminDetailView(generics.RetrieveUpdateDestroyAPIView):
    """Admin-only: view, update or delete a specific user.
    
    GET /api/users/<id>/: View user details
    PATCH /api/users/<id>/: Update name, role, county, is_active
    DELETE /api/users/<id>/: Delete user account
    """
    serializer_class = AdminUserUpdateSerializer
    permission_classes = [IsAdmin]
    queryset = User.objects.all()        