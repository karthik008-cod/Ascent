import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _showMotto = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Start animation shortly after build
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showMotto = true);
    });

    // Wait 1.8 seconds minimum before proceeding
    _timer = Timer(const Duration(milliseconds: 1800), _navigate);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _navigate() {
    if (!mounted) return;
    
    // Set splash as shown so redirect allows navigation away from /splash
    ref.read(splashNotifierProvider.notifier).state = true;
    
    // Triggering navigation to root will run redirect logic
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    // Auth provider fetches the user details. If loaded, we get the motto.
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull;
    final motto = user?.motto ?? '1% better every single day.';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final logoWidth = constraints.maxWidth * 0.60;
                    return AnimatedOpacity(
                      opacity: _showMotto ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOut,
                      child: AnimatedScale(
                        scale: _showMotto ? 1.0 : 0.8,
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutBack,
                        child: Container(
                          width: logoWidth,
                          height: logoWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.20),
                                blurRadius: 40,
                                spreadRadius: 16,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Spacer(),
              // Motto at bottom
              AnimatedOpacity(
                opacity: _showMotto ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      motto,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.8,
                        color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
