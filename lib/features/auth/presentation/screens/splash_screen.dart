import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planora/core/theme/app_theme.dart';
import 'package:planora/main.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupLoadingAnimation();
  }

  void _setupLoadingAnimation() {
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _loadingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _loadingController.forward();

    // When loading finishes → then navigate
    _loadingController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasNavigated && mounted) {
        // Small delay to ensure smooth transition
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_hasNavigated) {
            _checkAuthAndNavigate();
          }
        });
      }
    });
  }

  /// Setup animations for logo
  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // SCALE: tiny → big → normal → bounce
    _scaleAnimation = TweenSequence<double>([
      // Tiny → Big
      TweenSequenceItem(
        tween: Tween(
          begin: 0.1,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      // Big → Slightly above normal
      TweenSequenceItem(
        tween: Tween(
          begin: 1.3,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      // Settle to normal
      TweenSequenceItem(
        tween: Tween(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      // Bounce up
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      // Bounce down
      TweenSequenceItem(
        tween: Tween(
          begin: 1.08,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_animationController);

    // ROTATION: only happens in the middle
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
          0.35, // start after growing
          0.65, // end before bounce
          curve: Curves.easeInOutCubic,
        ),
      ),
    );

    _animationController.forward();
  }

  /// Check if user is logged in and navigate accordingly
  Future<void> _checkAuthAndNavigate() async {
    // Prevent multiple navigations
    if (_hasNavigated || !mounted) return;

    try {
      // Get current user session
      final session = supabase.auth.currentSession;
      final user = supabase.auth.currentUser;

      if (session != null && user != null) {
        // User is logged in → Navigate to Home
        debugPrint('User is logged in: ${user.email}');
        _navigateToHome();
      } else {
        // User is not logged in → Navigate to Login
        debugPrint('User is not logged in');
        _navigateToLogin();
      }
    } catch (e) {
      debugPrint('Error checking auth: $e');
      // On error, navigate to login for safety
      if (mounted && !_hasNavigated) {
        _navigateToLogin();
      }
    }
  }

  /// Navigate to Login screen
  void _navigateToLogin() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  /// Navigate to Home screen
  void _navigateToHome() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        // Gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [AppTheme.darkSurface, AppTheme.darkBackground]
                : [AppTheme.primaryColor, AppTheme.secondaryColor],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return RotationTransition(
                          turns: _rotationAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: _buildTickIcon(),
                    ),

                    const SizedBox(height: 32),
                    Text(
                      "P L A N O R A",
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Plan • Track • Improve',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
              // Bottom loading line
              Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: AnimatedBuilder(
                    animation: _loadingAnimation,
                    builder: (context, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _loadingAnimation.value,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTickIcon() {
    return const Icon(
      Icons.check_circle_rounded,
      size: 140,
      color: Colors.white,
    );
  }
}
