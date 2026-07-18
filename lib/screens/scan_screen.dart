import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../services/gemini_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../database/database_helper.dart';
import '../models/plant_catalog_model.dart';

/// ──────────────────────────────────────────────
/// ScanScreen — Capture or select a plant image,
/// optionally tag with GPS, and send to Gemini
/// for AI-powered identification.
/// ──────────────────────────────────────────────
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();

  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _gpsEnabled = false;
  Position? _currentPosition;

  // ── Image Selection ───────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Plant Image',
              toolbarColor: AppColors.primary,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              activeControlsWidgetColor: AppColors.accent,
            ),
            IOSUiSettings(
              title: 'Crop Plant Image',
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _selectedImage = File(croppedFile.path);
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ── GPS Location ──────────────────────────────

  Future<void> _captureLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location services are disabled. Please enable them in settings.'),
            backgroundColor: AppColors.caution,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        await Geolocator.openLocationSettings();
        setState(() => _gpsEnabled = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission denied.'),
              backgroundColor: AppColors.caution,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          setState(() => _gpsEnabled = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permissions are permanently denied.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() => _gpsEnabled = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() => _currentPosition = position);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() => _gpsEnabled = false);
    }
  }

  // ── Plant Identification ──────────────────────

  Future<void> _identifyPlant() async {
    if (_selectedImage == null) return;

    // Capture GPS if enabled
    if (_gpsEnabled && _currentPosition == null) {
      await _captureLocation();
    }

    final authService = context.read<AuthService>();
    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult.any((r) => r != ConnectivityResult.none);

    if (!isOnline) {
      // Offline Mode: Save to Pending Queue
      final user = authService.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in first.')),
        );
        return;
      }

      final pendingRecord = PlantCatalogModel(
        userId: user.id,
        scientificName: 'Unknown Species',
        commonName: 'Pending Identification',
        confidenceScore: 0.0,
        imagePath: _selectedImage!.path,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        xaiReasoning: 'Waiting for internet connection to verify safety and identity. DO NOT CONSUME.',
        timestamp: DateTime.now(),
        verificationStatus: 'pending',
      );

      await DatabaseHelper.instance.insertPlantRecord(pendingRecord);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.cloud_off_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Offline. Saved to queue for verification.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.caution,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context);
      return;
    }

    // Check API key first
    final hasKey = await _geminiService.hasApiKey();
    if (!hasKey) {
      if (!mounted) return;
      _showApiKeyDialog();
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final result = await _geminiService.identifyPlant(_selectedImage!);

      if (!mounted) return;

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Identification failed. Please try again with a clearer image.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      Navigator.pushNamed(
        context,
        '/result',
        arguments: {
          'result': result,
          'imagePath': _selectedImage!.path,
          'latitude': _currentPosition?.latitude,
          'longitude': _currentPosition?.longitude,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.key_rounded, color: AppColors.accent, size: 40),
        title: const Text('API Key Required'),
        content: const Text(
          'A Gemini API key is needed to identify plants. '
          'Please go to Settings to configure your API key.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/settings');
            },
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan Plant'),
        actions: [
          // GPS toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _gpsEnabled ? Icons.location_on_rounded : Icons.location_off_rounded,
                  color: _gpsEnabled ? AppColors.accent : AppColors.textOnPrimary.withValues(alpha: 0.5),
                  size: 20,
                ),
                const SizedBox(width: 4),
                Switch(
                  value: _gpsEnabled,
                  onChanged: (value) {
                    setState(() => _gpsEnabled = value);
                    if (value) _captureLocation();
                    if (!value) _currentPosition = null;
                  },
                  activeThumbColor: AppColors.accent,
                  activeTrackColor: AppColors.accentDark.withValues(alpha: 0.4),
                  inactiveThumbColor: AppColors.textOnPrimary.withValues(alpha: 0.6),
                  inactiveTrackColor: AppColors.textOnPrimary.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                // ── Image Preview Area ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildImagePreview(),
                  ),
                ),

                // ── GPS Indicator ──
                if (_gpsEnabled && _currentPosition != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.safe.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.safe.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.my_location_rounded, size: 16, color: AppColors.safe),
                          const SizedBox(width: 8),
                          Text(
                            '${_currentPosition!.latitude.toStringAsFixed(4)}, '
                            '${_currentPosition!.longitude.toStringAsFixed(4)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.safe,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                  ),

                const SizedBox(height: 16),

                // ── Action Buttons ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Camera Button
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.camera_alt_rounded,
                          label: 'Take Photo',
                          onTap: () => _pickImage(ImageSource.camera),
                          gradient: AppDecorations.primaryGradient,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Gallery Button
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.photo_library_rounded,
                          label: 'Choose from Gallery',
                          onTap: () => _pickImage(ImageSource.gallery),
                          gradient: AppDecorations.goldGradient,
                          textColor: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .slideY(begin: 0.3, end: 0, delay: 200.ms, duration: 500.ms),

                const SizedBox(height: 16),

                // ── Identify Button ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _selectedImage != null && !_isAnalyzing
                          ? _identifyPlant
                          : null,
                      icon: const Icon(Icons.search_rounded, size: 22),
                      label: const Text('Identify Plant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                        disabledForegroundColor: AppColors.textOnPrimary.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.3, end: 0, delay: 400.ms, duration: 500.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // ── Loading Overlay ──
          if (_isAnalyzing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _selectedImage != null
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.textHint.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _selectedImage != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                // Selected image
                Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
                // Gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                ),
                // Change image hint
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Tap below to change',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.0, 1.0),
                duration: 400.ms,
                curve: Curves.easeOut,
              )
          : // Placeholder
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_florist_rounded,
                    size: 48,
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.05, 1.05),
                      duration: 2000.ms,
                    ),
                const SizedBox(height: 20),
                Text(
                  'No plant image selected',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take a photo or choose from gallery\nto start identification',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textHint.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 1.5,
                      ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 600.ms),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated plant icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .rotate(duration: 3000.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.1, 1.1),
                    duration: 1500.ms,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.1, 1.1),
                    end: const Offset(0.9, 0.9),
                    duration: 1500.ms,
                    curve: Curves.easeInOut,
                  ),

              const SizedBox(height: 24),



              Text(
                'Analyzing plant...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                'Our AI is examining leaf shape,\ncolor, and texture patterns',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
              duration: 400.ms,
              curve: Curves.easeOutBack,
            ),
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms);
  }
}

/// ──────────────────────────────────────────────
/// _ActionButton — Reusable gradient action button
/// ──────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final LinearGradient gradient;
  final Color textColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.gradient,
    this.textColor = AppColors.textOnPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: textColor, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
