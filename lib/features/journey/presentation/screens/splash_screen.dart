import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/screens/dart:async';
import '../../../auth/presentation/providers/auth_provider.dart';

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
                    return Container(
                      width: logoWidth,
                      height: logoWidth,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.15),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
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
