"""Audit Middleware - Automatic logging of all data modifications."""
import logging
import re
from .models import AuditLog

logger = logging.getLogger('audit')

class AuditLogMiddleware:
    """Middleware that automatically logs all create/update/delete operations.
    
    Captures:
    - User performing the action
    - Type of action (create, update, delete)
    - Model affected (extracted from URL path)
    - Record ID (if available in URL)
    - Request source (IP, user agent)
    
    This ensures full compliance audit trail with minimal developer effort.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
        # Map HTTP methods to audit actions
        self.method_action_map = {
            'POST': 'create',
            'PUT': 'update',
            'PATCH': 'update',
            'DELETE': 'delete',
        }

    def __call__(self, request):
        """Process request, call view, then log any modifications."""
        response = self.get_response(request)
        
        # Only log modifications by authenticated users
        if request.user.is_authenticated and request.method in self.method_action_map:
            self._log_action(request)
        
        return response
    
    def _log_action(self, request):
        """Extract details from request and create audit log entry.
        
        URL patterns are like /api/reports/123/ - we extract:
        - Model name from URL path
        - Record ID from URL if available
        """
        try:
            # Extract table/model name from URL path
            # Examples: /api/reports/123/ -> 'reports', /api/users/ -> 'users'
            path_parts = request.path.strip('/').split('/')
            table_name = path_parts[1] if len(path_parts) > 1 else 'unknown'
            
            # Extract record ID if present in URL
            # /api/reports/123/ -> record_id = 123
            record_id = 0
            if len(path_parts) > 2 and path_parts[2].isdigit():
                record_id = int(path_parts[2])
            
            # Create immutable audit log entry
            AuditLog.objects.create(
                user=request.user,
                action=self.method_action_map[request.method],
                table_name=table_name,  # e.g., 'reports', 'users'
                record_id=record_id,  # e.g., 123
                ip_address=self._get_client_ip(request),
                user_agent=request.META.get('HTTP_USER_AGENT', '')
            )
            
            # Log successful audit entry
            logger.info(
                f"Audit: {request.user.email} {self.method_action_map[request.method].upper()} "
                f"{table_name}/{record_id} from {self._get_client_ip(request)}"
            )
        except Exception as e:
            # Log errors but don't crash the application
            logger.error(f"Failed to create audit log: {str(e)}", exc_info=True)
    
    def _get_client_ip(self, request):
        """Extract client IP, handling proxies correctly."""
        # Check for IP behind proxy (common in production)
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            # X-Forwarded-For can be comma-separated; take the first (client) IP
            ip = x_forwarded_for.split(',')[0].strip()
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip