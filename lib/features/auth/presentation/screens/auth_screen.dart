import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';

enum AuthStep { email, methodSelection, passwordSignIn, otpVerification, signUpDetails }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  AuthStep _currentStep = AuthStep.email;
  bool _userExists = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _setError(String? message) {
    setState(() {
      _errorMessage = message;
    });
  }

  void _setLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  Future<void> _handleEmailSubmit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _setError('Please enter a valid email address.');
      return;
    }
    _setError(null);
    _setLoading(true);

    try {
      _userExists = await ref.read(authNotifierProvider.notifier).checkUserExists(email);
      if (_userExists) {
        setState(() => _currentStep = AuthStep.methodSelection);
      } else {
        // New User -> Must use OTP
        final sent = await ref.read(authNotifierProvider.notifier).sendOtp(email);
        if (sent) {
          setState(() => _currentStep = AuthStep.otpVerification);
        } else {
          _setError('Failed to send OTP email. Please try again.');
        }
      }
    } catch (e) {
      _setError('Error checking email: $e');
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  Future<void> _handleOtpSubmit() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      _setError('Please enter the full 6-digit code.');
      return;
    }
    _setError(null);
    _setLoading(true);

    try {
      final isValid = await ref.read(authNotifierProvider.notifier).verifyOtp(email, otp);
      if (isValid) {
        if (_userExists) {
          // Existing user -> Log them in immediately with OTP
          await ref.read(authNotifierProvider.notifier).loginWithOtp(email);
          if (mounted) context.go('/');
        } else {
          // New user -> Move to signup details
          setState(() => _currentStep = AuthStep.signUpDetails);
        }
      } else {
        _setError('Invalid or expired OTP. Please try again.');
      }
    } catch (e) {
      _setError('Error verifying OTP: $e');
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  Future<void> _handlePasswordSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      _setError('Please enter your password.');
      return;
    }
    _setError(null);
    _setLoading(true);

    try {
      await ref.read(authNotifierProvider.notifier).signIn(email, password);
      if (mounted) context.go('/');
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  Future<void> _handleSignUpDetailsSubmit() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (name.isEmpty) {
      _setError('Please enter your full name.');
      return;
    }
    
    final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$&*~]).{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      _setError('Password must be at least 8 chars, with 1 uppercase, 1 number, and 1 special character (!@#\$&*~).');
      return;
    }

    if (password != confirm) {
      _setError('Passwords do not match.');
      return;
    }

    _setError(null);
    _setLoading(true);

    try {
      await ref.read(authNotifierProvider.notifier).signUp(email, password, name);
      if (mounted) context.go('/');
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case AuthStep.email:
        return _buildEmailStep();
      case AuthStep.methodSelection:
        return _buildMethodSelectionStep();
      case AuthStep.passwordSignIn:
        return _buildPasswordStep();
      case AuthStep.otpVerification:
        return _buildOtpStep();
      case AuthStep.signUpDetails:
        return _buildSignUpDetailsStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Unique custom transition: Fade + slight Scale up
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    key: ValueKey(_currentStep),
                    child: _buildStepContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Welcome', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Enter your email to continue.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 48),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
        ),
        const SizedBox(height: 24),
        _buildError(),
        _buildButton('Continue', _handleEmailSubmit),
      ],
    );
  }

  Widget _buildMethodSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Welcome Back!', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('How would you like to sign in?', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 48),
        _buildButton('Sign In with Password', () {
          setState(() {
            _errorMessage = null;
            _currentStep = AuthStep.passwordSignIn;
          });
        }),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () async {
            setState(() {
              _errorMessage = null;
              _isLoading = true;
            });
            final sent = await ref.read(authNotifierProvider.notifier).sendOtp(_emailController.text.trim());
            setState(() => _isLoading = false);
            if (sent) {
              setState(() => _currentStep = AuthStep.otpVerification);
            } else {
              _setError('Failed to send OTP. Please try again.');
            }
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _isLoading 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Send One-Time Code (OTP)', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
        _buildError(),
        _buildBackButton(AuthStep.email),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Enter Password', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28), textAlign: TextAlign.center),
        const SizedBox(height: 48),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: _obscurePassword ? Colors.grey : AppColors.primary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              splashRadius: 20,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildError(),
        _buildButton('Sign In', _handlePasswordSignIn),
        const SizedBox(height: 16),
        _buildBackButton(AuthStep.methodSelection),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Check Your Email', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('We sent a 6-digit code to\n${_emailController.text}', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 48),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(letterSpacing: 8, fontSize: 24, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            counterText: '',
            hintText: '000000',
            contentPadding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 24),
        _buildError(),
        _buildButton('Verify Code', _handleOtpSubmit),
        const SizedBox(height: 16),
        _buildBackButton(_userExists ? AuthStep.methodSelection : AuthStep.email),
      ],
    );
  }

  Widget _buildSignUpDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Create Account', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Just a few more details to get started.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 48),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Create Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: _obscurePassword ? Colors.grey : AppColors.primary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              splashRadius: 20,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscurePassword,
          decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_reset_outlined)),
        ),
        const SizedBox(height: 24),
        _buildError(),
        _buildButton('Complete Sign Up', _handleSignUpDetailsSubmit),
      ],
    );
  }

  Widget _buildError() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: AppColors.error),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      child: _isLoading 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(text),
    );
  }

  Widget _buildBackButton(AuthStep backStep) {
    return TextButton(
      onPressed: _isLoading ? null : () {
        setState(() {
          _errorMessage = null;
          _currentStep = backStep;
        });
      },
      child: const Text('Back', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
