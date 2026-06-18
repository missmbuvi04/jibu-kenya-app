import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/auth_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/secure_storage.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    print('SPLASH: started');
    await Future.delayed(const Duration(seconds: 2));
    print('SPLASH: delay done');
    if (!mounted) return;

    print('SPLASH: calling checkAuthStatus');
    await ref.read(authProvider.notifier).checkAuthStatus();
    print('SPLASH: checkAuthStatus done');

    if (!mounted) return;

    final authState = ref.read(authProvider);
    print('SPLASH: isAuthenticated = ${authState.isAuthenticated}');

    final user = ref.read(authProvider).user;
    if (authState.isAuthenticated) {
      if (user?.isCountyOfficer == true) {
        context.go(AppRoutes.countyOfficerHome);
      } else {
        context.go(AppRoutes.home);
      }
    } else {
      context.go(AppRoutes.login);
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.teal,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Jibu Kenya',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Civic Infrastructure Reporting',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 24),
              Container(width: 60, height: 2, color: AppColors.amber),
              const SizedBox(height: 16),
              const Text(
                'Report. Track. Accountable.',
                style: TextStyle(
                  color: AppColors.amber,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 60),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.amber,
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}