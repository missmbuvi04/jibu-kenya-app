import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();

  /// Request camera + storage permissions before opening camera or gallery.
  /// Returns true if all required permissions are granted.
  static Future<bool> requestCameraPermissions(BuildContext context) async {
    final statuses = await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
    ].request();

    final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final photosGranted = statuses[Permission.photos]?.isGranted ?? false;
    final storageGranted = statuses[Permission.storage]?.isGranted ?? false;

    // On Android 13+ photos permission replaces storage
    final storageOk = photosGranted || storageGranted;

    if (!cameraGranted || !storageOk) {
      if (context.mounted) {
        final openSettings = await _showDeniedDialog(
          context,
          title: 'Camera & Storage Access Required',
          message:
              'Jibu Kenya needs camera access to photograph infrastructure '
              'issues and storage access to attach photos from your gallery. '
              'Please enable these in Settings.',
        );
        if (openSettings) await openAppSettings();
      }
      return false;
    }

    return true;
  }

  /// Request GPS location permissions before fetching coordinates.
  /// Returns true if at least coarse location is granted.
  static Future<bool> requestLocationPermission(BuildContext context) async {
    // First request coarse location — Android requires this before fine
    final coarse = await Permission.locationWhenInUse.request();

    if (coarse.isGranted) {
      // Try to upgrade to fine location
      await Permission.location.request();
      return true;
    }

    if (coarse.isPermanentlyDenied) {
      if (context.mounted) {
        final openSettings = await _showDeniedDialog(
          context,
          title: 'Location Access Required',
          message:
              'Jibu Kenya needs your GPS location to accurately tag where '
              'infrastructure issues are occurring. Please enable location '
              'access in Settings.',
        );
        if (openSettings) await openAppSettings();
      }
      return false;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission denied. GPS coordinates will not be captured.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return false;
  }

  /// Check if camera permission is already granted without prompting
  static Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  /// Check if location permission is already granted without prompting
  static Future<bool> hasLocationPermission() async {
    return await Permission.locationWhenInUse.isGranted ||
        await Permission.location.isGranted;
  }

  /// Show a dialog explaining why a permission was denied
  /// Returns true if user tapped "Open Settings"
  static Future<bool> _showDeniedDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}