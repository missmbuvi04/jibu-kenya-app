"""User Models - Custom user authentication with role-based access control."""
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models

class UserManager(BaseUserManager):
    """Custom manager for email-based user authentication.
    
    Replaces Django's default username-based auth with email-based login.
    """
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('Email is required')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', 'admin')
        return self.create_user(email, password, **extra_fields)

class User(AbstractBaseUser, PermissionsMixin):
    """Custom user model with role-based authorization.
    
    Four user types:
    - citizen: Public users submitting infrastructure issues
    - county_officer: Local officials managing reports in their county
    - police_officer: Law enforcement (for non-public-works issues)
    - admin: System administrators with full access
    """
    ROLE_CHOICES = [
        ('citizen', 'Citizen'),
        ('county_officer', 'County Officer'),
        ('police_officer', 'Police Officer'),
        ('admin', 'Admin'),
    ]

    # User identity
    name = models.CharField(max_length=255)
    email = models.EmailField(unique=True, help_text="Used for authentication")
    
    # Authorization and organization
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='citizen',
                           help_text="Determines API permissions and data access")
    county = models.CharField(max_length=100, help_text="Geographic jurisdiction for officers")
    
    # Account status
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False, help_text="Access to admin panel")
    created_at = models.DateTimeField(auto_now_add=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['name']

    objects = UserManager()

    def __str__(self):
        return f"{self.name} ({self.role})"