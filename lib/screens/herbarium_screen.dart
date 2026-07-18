import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../database/database_helper.dart';
import '../models/plant_catalog_model.dart';
import '../services/sync_service.dart';
import 'plant_detail_screen.dart';

/// ──────────────────────────────────────────────
/// HerbariumScreen — Browsable catalog of all
/// plants identified by the current user, with
/// grid/list toggle, pull-to-refresh, and details.
/// ──────────────────────────────────────────────
class HerbariumScreen extends StatefulWidget {
  const HerbariumScreen({super.key});

  @override
  State<HerbariumScreen> createState() => _HerbariumScreenState();
}

class _HerbariumScreenState extends State<HerbariumScreen> {
  List<PlantCatalogModel> _plants = [];
  bool _isLoading = true;
  bool _isGridView = true;
  String? _errorMessage;

  bool _wasSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadPlants();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncService>().addListener(_onSyncChanged);
    });
  }

  @override
  void dispose() {
    context.read<SyncService>().removeListener(_onSyncChanged);
    super.dispose();
  }

  void _onSyncChanged() {
    if (!mounted) return;
    final isSyncing = context.read<SyncService>().isSyncing;
    if (_wasSyncing && !isSyncing) {
      _loadPlants();
    }
    _wasSyncing = isSyncing;
  }

  Future<void> _loadPlants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final userId = authService.currentUser?.id;
      if (userId == null) {
        setState(() {
          _errorMessage = 'Please log in to view your herbarium.';
          _isLoading = false;
        });
        return;
      }

      final plants = await DatabaseHelper.instance.getUserPlantRecords(userId);
      setState(() {
        _plants = plants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load plants: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePlant(PlantCatalogModel plant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Record'),
        content: Text(
          'Remove "${plant.commonName}" from your herbarium?\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && plant.id != null) {
      await DatabaseHelper.instance.deletePlantRecord(plant.id!);
      _loadPlants();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${plant.commonName} removed'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showDetailSheet(PlantCatalogModel plant) {
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => PlantDetailScreen(plant: plant)));
  }

  Color _confidenceColor(double score) {
    if (score >= 0.8) return AppColors.safe;
    if (score >= 0.5) return AppColors.caution;
    return AppColors.danger;
  }

  String _confidenceLabel(double score) {
    if (score >= 0.8) return 'High';
    if (score >= 0.5) return 'Medium';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Herbarium'),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                key: ValueKey(_isGridView),
              ),
            ),
            tooltip: _isGridView ? 'Switch to list' : 'Switch to grid',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    if (_plants.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadPlants,
      child: _isGridView ? _buildGridView() : _buildListView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decorative botanical illustration area
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.accent.withValues(alpha: 0.12),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_florist_rounded,
                  size: 80,
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.8, 0.8), duration: 600.ms, curve: Curves.easeOut),
              const SizedBox(height: 32),
              Text(
                'No plants identified yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
              const SizedBox(height: 12),
              Text(
                'Start scanning plants around you to build\nyour personal botanical collection!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ).animate().fadeIn(delay: 350.ms, duration: 500.ms),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/scan'),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Start Scanning'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 500.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: _plants.length,
      itemBuilder: (context, index) {
        final plant = _plants[index];
        return _GridPlantCard(
          plant: plant,
          confidenceColor: _confidenceColor(plant.confidenceScore),
          confidenceLabel: _confidenceLabel(plant.confidenceScore),
          onTap: () => _showDetailSheet(plant),
          onLongPress: () => _deletePlant(plant),
        )
            .animate()
            .fadeIn(delay: (50 * index).ms, duration: 400.ms)
            .slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOut);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _plants.length,
      itemBuilder: (context, index) {
        final plant = _plants[index];
        return Dismissible(
          key: ValueKey(plant.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 28),
          ),
          confirmDismiss: (_) async {
            await _deletePlant(plant);
            return false; // handled manually via _deletePlant
          },
          child: _ListPlantCard(
            plant: plant,
            confidenceColor: _confidenceColor(plant.confidenceScore),
            confidenceLabel: _confidenceLabel(plant.confidenceScore),
            onTap: () => _showDetailSheet(plant),
            onLongPress: () => _deletePlant(plant),
          )
              .animate()
              .fadeIn(delay: (50 * index).ms, duration: 400.ms)
              .slideX(begin: 0.05, duration: 400.ms, curve: Curves.easeOut),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
// Grid Card Widget
// ═══════════════════════════════════════════════
class _GridPlantCard extends StatelessWidget {
  final PlantCatalogModel plant;
  final Color confidenceColor;
  final String confidenceLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _GridPlantCard({
    required this.plant,
    required this.confidenceColor,
    required this.confidenceLabel,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork = plant.imagePath.startsWith('http');
    final imageFile = isNetwork ? null : File(plant.imagePath);
    final hasImage = isNetwork || (imageFile != null && imageFile.existsSync());
    final dateStr = DateFormat('MMM d, yyyy').format(plant.timestamp);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasImage
                      ? Hero(
                          tag: 'plant_image_${plant.id}',
                          child: isNetwork
                              ? CachedNetworkImage(imageUrl: plant.imagePath, fit: BoxFit.cover)
                              : Image.file(imageFile!, fit: BoxFit.cover),
                        )
                      : Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(
                            Icons.eco_rounded,
                            size: 48,
                            color: AppColors.textHint,
                          ),
                        ),
                  // Badge
                  if (plant.verificationStatus == 'pending')
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.caution.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PENDING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: confidenceColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(plant.confidenceScore * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  // Sync indicator
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Icon(
                      plant.isSynced == 1
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_off_rounded,
                      size: 18,
                      color: plant.isSynced == 1
                          ? AppColors.synced
                          : AppColors.unsynced,
                    ),
                  ),
                ],
              ),
            ),
            // Info section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.commonName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plant.scientificName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// List Card Widget
// ═══════════════════════════════════════════════
class _ListPlantCard extends StatelessWidget {
  final PlantCatalogModel plant;
  final Color confidenceColor;
  final String confidenceLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ListPlantCard({
    required this.plant,
    required this.confidenceColor,
    required this.confidenceLabel,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork = plant.imagePath.startsWith('http');
    final imageFile = isNetwork ? null : File(plant.imagePath);
    final hasImage = isNetwork || (imageFile != null && imageFile.existsSync());
    final dateStr = DateFormat('MMM d, yyyy · h:mm a').format(plant.timestamp);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: hasImage
                      ? Hero(
                          tag: 'plant_image_${plant.id}',
                          child: isNetwork
                              ? CachedNetworkImage(imageUrl: plant.imagePath, fit: BoxFit.cover)
                              : Image.file(imageFile!, fit: BoxFit.cover),
                        )
                      : Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.eco_rounded, color: AppColors.textHint),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.commonName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plant.scientificName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Confidence chip
                        if (plant.verificationStatus == 'pending')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.caution.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'PENDING',
                              style: TextStyle(
                                color: AppColors.caution,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: confidenceColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$confidenceLabel · ${(plant.confidenceScore * 100).toInt()}%',
                              style: TextStyle(
                                color: confidenceColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Sync icon
              Icon(
                plant.isSynced == 1
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_off_rounded,
                size: 20,
                color: plant.isSynced == 1 ? AppColors.synced : AppColors.unsynced,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showPlantDetailSheet(BuildContext context, PlantCatalogModel plant) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PlantDetailSheet(plant: plant),
  );
}

// ═══════════════════════════════════════════════
// Detail Bottom Sheet
// ═══════════════════════════════════════════════
class _PlantDetailSheet extends StatelessWidget {
  final PlantCatalogModel plant;

  const _PlantDetailSheet({required this.plant});

  @override
  Widget build(BuildContext context) {
    final isNetwork = plant.imagePath.startsWith('http');
    final imageFile = isNetwork ? null : File(plant.imagePath);
    final hasImage = isNetwork || (imageFile != null && imageFile.existsSync());
    final dateStr = DateFormat('EEEE, MMMM d, yyyy · h:mm a').format(plant.timestamp);

    Color confidenceColor;
    if (plant.confidenceScore >= 0.8) {
      confidenceColor = AppColors.safe;
    } else if (plant.confidenceScore >= 0.5) {
      confidenceColor = AppColors.caution;
    } else {
      confidenceColor = AppColors.danger;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Hero image
              if (hasImage)
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  child: Container(
                    height: 260,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: isNetwork
                        ? CachedNetworkImage(imageUrl: plant.imagePath, fit: BoxFit.cover, width: double.infinity)
                        : Image.file(imageFile!, fit: BoxFit.cover, width: double.infinity),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.95, 0.95), duration: 400.ms),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                    const SizedBox(height: 4),
                    Text(
                      plant.scientificName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                    if (plant.family != null && plant.family!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Family: ${plant.family}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w600,
                            ),
                      ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                    ],

                    if (plant.edibilityStatus != null && plant.edibilityStatus!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: plant.edibilityStatus == 'edible'
                              ? AppColors.safe
                              : plant.edibilityStatus == 'toxic'
                                  ? AppColors.danger
                                  : AppColors.caution,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              plant.edibilityStatus == 'edible'
                                  ? Icons.restaurant_rounded
                                  : plant.edibilityStatus == 'toxic'
                                      ? Icons.dangerous_rounded
                                      : Icons.warning_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              plant.edibilityStatus!.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 180.ms, duration: 400.ms),
                    ],

                    if (plant.localName != null && plant.localName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Local: ${plant.localName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Confidence & Sync Row
                    Row(
                      children: [
                        _DetailChip(
                          icon: Icons.analytics_rounded,
                          label: 'Confidence',
                          value: '${(plant.confidenceScore * 100).toInt()}%',
                          color: confidenceColor,
                        ),
                        const SizedBox(width: 12),
                        _DetailChip(
                          icon: plant.isSynced == 1
                              ? Icons.cloud_done_rounded
                              : Icons.cloud_off_rounded,
                          label: 'Sync',
                          value: plant.isSynced == 1 ? 'Synced' : 'Pending',
                          color: plant.isSynced == 1
                              ? AppColors.synced
                              : AppColors.unsynced,
                        ),
                      ],
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                    const SizedBox(height: 8),
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                    ),

                    if (plant.latitude != null && plant.longitude != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '📍 ${plant.latitude!.toStringAsFixed(4)}, ${plant.longitude!.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                      ),
                    ],

                    // XAI Reasoning
                    const SizedBox(height: 24),
                    _SectionCard(
                      icon: Icons.psychology_rounded,
                      title: 'AI Reasoning',
                      content: plant.xaiReasoning,
                      accentColor: AppColors.info,
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.05),

                    // Safety
                    if (plant.safetyWarnings != null && plant.safetyWarnings!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _SectionCard(
                        icon: Icons.warning_amber_rounded,
                        title: 'Safety Warnings',
                        content: plant.safetyWarnings!,
                        accentColor: AppColors.caution,
                      ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.05),
                    ],

                    // Preparation
                    if (plant.preparationMethods != null &&
                        plant.preparationMethods!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _SectionCard(
                        icon: Icons.restaurant_rounded,
                        title: 'Preparation',
                        content: plant.preparationMethods!,
                        accentColor: AppColors.safe,
                      ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.05),
                    ],

                    // Habitat
                    if (plant.habitat != null && plant.habitat!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _SectionCard(
                        icon: Icons.landscape_rounded,
                        title: 'Habitat',
                        content: plant.habitat!,
                        accentColor: AppColors.primary,
                      ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(begin: 0.05),
                    ],

                    // Nutritional Highlights
                    if (plant.nutritionalHighlights != null && plant.nutritionalHighlights!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _SectionCard(
                        icon: Icons.eco_rounded,
                        title: 'Nutritional Highlights',
                        content: plant.nutritionalHighlights!,
                        accentColor: AppColors.safe,
                      ).animate().fadeIn(delay: 700.ms, duration: 400.ms).slideY(begin: 0.05),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color accentColor;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accentColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}
