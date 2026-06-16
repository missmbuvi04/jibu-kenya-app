from django.db.models.signals import post_save
from django.dispatch import receiver
from reports.models import ReportStatus
from .models import Notification


STATUS_MESSAGES = {
    'assigned': {
        'title': 'Report Assigned',
        'template': 'Your report {ref} has been assigned to {department}.',
    },
    'in_progress': {
        'title': 'Status Updated',
        'template': 'Your report {ref} is now In Progress.',
    },
    'resolved': {
        'title': 'Report Resolved',
        'template': 'Your report {ref} has been marked Resolved.',
    },
    'closed': {
        'title': 'Report Closed',
        'template': 'Your report {ref} has been closed.',
    },
}


@receiver(post_save, sender=ReportStatus)
def create_notification_on_status_change(sender, instance, created, **kwargs):
    """Whenever a ReportStatus entry is created, notify the citizen
    who owns the report about the status change."""
    if not created:
        return

    report = instance.report
    status = instance.status

    config = STATUS_MESSAGES.get(status)
    if not config:
        return

    ref = f'#JK-{report.created_at.year}-{report.id:06d}'
    department_name = (
        report.assigned_department.name
        if report.assigned_department
        else 'the relevant department'
    )

    message = config['template'].format(ref=ref, department=department_name)

    Notification.objects.create(
        user=report.citizen,
        report=report,
        title=config['title'],
        message=message,
        notification_type=status,
    )