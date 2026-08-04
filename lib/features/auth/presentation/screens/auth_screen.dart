import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/dynamic_loading_indicator.dart';

enum AuthStep { email, methodSelection, passwordSignIn, otpVerification, signUpDetails, forgotPasswordOtp, forgotPasswordNew }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  AuthStep _currentStep = AuthStep.email;
  bool _userExists = false;
  bool _isLoading = false;
  bool _isOtpLoading = false;
  bool _isForgotLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  bool _hasStartedTypingConfirm = false;
  bool _isPasswordMatch = false;

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
      TextInput.finishAutofillContext();
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
      TextInput.finishAutofillContext();
      if (mounted) context.go('/');
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  Future<void> _handleForgotPasswordOtpSubmit() async {
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
        setState(() {
          _passwordController.clear();
          _confirmPasswordController.clear();
          _hasStartedTypingConfirm = false;
          _currentStep = AuthStep.forgotPasswordNew;
        });
      } else {
        _setError('Invalid or expired OTP. Please try again.');
      }
    } catch (e) {
      _setError('Error verifying OTP: $e');
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  Future<void> _handleForgotPasswordNewSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

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
      await ref.read(authNotifierProvider.notifier).updatePassword(email, password);
      TextInput.finishAutofillContext();
      setState(() {
        _passwordController.clear();
        _confirmPasswordController.clear();
        _hasStartedTypingConfirm = false;
        _currentStep = AuthStep.passwordSignIn;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!')));
    } catch (e) {
      _setError('Failed to update password.');
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
      case AuthStep.forgotPasswordOtp:
        return _buildForgotPasswordOtpStep();
      case AuthStep.forgotPasswordNew:
        return _buildForgotPasswordNewStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: AutofillGroup(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
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
      ),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Welcome', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Text('Enter your email to continue.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 48),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
        ),
        const SizedBox(height: 32),
        _buildError(),
        _buildButton(
          'Continue', 
          _handleEmailSubmit,
          loadingMessages: ['Checking account...', 'Looking up user details...', 'Almost there...'],
        ),
      ],
    );
  }

  Widget _buildMethodSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Welcome Back!', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text('How would you like to sign in?', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _errorMessage = null;
              _currentStep = AuthStep.passwordSignIn;
            });
          },
          child: const Text('Sign In with Password'),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: _isOtpLoading ? null : () async {
            setState(() {
              _errorMessage = null;
              _isOtpLoading = true;
            });
            final sent = await ref.read(authNotifierProvider.notifier).sendOtp(_emailController.text.trim());
            if (mounted) setState(() => _isOtpLoading = false);
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
          child: _isOtpLoading 
            ? const DynamicLoadingIndicator(
                messages: ['Contacting server...', 'Generating secure OTP...', 'Sending email...'],
                isHorizontal: true,
                color: AppColors.primary,
              )
            : const Text('Send One-Time Code (OTP)', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 32),
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
          autofillHints: const [AutofillHints.password],
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
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isForgotLoading ? null : () async {
              setState(() => _isForgotLoading = true);
              final sent = await ref.read(authNotifierProvider.notifier).sendOtp(_emailController.text.trim());
              if (mounted) setState(() => _isForgotLoading = false);
              if (sent) {
                _otpController.clear();
                setState(() => _currentStep = AuthStep.forgotPasswordOtp);
              } else {
                _setError('Failed to send reset code. Please try again.');
              }
            },
            child: _isForgotLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Forgot Password?', style: TextStyle(color: AppColors.primary, fontSize: 14)),
          ),
        ),
        const SizedBox(height: 16),
        _buildError(),
        _buildButton(
          'Sign In', 
          _handlePasswordSignIn,
          loadingMessages: ['Authenticating...', 'Syncing your data...', 'Restoring your missions...'],
        ),
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
        const SizedBox(height: 16),
        Text('We sent a 6-digit code to\n${_emailController.text}', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 48),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(letterSpacing: 8, fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_paste),
              tooltip: 'Paste OTP',
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data != null && data.text != null) {
                  final pastedText = data.text!.replaceAll(RegExp(r'[^0-9]'), '');
                  if (pastedText.isNotEmpty) {
                    _otpController.text = pastedText.substring(0, pastedText.length > 6 ? 6 : pastedText.length);
                  }
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildError(),
        _buildButton(
          'Verify Code', 
          _handleOtpSubmit,
          loadingMessages: ['Verifying OTP...', 'Authenticating securely...', 'Loading your data...'],
        ),
        const SizedBox(height: 16),
        _buildBackButton(_userExists ? AuthStep.methodSelection : AuthStep.email),
      ],
    );
  }

  Widget _buildForgotPasswordOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Reset Password', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text('Enter the 6-digit code sent to\n${_emailController.text}', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 48),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(letterSpacing: 8, fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_paste),
              tooltip: 'Paste OTP',
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data != null && data.text != null) {
                  final pastedText = data.text!.replaceAll(RegExp(r'[^0-9]'), '');
                  if (pastedText.isNotEmpty) {
                    _otpController.text = pastedText.substring(0, pastedText.length > 6 ? 6 : pastedText.length);
                  }
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildError(),
        _buildButton(
          'Verify Code', 
          _handleForgotPasswordOtpSubmit,
          loadingMessages: ['Verifying code...', 'Confirming identity...', 'Preparing password reset...'],
        ),
        const SizedBox(height: 16),
        _buildBackButton(AuthStep.passwordSignIn),
      ],
    );
  }

  Widget _buildForgotPasswordNewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('New Password', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text('Create a new secure password.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 48),
        Offstage(
          child: TextField(
            controller: _emailController,
            autofillHints: const [AutofillHints.username],
          ),
        ),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: (val) {
            if (_hasStartedTypingConfirm) {
              setState(() {
                _isPasswordMatch = val == _confirmPasswordController.text;
              });
            }
          },
          decoration: InputDecoration(
            labelText: 'New Password',
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
        TextField(
          controller: _confirmPasswordController,
          obscureText: true, // No visibility toggle on confirm field
          onChanged: (val) {
            setState(() {
              _hasStartedTypingConfirm = true;
              _isPasswordMatch = val == _passwordController.text;
            });
          },
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_reset_outlined),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: !_hasStartedTypingConfirm
                    ? Colors.transparent
                    : (_isPasswordMatch ? Colors.green : AppColors.error),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: !_hasStartedTypingConfirm
                    ? AppColors.primary
                    : (_isPasswordMatch ? Colors.green : AppColors.error),
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildError(),
        _buildButton(
          'Update Password', 
          _handleForgotPasswordNewSubmit,
          loadingMessages: ['Encrypting password...', 'Updating your credentials...', 'Almost done...'],
        ),
        const SizedBox(height: 16),
        _buildBackButton(AuthStep.passwordSignIn),
      ],
    );
  }

  Widget _buildSignUpDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Create Account', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text('Just a few more details to get started.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 48),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: (val) {
            if (_hasStartedTypingConfirm) {
              setState(() {
                _isPasswordMatch = val == _confirmPasswordController.text;
              });
            }
          },
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
        const SizedBox(height: 24),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true, // No visibility toggle on confirm field
          onChanged: (val) {
            setState(() {
              _hasStartedTypingConfirm = true;
              _isPasswordMatch = val == _passwordController.text;
            });
          },
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_reset_outlined),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: !_hasStartedTypingConfirm
                    ? Colors.transparent
                    : (_isPasswordMatch ? Colors.green : AppColors.error),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: !_hasStartedTypingConfirm
                    ? AppColors.primary
                    : (_isPasswordMatch ? Colors.green : AppColors.error),
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildError(),
        _buildButton(
          'Complete Sign Up', 
          _handleSignUpDetailsSubmit,
          loadingMessages: ['Creating your account...', 'Setting up your profile...', 'Preparing your workspace...'],
        ),
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

  Widget _buildButton(String text, VoidCallback onPressed, {List<String>? loadingMessages}) {
    final isDisabled = _isLoading || _isOtpLoading || _isForgotLoading;
    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      child: _isLoading 
          ? DynamicLoadingIndicator(
              messages: loadingMessages ?? ['Processing...', 'Please wait...', 'Verifying details...'],
              isHorizontal: true,
            )
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
