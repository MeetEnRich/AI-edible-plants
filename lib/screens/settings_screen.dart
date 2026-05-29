import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/gemini_service.dart';
import '../services/sync_service.dart';
import '../database/database_helper.dart';

/// ──────────────────────────────────────────────
/// SettingsScreen — App configuration hub covering
/// Gemini API key, account, sync, and about info.
/// ──────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _geminiService = GeminiService();
  bool _hasApiKey = false;
  bool _isApiKeyVisible = false;
  bool _isSavingKey = false;
  
  final _imgBbKeyController = TextEditingController();
  bool _hasImgBbKey = false;
  bool _isImgBbKeyVisible = false;

  @override
  void initState() {
    super.initState();
    _checkApiKeyStatus();
    _checkImgBbKeyStatus();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    final userId = context.read<AuthService>().currentUser?.id;
    if (userId != null) {
      final count = await DatabaseHelper.instance.getUnsyncedCount(userId);
      if (mounted) {
        context.read<SyncService>().updatePendingCount(count);
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _imgBbKeyController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKeyStatus() async {
    final hasKey = await _geminiService.hasApiKey();
    if (mounted) setState(() => _hasApiKey = hasKey);
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      _showSnack('Please enter a valid API key', isError: true);
      return;
    }

    setState(() => _isSavingKey = true);

    try {
      await _geminiService.setApiKey(key);
      _apiKeyController.clear();
      await _checkApiKeyStatus();
      _showSnack('API key saved successfully!');
    } catch (e) {
      _showSnack('Failed to save key: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingKey = false);
    }
  }

  Future<void> _checkImgBbKeyStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('imgbb_api_key');
    if (mounted) setState(() => _hasImgBbKey = key != null && key.isNotEmpty);
  }

  Future<void> _saveImgBbKey() async {
    final key = _imgBbKeyController.text.trim();
    if (key.isEmpty) {
      _showSnack('Please enter a valid ImgBB API key', isError: true);
      return;
    }

    setState(() => _isSavingKey = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('imgbb_api_key', key);
      _imgBbKeyController.clear();
      await _checkImgBbKeyStatus();
      _showSnack('ImgBB API key saved successfully!');
    } catch (e) {
      _showSnack('Failed to save ImgBB key: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingKey = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthService>().logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final syncService = context.watch<SyncService>();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // ── Gemini API Key ─────────────────────
          _buildSectionHeader('Gemini AI Configuration', Icons.auto_awesome_rounded),
          const SizedBox(height: 10),
          _buildPremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (_hasApiKey ? AppColors.safe : AppColors.danger)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _hasApiKey ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: _hasApiKey ? AppColors.safe : AppColors.danger,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasApiKey ? 'API Key Configured' : 'No API Key Set',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _hasApiKey ? AppColors.safe : AppColors.danger,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _hasApiKey
                                ? 'Gemini AI is ready for plant identification'
                                : 'Add your key to enable plant scanning',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // API Key input
                TextFormField(
                  controller: _apiKeyController,
                  obscureText: !_isApiKeyVisible,
                  decoration: InputDecoration(
                    hintText: 'Enter Gemini API Key',
                    prefixIcon: const Icon(Icons.key_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isApiKeyVisible
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _isApiKeyVisible = !_isApiKeyVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSavingKey ? null : _saveApiKey,
                    icon: _isSavingKey
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_isSavingKey ? 'Saving…' : 'Save Key'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),

          const SizedBox(height: 28),

          // ── ImgBB API Key ─────────────────────
          _buildSectionHeader('ImgBB Cloud Backup', Icons.cloud_upload_rounded),
          const SizedBox(height: 10),
          _buildPremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (_hasImgBbKey ? AppColors.safe : AppColors.danger)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _hasImgBbKey ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: _hasImgBbKey ? AppColors.safe : AppColors.danger,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasImgBbKey ? 'ImgBB Key Configured' : 'No ImgBB Key Set',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _hasImgBbKey ? AppColors.safe : AppColors.danger,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _hasImgBbKey
                                ? 'Image Cloud Backup is enabled'
                                : 'Add your key to enable image backups',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // API Key input
                TextFormField(
                  controller: _imgBbKeyController,
                  obscureText: !_isImgBbKeyVisible,
                  decoration: InputDecoration(
                    hintText: 'Enter ImgBB API Key',
                    prefixIcon: const Icon(Icons.key_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isImgBbKeyVisible
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _isImgBbKeyVisible = !_isImgBbKeyVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSavingKey ? null : _saveImgBbKey,
                    icon: _isSavingKey
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_isSavingKey ? 'Saving…' : 'Save Key'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),

          const SizedBox(height: 28),

          // ── Account ────────────────────────────
          _buildSectionHeader('Account', Icons.person_rounded),
          const SizedBox(height: 10),
          _buildPremiumCard(
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.person_outline_rounded,
                  'Username',
                  user?.username ?? 'Not logged in',
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.email_outlined,
                  'Email',
                  user?.email ?? '—',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.05),

          const SizedBox(height: 28),

          // ── Sync ───────────────────────────────
          _buildSectionHeader('Data Sync', Icons.sync_rounded),
          const SizedBox(height: 10),
          _buildPremiumCard(
            child: Column(
              children: [
                // Online status
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: syncService.isOnline ? AppColors.safe : AppColors.textHint,
                        shape: BoxShape.circle,
                        boxShadow: syncService.isOnline
                            ? [
                                BoxShadow(
                                  color: AppColors.safe.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      syncService.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: syncService.isOnline ? AppColors.safe : AppColors.textHint,
                      ),
                    ),
                    const Spacer(),
                    if (syncService.isSyncing)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  Icons.cloud_upload_outlined,
                  'Pending Records',
                  '${syncService.pendingCount}',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: syncService.isOnline && !syncService.isSyncing
                        ? () => syncService.syncNow()
                        : null,
                    icon: const Icon(Icons.cloud_sync_rounded, size: 18),
                    label: Text(syncService.isSyncing ? 'Syncing…' : 'Sync Now'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.surfaceVariant,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.05),

          const SizedBox(height: 28),

          // ── About ──────────────────────────────
          _buildSectionHeader('About', Icons.info_outline_rounded),
          const SizedBox(height: 10),
          _buildPremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App logo area
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppDecorations.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'FloraID Nigeria',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentDark,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'An AI-powered mobile application for the identification and '
                  'cataloging of Nigerian edible plants, leveraging Gemini multimodal '
                  'AI with Explainable AI (XAI) reasoning and indigenous ethnobotanical '
                  'knowledge for safe, informed foraging.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                // Disclaimer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.caution.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.caution.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.caution,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This app is an educational aid and does not replace '
                          'professional botanical identification. Always consult '
                          'an expert before consuming any wild plant.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: AppColors.caution,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.05),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
