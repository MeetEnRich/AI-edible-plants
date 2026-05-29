import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../database/database_helper.dart';
import '../models/indigenous_metadata_model.dart';

/// ──────────────────────────────────────────────
/// EncyclopediaScreen — Searchable reference of
/// all seeded indigenous Nigerian edible plants.
/// ──────────────────────────────────────────────
class EncyclopediaScreen extends StatefulWidget {
  const EncyclopediaScreen({super.key});

  @override
  State<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends State<EncyclopediaScreen> {
  final _searchController = TextEditingController();
  List<IndigenousMetadataModel> _allPlants = [];
  List<IndigenousMetadataModel> _filteredPlants = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final plants = await DatabaseHelper.instance.getAllMetadata();
      setState(() {
        _allPlants = plants;
        _filteredPlants = plants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load encyclopedia: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _filteredPlants = _allPlants);
      return;
    }

    try {
      final results = await DatabaseHelper.instance.searchMetadata(query.trim());
      setState(() => _filteredPlants = results);
    } catch (_) {
      // Fall back to local filtering
      final q = query.toLowerCase();
      setState(() {
        _filteredPlants = _allPlants.where((p) {
          return p.scientificName.toLowerCase().contains(q) ||
              p.family.toLowerCase().contains(q) ||
              (p.igboName?.toLowerCase().contains(q) ?? false) ||
              (p.hausaName?.toLowerCase().contains(q) ?? false) ||
              (p.yorubaName?.toLowerCase().contains(q) ?? false);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? _buildSearchField()
            : const Text('Plant Encyclopedia'),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                _isSearching ? Icons.close_rounded : Icons.search_rounded,
                key: ValueKey(_isSearching),
              ),
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredPlants = _allPlants;
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      onChanged: _onSearch,
      style: const TextStyle(color: AppColors.textOnPrimary, fontSize: 16),
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        hintText: 'Search plants, families, local names…',
        hintStyle: TextStyle(
          color: AppColors.textOnPrimary.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        border: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
      ),
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
              const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _loadPlants,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredPlants.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No plants found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHint,
                  ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadPlants,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _filteredPlants.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader();
          }
          final plant = _filteredPlants[index - 1];
          return _EncyclopediaCard(plant: plant)
              .animate()
              .fadeIn(delay: (50 * index).ms, duration: 400.ms)
              .slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOut);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '${_filteredPlants.length} species',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (_searchController.text.isNotEmpty)
            Text(
              'Results for "${_searchController.text}"',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textHint,
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ═══════════════════════════════════════════════
// Encyclopedia Card — Expandable plant entry
// ═══════════════════════════════════════════════
class _EncyclopediaCard extends StatefulWidget {
  final IndigenousMetadataModel plant;

  const _EncyclopediaCard({required this.plant});

  @override
  State<_EncyclopediaCard> createState() => _EncyclopediaCardState();
}

class _EncyclopediaCardState extends State<_EncyclopediaCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content — tappable
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Botanical icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppDecorations.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.spa_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plant.scientificName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                plant.family,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Expand icon
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Local name chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (plant.igboName != null && plant.igboName!.isNotEmpty)
                        _LocalNameChip(
                          language: 'Igbo',
                          name: plant.igboName!,
                          color: const Color(0xFF2E7D32),
                        ),
                      if (plant.hausaName != null && plant.hausaName!.isNotEmpty)
                        _LocalNameChip(
                          language: 'Hausa',
                          name: plant.hausaName!,
                          color: const Color(0xFF1565C0),
                        ),
                      if (plant.yorubaName != null && plant.yorubaName!.isNotEmpty)
                        _LocalNameChip(
                          language: 'Yoruba',
                          name: plant.yorubaName!,
                          color: const Color(0xFF6A1B9A),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Brief description
                  Text(
                    plant.description,
                    maxLines: _isExpanded ? null : 2,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable detail section
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedDetails(plant),
            crossFadeState:
                _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 350),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails(IndigenousMetadataModel plant) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24),

          // Preparation methods
          _DetailSection(
            icon: Icons.restaurant_rounded,
            title: 'Preparation Methods',
            content: plant.preparationMethods,
            accentColor: AppColors.safe,
          ),

          const SizedBox(height: 16),

          // Safety warnings
          _DetailSection(
            icon: Icons.warning_amber_rounded,
            title: 'Safety Warnings',
            content: plant.safetyWarnings,
            accentColor: AppColors.caution,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Local Name Chip
// ═══════════════════════════════════════════════
class _LocalNameChip extends StatelessWidget {
  final String language;
  final String name;
  final Color color;

  const _LocalNameChip({
    required this.language,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            language,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Detail Section within expanded card
// ═══════════════════════════════════════════════
class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color accentColor;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.content,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
