from rest_framework import serializers
from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    # Field names match Flutter's NotificationModel.fromJson exactly
    report_id = serializers.IntegerField(source='report.id', read_only=True, default=None)
    report_reference = serializers.SerializerMethodField()
    type = serializers.CharField(source='notification_type')

    class Meta:
        model = Notification
        fields = [
            'id',
            'title',
            'message',
            'type',
            'report_id',
            'report_reference',
            'is_read',
            'created_at',
        ]
        read_only_fields = fields

    def get_report_reference(self, obj):
        if obj.report:
            return f'#JK-{obj.report.created_at.year}-{obj.report.id:06d}'
        return None


class MarkReadSerializer(serializers.Serializer):
    is_read = serializers.BooleanField()