import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../database/database_helper.dart';
import '../models/plant_catalog_model.dart';
import '../models/indigenous_metadata_model.dart';

/// ──────────────────────────────────────────────
/// ResultScreen — Detailed identification results
/// with XAI reasoning, safety info, indigenous
/// metadata, and save-to-herbarium functionality.
/// ──────────────────────────────────────────────
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  IndigenousMetadataModel? _indigenousData;
  bool _indigenousLoaded = false;
  bool _isSaving = false;

  late Map<String, dynamic> _result;
  late String _imagePath;
  double? _latitude;
  double? _longitude;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_indigenousLoaded) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _result = args['result'] as Map<String, dynamic>;
      _imagePath = args['imagePath'] as String;
      _latitude = args['latitude'] as double?;
      _longitude = args['longitude'] as double?;
      _loadIndigenousMetadata();
    }
  }

  Future<void> _loadIndigenousMetadata() async {
    final scientificName = _result['scientific_name'] as String? ?? '';
    if (scientificName.isNotEmpty) {
      final metadata = await DatabaseHelper.instance.lookupMetadata(scientificName);
      if (mounted) {
        setState(() {
          _indigenousData = metadata;
          _indigenousLoaded = true;
        });
      }
    } else {
      setState(() => _indigenousLoaded = true);
    }
  }

  // ── Helpers ───────────────────────────────────

  double get _confidence => ((_result['confidence'] as num?) ?? 0).toDouble();
  String get _scientificName => _result['scientific_name'] as String? ?? 'Unknown species';
  String get _commonName => _result['common_name'] as String? ?? 'Unknown';
  String get _family => _result['family'] as String? ?? '';
  String get _reasoning => _result['reasoning'] as String? ?? 'No reasoning provided.';
  String get _edibilityStatus => _result['edibility_status'] as String? ?? 'unknown';
  String get _safetyWarnings => _result['safety_warnings'] as String? ?? '';
  String get _preparationNotes => _result['preparation_notes'] as String? ?? '';
  String get _habitat => _result['habitat'] as String? ?? '';
  String get _nutritionalHighlights => _result['nutritional_highlights'] as String? ?? '';

  Color get _confidenceColor {
    if (_confidence >= 0.80) return AppColors.safe;
    if (_confidence >= 0.60) return AppColors.caution;
    return AppColors.danger;
  }

  Color get _edibilityColor {
    switch (_edibilityStatus) {
      case 'edible':
        return AppColors.safe;
      case 'edible_with_preparation':
        return AppColors.caution;
      case 'toxic':
        return AppColors.danger;
      default:
        return AppColors.textHint;
    }
  }

  String get _edibilityLabel {
    switch (_edibilityStatus) {
      case 'edible':
        return '✓ Edible';
      case 'edible_with_preparation':
        return '⚠ Edible with Preparation';
      case 'toxic':
        return '✕ Toxic';
      default:
        return '? Unknown';
    }
  }

  IconData get _edibilityIcon {
    switch (_edibilityStatus) {
      case 'edible':
        return Icons.check_circle_rounded;
      case 'edible_with_preparation':
        return Icons.warning_amber_rounded;
      case 'toxic':
        return Icons.dangerous_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  // ── Save to Herbarium ─────────────────────────

  Future<void> _saveToHerbarium() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to save plants to your herbarium.'),
          backgroundColor: AppColors.caution,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Combine local names if indigenous metadata exists
      String? localName;
      if (_indigenousData != null) {
        final names = <String>[];
        if (_indigenousData!.igboName != null) names.add('Igbo: ${_indigenousData!.igboName}');
        if (_indigenousData!.hausaName != null) names.add('Hausa: ${_indigenousData!.hausaName}');
        if (_indigenousData!.yorubaName != null) names.add('Yoruba: ${_indigenousData!.yorubaName}');
        if (names.isNotEmpty) localName = names.join(', ');
      }

      final record = PlantCatalogModel(
        userId: user.id,
        scientificName: _scientificName,
        commonName: _commonName,
        localName: localName,
        confidenceScore: _confidence,
        imagePath: _imagePath,
        latitude: _latitude,
        longitude: _longitude,
        xaiReasoning: _reasoning,
        safetyWarnings: _safetyWarnings.isNotEmpty ? _safetyWarnings : null,
        preparationMethods: _preparationNotes.isNotEmpty ? _preparationNotes : null,
        family: _family.isNotEmpty ? _family : null,
        edibilityStatus: _edibilityStatus.isNotEmpty ? _edibilityStatus : null,
        habitat: _habitat.isNotEmpty ? _habitat : null,
        nutritionalHighlights: _nutritionalHighlights.isNotEmpty ? _nutritionalHighlights : null,
        timestamp: DateTime.now(),
      );

      await DatabaseHelper.instance.insertPlantRecord(record);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$_commonName saved to your herbarium!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.safe,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );

      // Pop back to dashboard after a brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero Image AppBar ──
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Plant image
                  Image.file(
                    File(_imagePath),
                    fit: BoxFit.cover,
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  // Bottom info
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Edibility badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _edibilityColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_edibilityIcon, size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                _edibilityLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Names Section ──
                  _buildNamesSection()
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.2, end: 0, duration: 500.ms),

                  const SizedBox(height: 20),

                  // ── Confidence Meter ──
                  _buildConfidenceMeter()
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 500.ms)
                      .slideY(begin: 0.2, end: 0, delay: 100.ms, duration: 500.ms),

                  const SizedBox(height: 20),

                  // ── XAI Reasoning ──
                  _buildXaiReasoningCard()
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 500.ms),

                  const SizedBox(height: 16),

                  // ── Indigenous Names ──
                  _buildIndigenousNamesCard()
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 500.ms)
                      .slideY(begin: 0.2, end: 0, delay: 300.ms, duration: 500.ms),

                  const SizedBox(height: 16),

                  // ── Safety Warnings ──
                  if (_safetyWarnings.isNotEmpty)
                    _buildSafetyWarningsCard()
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, delay: 400.ms, duration: 500.ms),

                  if (_safetyWarnings.isNotEmpty) const SizedBox(height: 16),

                  // ── Preparation Methods ──
                  if (_preparationNotes.isNotEmpty)
                    _buildPreparationCard()
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, delay: 500.ms, duration: 500.ms),

                  if (_preparationNotes.isNotEmpty) const SizedBox(height: 16),

                  // ── Habitat & Nutrition ──
                  if (_habitat.isNotEmpty || _nutritionalHighlights.isNotEmpty)
                    _buildInfoCards()
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, delay: 600.ms, duration: 500.ms),

                  if (_habitat.isNotEmpty || _nutritionalHighlights.isNotEmpty)
                    const SizedBox(height: 16),

                  // ── GPS Info ──
                  if (_latitude != null && _longitude != null)
                    _buildGpsCard()
                        .animate()
                        .fadeIn(delay: 650.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, delay: 650.ms, duration: 500.ms),

                  if (_latitude != null && _longitude != null) const SizedBox(height: 16),

                  // ── Save Button ──
                  const SizedBox(height: 8),
                  _buildSaveButton()
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 500.ms)
                      .slideY(begin: 0.3, end: 0, delay: 700.ms, duration: 500.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Section Builders
  // ═══════════════════════════════════════════════

  Widget _buildNamesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Common Name
        Text(
          _commonName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 4),
        // Scientific Name (italic)
        Text(
          _scientificName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
        ),
        if (_family.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Family: $_family',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConfidenceMeter() {
    final percentage = (_confidence * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Confidence Level',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _confidenceColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    color: _confidenceColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Background track
                Container(
                  height: 10,
                  width: double.infinity,
                  color: AppColors.surfaceVariant,
                ),
                // Filled portion
                FractionallySizedBox(
                  widthFactor: _confidence.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _confidenceColor.withValues(alpha: 0.7),
                          _confidenceColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
                    .animate()
                    .scaleX(
                      begin: 0,
                      end: 1,
                      duration: 800.ms,
                      delay: 200.ms,
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.centerLeft,
                    ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _confidence >= 0.80
                ? 'High confidence identification'
                : _confidence >= 0.60
                    ? 'Moderate confidence — verify before use'
                    : 'Low confidence — exercise extreme caution',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _confidenceColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildXaiReasoningCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Why This Identification?',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _reasoning,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndigenousNamesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.translate_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Indigenous Names',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_indigenousLoaded)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            )
          else if (_indigenousData != null)
            Column(
              children: [
                _buildLanguageRow('🟢', 'Igbo', _indigenousData!.igboName ?? '—'),
                const SizedBox(height: 10),
                _buildLanguageRow('🟡', 'Hausa', _indigenousData!.hausaName ?? '—'),
                const SizedBox(height: 10),
                _buildLanguageRow('🟣', 'Yoruba', _indigenousData!.yorubaName ?? '—'),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Not in local database — indigenous names may be added in future updates.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLanguageRow(String emoji, String language, String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(
              language,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyWarningsCard() {
    final isToxic = _edibilityStatus == 'toxic';
    final bgColor = isToxic ? AppColors.danger : AppColors.caution;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bgColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isToxic ? Icons.dangerous_rounded : Icons.warning_amber_rounded,
              color: bgColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToxic ? 'Danger — Toxic Plant' : 'Safety Warnings',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: bgColor,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  _safetyWarnings,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.safe.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.safe,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Preparation Methods',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _preparationNotes,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Column(
      children: [
        if (_habitat.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.landscape_rounded, color: AppColors.info, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Habitat',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _habitat,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                ),
              ],
            ),
          ),
        if (_habitat.isNotEmpty && _nutritionalHighlights.isNotEmpty)
          const SizedBox(height: 16),
        if (_nutritionalHighlights.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.safe.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.eco_rounded, color: AppColors.safe, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Nutritional Highlights',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _nutritionalHighlights,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGpsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.pin_drop_rounded, color: AppColors.info, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collection Location',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveToHerbarium,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textOnPrimary,
                ),
              )
            : const Icon(Icons.bookmark_add_rounded, size: 22),
        label: Text(_isSaving ? 'Saving...' : 'Save to Herbarium'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          disabledForegroundColor: AppColors.textOnPrimary.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
