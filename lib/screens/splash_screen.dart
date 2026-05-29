import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

/// ──────────────────────────────────────────────
/// SplashScreen — Animated landing screen with
/// botanical theming and auto-login detection.
/// ──────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // Allow the animations to play for 3 seconds
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final isLoggedIn = await authService.tryAutoLogin();

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppDecorations.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ── App Icon ──
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.glassWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.glassBorder, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  size: 64,
                  color: AppColors.accentLight,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    duration: 800.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 600.ms),

              const SizedBox(height: 32),

              // ── App Title ──
              Text(
                'FloraID',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.textOnPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, delay: 300.ms, duration: 600.ms),

              const SizedBox(height: 4),

              // ── Subtitle ──
              Text(
                'NIGERIA',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 8,
                      fontSize: 16,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, delay: 500.ms, duration: 600.ms),

              const SizedBox(height: 48),

              // ── Tagline ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'AI-Powered Identification &\nCataloguing of Local Edible Plants',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                        fontSize: 14,
                        height: 1.6,
                      ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 800.ms),

              const Spacer(flex: 2),

              // ── Loading Indicator ──
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accent.withValues(alpha: 0.8),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 1200.ms, duration: 600.ms),

              const SizedBox(height: 16),

              Text(
                'Initializing...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.5),
                      letterSpacing: 1.5,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 1400.ms, duration: 600.ms),

              const Spacer(),

              // ── Attribution ──
              Text(
                'A Final Year Project by\nPeter, John Funom',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 1600.ms, duration: 800.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
