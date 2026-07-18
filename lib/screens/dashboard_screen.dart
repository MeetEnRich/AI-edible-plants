import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../database/database_helper.dart';
import '../models/plant_catalog_model.dart';
import 'plant_detail_screen.dart';

/// ──────────────────────────────────────────────
/// DashboardScreen — Main hub after login.
/// Shows welcome header, quick actions, and
/// recent plant identification scans.
/// ──────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _plantCount = 0;
  List<PlantCatalogModel> _recentScans = [];
  bool _isLoading = true;
  String? _error;

  bool _wasSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    // Add listener to reload data automatically when a background verification completes
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
    // If it just finished syncing, reload the UI
    if (_wasSyncing && !isSyncing) {
      _loadDashboardData();
    }
    _wasSyncing = isSyncing;
  }

  Future<void> _loadDashboardData() async {
    try {
      final auth = context.read<AuthService>();
      final userId = auth.currentUser?.id;
      if (userId == null) return;

      final db = DatabaseHelper.instance;
      final count = await db.getPlantCount(userId);
      final allRecords = await db.getUserPlantRecords(userId);

      if (!mounted) return;
      setState(() {
        _plantCount = count;
        _recentScans = allRecords.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final auth = context.read<AuthService>();
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  // ─── Confidence color helper ─────────────────
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

  // ═══════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final username = auth.currentUser?.username ?? 'Explorer';

    return Scaffold(
      appBar: AppBar(
        title: const Text('FloraID Nigeria'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadDashboardData,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24, top: 8),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildHeroHeader(username),
                      const SizedBox(height: 24),
                      _buildQuickActionsGrid(),
                      const SizedBox(height: 28),
                      _buildRecentScansSection(),
                    ],
                  ),
                ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ═══════════════════════════════════════════════
  // ERROR STATE
  // ═══════════════════════════════════════════════

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: AppColors.danger.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadDashboardData();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // HERO HEADER CARD
  // ═══════════════════════════════════════════════

  Widget _buildHeroHeader(String username) {
    final syncService = context.watch<SyncService>();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppDecorations.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome row ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome,',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      username,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // ── Avatar placeholder ──
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.glassWhite,
                  border: Border.all(color: AppColors.glassBorder, width: 2),
                ),
                child: const Icon(Icons.eco_rounded,
                    color: AppColors.accentLight, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Stats row ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: AppDecorations.glassCard,
            child: Row(
              children: [
                // Plant count
                const Icon(Icons.local_florist_rounded,
                    color: AppColors.accentLight, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$_plantCount',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 4),
                Text(
                  _plantCount == 1 ? 'plant identified' : 'plants identified',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                      ),
                ),
                const Spacer(),

                // Sync status
                _SyncStatusDot(isOnline: syncService.isOnline),
                const SizedBox(width: 6),
                Text(
                  syncService.isOnline ? 'Online' : 'Offline',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideY(begin: -0.05, end: 0, duration: 600.ms, curve: Curves.easeOut);
  }

  // ═══════════════════════════════════════════════
  // QUICK ACTIONS GRID
  // ═══════════════════════════════════════════════

  Widget _buildQuickActionsGrid() {
    final actions = [
      _QuickAction(
        icon: Icons.camera_alt_rounded,
        label: 'Identify\nPlant',
        gradient: AppDecorations.primaryGradient,
        onTap: () => Navigator.pushNamed(context, '/scan').then((_) => _loadDashboardData()),
      ),
      _QuickAction(
        icon: Icons.collections_bookmark_rounded,
        label: 'My\nHerbarium',
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.safe, AppColors.safe.withValues(alpha: 0.75)],
        ),
        onTap: () => Navigator.pushNamed(context, '/herbarium').then((_) => _loadDashboardData()),
      ),
      _QuickAction(
        icon: Icons.menu_book_rounded,
        label: 'Plant\nEncyclopedia',
        gradient: AppDecorations.goldGradient,
        onTap: () => Navigator.pushNamed(context, '/encyclopedia'),
      ),
      _QuickAction(
        icon: Icons.settings_rounded,
        label: 'Settings',
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.textSecondary,
            AppColors.textSecondary.withValues(alpha: 0.7),
          ],
        ),
        onTap: () => Navigator.pushNamed(context, '/settings'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.55,
            children: actions.asMap().entries.map((entry) {
              final index = entry.key;
              final action = entry.value;
              return _buildQuickActionCard(action)
                  .animate()
                  .fadeIn(
                      delay: (100 * index).ms,
                      duration: 500.ms,
                      curve: Curves.easeOut)
                  .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1, 1),
                      delay: (100 * index).ms,
                      duration: 500.ms,
                      curve: Curves.easeOut);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: action.gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.glassWhite,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(action.icon,
                      color: AppColors.textOnPrimary, size: 22),
                ),
                Text(
                  action.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textOnPrimary,
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // RECENT SCANS
  // ═══════════════════════════════════════════════

  Widget _buildRecentScansSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Scans',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_recentScans.isNotEmpty)
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/herbarium'),
                  child: const Text('See All'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _recentScans.isEmpty ? _buildEmptyScans() : _buildScanCards(),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 500.ms, curve: Curves.easeOut)
        .slideY(
            begin: 0.05,
            end: 0,
            delay: 400.ms,
            duration: 500.ms,
            curve: Curves.easeOut);
  }

  Widget _buildEmptyScans() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.textHint.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'No scans yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the camera button to identify your first plant!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCards() {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _recentScans.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final scan = _recentScans[index];
          return _buildScanCard(scan, index);
        },
      ),
    );
  }

  Widget _buildScanCard(PlantCatalogModel scan, int index) {
    final isNetwork = scan.imagePath.startsWith('http');
    final imageFile = isNetwork ? null : File(scan.imagePath);
    final hasImage = isNetwork || (imageFile != null && imageFile.existsSync());

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => PlantDetailScreen(plant: scan)));
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: hasImage
                    ? Hero(
                        tag: 'plant_image_${scan.id}',
                        child: isNetwork
                            ? CachedNetworkImage(imageUrl: scan.imagePath, fit: BoxFit.cover)
                            : Image.file(imageFile!, fit: BoxFit.cover),
                      )
                    : Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.local_florist_rounded,
                            size: 40, color: AppColors.textHint),
                      ),
              ),
            ),

            // ── Info ──
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.commonName,
                      style:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontSize: 13,
                              ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scan.scientificName,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.textHint,
                                fontSize: 11,
                              ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // ── Confidence badge ──
                    if (scan.verificationStatus == 'pending')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.caution.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PENDING VERIFICATION',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.caution,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _confidenceColor(scan.confidenceScore)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(scan.confidenceScore * 100).toStringAsFixed(0)}% ${_confidenceLabel(scan.confidenceScore)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color:
                                _confidenceColor(scan.confidenceScore),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
            delay: (200 + 120 * index).ms,
            duration: 500.ms,
            curve: Curves.easeOut)
        .slideX(
            begin: 0.15,
            end: 0,
            delay: (200 + 120 * index).ms,
            duration: 500.ms,
            curve: Curves.easeOut);
  }

  // ═══════════════════════════════════════════════
  // FAB
  // ═══════════════════════════════════════════════

  Widget _buildFAB() {
    return FloatingActionButton(
      heroTag: 'dashboard_fab',
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      onPressed: () => Navigator.pushNamed(context, '/scan').then((_) => _loadDashboardData()),
      child: const Icon(Icons.camera_alt_rounded, size: 28),
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 400.ms)
        .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            delay: 500.ms,
            duration: 400.ms,
            curve: Curves.elasticOut);
  }
}

// ═══════════════════════════════════════════════
// PRIVATE HELPER WIDGETS
// ═══════════════════════════════════════════════

/// Animated sync-status indicator dot.
class _SyncStatusDot extends StatelessWidget {
  final bool isOnline;
  const _SyncStatusDot({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? AppColors.synced : AppColors.unsynced,
        boxShadow: [
          BoxShadow(
            color: (isOnline ? AppColors.synced : AppColors.unsynced)
                .withValues(alpha: 0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 1200.ms)
        .then()
        .fade(begin: 1, end: 0.5, duration: 1200.ms);
  }
}

/// Data class for quick-action grid items.
class _QuickAction {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });
}
