import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/reports_provider.dart';
import '../../data/models/report_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../features/auth/domain/auth_provider.dart';
import '../../../../core/services/permission_service.dart';
import 'package:geolocator/geolocator.dart';


const List<String> _categories = [
  'roads',
  'water',
  'bridges',
  'streetlights',
  'public_facilities',
  'safety',
  'other',
];

const List<String> _categoryLabels = [
  'Roads',
  'Water',
  'Bridges',
  'Streetlights',
  'Public Facilities',
  'Safety / Crime',
  'Other',
];

class SubmitReportScreen extends ConsumerStatefulWidget {
  const SubmitReportScreen({super.key});

  @override
  ConsumerState<SubmitReportScreen> createState() =>
      _SubmitReportScreenState();
}

class _SubmitReportScreenState extends ConsumerState<SubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String _urgency = 'medium';
  double? _latitude;
  double? _longitude;
  bool _fetchingLocation = false;
  String? _locationLabel;
  XFile? _selectedImage;
  bool _isPickingImage = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;

    // Request permissions first
    final granted = await PermissionService.requestCameraPermissions(context);
    if (!granted || !mounted) return;

    setState(() => _isPickingImage = true);

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.teal),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Open camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppColors.teal),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select existing photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchLocation() async {
    final granted =
        await PermissionService.requestLocationPermission(context);
    if (!granted || !mounted) return;

    setState(() => _fetchingLocation = true);

    try {
      // Simulated coordinates for now
      // Replace with: final position = await Geolocator.getCurrentPosition();

// Real GPS call:
final position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
);
if (mounted) {
  setState(() {
    _latitude = position.latitude;
    _longitude = position.longitude;
    _locationLabel = 'GPS captured (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
    _fetchingLocation = false;
  });
}
    } catch (e) {
      if (mounted) {
        setState(() => _fetchingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) {
      _showValidationError('Please select a category');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showValidationError('Please add a description');
      return;
    }

    if (_selectedImage == null) {
      _showValidationError('Please upload a photo');
      return;
    }

    final user = ref.read(authProvider).user;
    final request = SubmitReportRequest(
      category: _selectedCategory!,
      description: _descriptionController.text.trim(),
      county: user?.county ?? 'Nairobi',
      urgency: _urgency,
      latitude: _latitude,
      longitude: _longitude,
      photo: _selectedImage,
    );

    await ref.read(submitReportProvider.notifier).submit(request);

    if (!mounted) return;
    final state = ref.read(submitReportProvider);
    if (state.isSuccess) {
      context.pushReplacement(
        AppRoutes.confirmation,
        extra: state.submittedReport,
      );
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } 

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(submitReportProvider);

    ref.listen<SubmitReportState>(submitReportProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
                top: 56, bottom: 30, left: 24, right: 24),
            decoration: const BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Icon(Icons.arrow_back,
                      color: AppColors.white),
                ),
                const SizedBox(width: 16),
                const Text(
                  'New Report',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo picker
                    GestureDetector(
                      onTap: _isPickingImage ? null : _showImageSourceDialog,
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.tealLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.teal.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: kIsWeb
                                    ? Image.network(
                                        _selectedImage!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_selectedImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _isPickingImage
                                      ? const CircularProgressIndicator(
                                          color: AppColors.teal,
                                          strokeWidth: 2,
                                        )
                                      : Icon(
                                          Icons.camera_alt_outlined,
                                          size: 36,
                                          color:
                                              AppColors.teal.withOpacity(0.7),
                                        ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tap to add photo',
                                    style: TextStyle(
                                      color: AppColors.teal,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Text(
                                    'Camera or Gallery',
                                    style: TextStyle(
                                        color: AppColors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category
                    _sectionLabel('Category'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      hint: const Text('Select category'),
                      decoration: const InputDecoration(),
                      items: List.generate(_categories.length, (i) {
                        return DropdownMenuItem(
                          value: _categories[i],
                          child: Text(_categoryLabels[i]),
                        );
                      }),
                      onChanged: (v) =>
                          setState(() => _selectedCategory = v),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _sectionLabel('Description'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Please describe the issue'
                              : null,
                      decoration: const InputDecoration(
                        hintText: 'Describe the issue in detail...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location
                    _sectionLabel('Location'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.warmWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.grey.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: AppColors.teal, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _locationLabel ?? 'Location not captured',
                              style: TextStyle(
                                color: _locationLabel != null
                                    ? AppColors.dark
                                    : AppColors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _fetchingLocation
                                ? null
                                : _fetchLocation,
                            child: _fetchingLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.teal,
                                    ),
                                  )
                                : Text(
                                    _locationLabel != null
                                        ? 'Refresh'
                                        : 'Fetch GPS',
                                    style: const TextStyle(
                                      color: AppColors.teal,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Urgency
                    _sectionLabel('Urgency Level'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _urgencyButton('low', 'Low', AppColors.green,
                            AppColors.greenLight),
                        const SizedBox(width: 8),
                        _urgencyButton('medium', 'Medium',
                            AppColors.amber, AppColors.amberLight),
                        const SizedBox(width: 8),
                        _urgencyButton('high', 'High', AppColors.red,
                            AppColors.redLight),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            submitState.isLoading ? null : _submit,
                        child: submitState.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Submit Report'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _urgencyButton(
      String value, String label, Color color, Color bg) {
    final isSelected = _urgency == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _urgency = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.lightBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.grey,
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.dark,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}