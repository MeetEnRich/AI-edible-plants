import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'full_map_screen.dart';
import '../theme/app_theme.dart';
import '../models/plant_catalog_model.dart';

class PlantDetailScreen extends StatelessWidget {
  final PlantCatalogModel plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    final isNetwork = plant.imagePath.startsWith('http');
    final imageFile = isNetwork ? null : File(plant.imagePath);
    final hasImage = isNetwork || (imageFile != null && imageFile.existsSync());

    Color confidenceColor;
    if (plant.confidenceScore >= 0.8) {
      confidenceColor = AppColors.safe;
    } else if (plant.confidenceScore >= 0.5) {
      confidenceColor = AppColors.caution;
    } else {
      confidenceColor = AppColors.danger;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: hasImage
                  ? Hero(
                      tag: 'plant_image_${plant.id}',
                      child: isNetwork
                          ? CachedNetworkImage(imageUrl: plant.imagePath, fit: BoxFit.cover)
                          : Image.file(imageFile!, fit: BoxFit.cover),
                    )
                  : Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.local_florist_rounded, size: 80, color: AppColors.textHint),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (plant.verificationStatus == 'pending')
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded, color: AppColors.danger, size: 28),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'NOT VERIFIED. DO NOT CONSUME. Waiting for internet connection.',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms),

                  // Names
                  Text(
                    plant.commonName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                  const SizedBox(height: 4),
                  Text(
                    plant.scientificName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                  if (plant.family != null && plant.family!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Family: ${plant.family}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w600,
                          ),
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                  ],

                  const SizedBox(height: 24),

                  // Metadata Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetaCard(
                          icon: Icons.analytics_outlined,
                          title: 'AI Confidence',
                          value: '${(plant.confidenceScore * 100).toInt()}%',
                          color: confidenceColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetaCard(
                          icon: Icons.calendar_today_rounded,
                          title: 'Date Logged',
                          value: DateFormat('MMM d, yyyy').format(plant.timestamp),
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: 32),

                  // Safety & Reasoning
                  _buildSection(
                    context,
                    title: 'Edibility Status',
                    icon: Icons.restaurant_rounded,
                    content: (plant.edibilityStatus ?? 'UNKNOWN').toUpperCase(),
                    contentColor: (plant.edibilityStatus ?? '').toLowerCase().contains('toxic') ? AppColors.danger : AppColors.safe,
                    delay: 250,
                  ),
                  _buildSection(
                    context,
                    title: 'AI Reasoning',
                    icon: Icons.psychology_rounded,
                    content: plant.xaiReasoning,
                    delay: 300,
                  ),
                  if (plant.safetyWarnings != null && plant.safetyWarnings!.isNotEmpty)
                    _buildSection(
                      context,
                      title: 'Safety Warnings',
                      icon: Icons.warning_amber_rounded,
                      content: plant.safetyWarnings!,
                      contentColor: AppColors.danger,
                      delay: 350,
                    ),
                  if (plant.preparationMethods != null && plant.preparationMethods!.isNotEmpty)
                    _buildSection(
                      context,
                      title: 'Preparation Notes',
                      icon: Icons.soup_kitchen_rounded,
                      content: plant.preparationMethods!,
                      delay: 400,
                    ),
                  if (plant.habitat != null && plant.habitat!.isNotEmpty)
                    _buildSection(
                      context,
                      title: 'Habitat',
                      icon: Icons.landscape_rounded,
                      content: plant.habitat!,
                      delay: 450,
                    ),

                  if (plant.latitude != null && plant.longitude != null)
                    _buildMapSection(context, plant.latitude!, plant.longitude!),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {
    required String title,
    required IconData icon,
    required String content,
    Color contentColor = AppColors.textPrimary,
    required int delay,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: contentColor,
              height: 1.6,
            ),
          ),
        ],
      ).animate().fadeIn(delay: delay.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, delay: delay.ms),
    );
  }

  Widget _buildMapSection(BuildContext context, double lat, double lng) {
    final position = LatLng(lat, lng);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Location Found', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => FullMapScreen(
                    latitude: lat,
                    longitude: lng,
                    title: 'Plant Location',
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: position,
                          initialZoom: 15.0,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.flora_id',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: position,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: AppColors.danger,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final text = '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
              await Clipboard.setData(ClipboardData(text: text));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Coordinates copied to clipboard!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: Row(
              children: [
                Text(
                  'GPS Coordinates: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.copy_rounded, size: 14, color: AppColors.textHint),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, delay: 500.ms),
    );
  }
}
