from django.urls import path
from .views import ReportListCreateView, ReportDetailView, ReportStatusUpdateView, DuplicateFlagListView
from .views import cloudinary_signature
# add to urlpatterns:
urlpatterns = [
    path('', ReportListCreateView.as_view(), name='report-list'),
    path('<int:pk>/', ReportDetailView.as_view(), name='report-detail'),
    path('status/', ReportStatusUpdateView.as_view(), name='report-status'),
    path('duplicates/', DuplicateFlagListView.as_view(), name='duplicate-list'),
    path('cloudinary-signature/', cloudinary_signature, name='cloudinary-signature'),
]