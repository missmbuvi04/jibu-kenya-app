from django.db import models

class Department(models.Model):
    TYPE_CHOICES = [
        ('public_works', 'Public Works'),
        ('police', 'Police'),
    ]

    name = models.CharField(max_length=255)
    type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    county = models.CharField(max_length=100)
    contact_phone = models.CharField(max_length=20, blank=True, null=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.name} - {self.county}"