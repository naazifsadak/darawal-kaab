import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/background_scaffold.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';

enum ResetStep {
  enterEmail,
  verifyOtp,
  createNewPassword,
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  ResetStep _currentStep = ResetStep.enterEmail;
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.recoverPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP code sent successfully to your email!"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _currentStep = ResetStep.verifyOtp;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP code'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.verifyRecoveryOtp(email: email, token: otp);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP verified successfully! Please set your new password."),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _currentStep = ResetStep.createNewPassword;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all password fields'), backgroundColor: Colors.red),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters long'), backgroundColor: Colors.red),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.updatePassword(password);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset successfully! Welcome back."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  IconData _getStepIcon() {
    switch (_currentStep) {
      case ResetStep.enterEmail:
        return Icons.lock_reset;
      case ResetStep.verifyOtp:
        return Icons.mark_email_read_outlined;
      case ResetStep.createNewPassword:
        return Icons.lock_open;
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case ResetStep.enterEmail:
        return "Forgot Password";
      case ResetStep.verifyOtp:
        return "Verify OTP";
      case ResetStep.createNewPassword:
        return "New Password";
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case ResetStep.enterEmail:
        return "Enter your email to receive an OTP code";
      case ResetStep.verifyOtp:
        return "We have sent a 6-digit OTP code to\n${_emailController.text.trim()}\n\nPlease enter the code to verify your identity.";
      case ResetStep.createNewPassword:
        return "Create your new password below";
    }
  }

  String _getStepButtonText() {
    switch (_currentStep) {
      case ResetStep.enterEmail:
        return "Send OTP Code";
      case ResetStep.verifyOtp:
        return "Verify OTP";
      case ResetStep.createNewPassword:
        return "Reset Password";
    }
  }

  VoidCallback _onStepButtonPressed() {
    switch (_currentStep) {
      case ResetStep.enterEmail:
        return _sendOtp;
      case ResetStep.verifyOtp:
        return _verifyOtp;
      case ResetStep.createNewPassword:
        return _resetPassword;
    }
  }

  List<Widget> _buildStepFields() {
    switch (_currentStep) {
      case ResetStep.enterEmail:
        return [
          CustomTextField(
            controller: _emailController,
            hintText: "Email Address",
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ).animate().fadeIn(delay: 200.ms).slideY(),
        ];
      case ResetStep.verifyOtp:
        return [
          CustomTextField(
            controller: _otpController,
            hintText: "6-digit OTP Code",
            prefixIcon: Icons.lock_clock_outlined,
            keyboardType: TextInputType.number,
          ).animate().fadeIn(delay: 200.ms).slideY(),
        ];
      case ResetStep.createNewPassword:
        return [
          CustomTextField(
            controller: _passwordController,
            hintText: "New Password",
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(),
          const SizedBox(height: 15),
          CustomTextField(
            controller: _confirmPasswordController,
            hintText: "Confirm Password",
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ).animate().fadeIn(delay: 250.ms).slideY(),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (_currentStep == ResetStep.enterEmail) {
                      Navigator.of(context).pop();
                    } else if (_currentStep == ResetStep.verifyOtp) {
                      setState(() {
                        _currentStep = ResetStep.enterEmail;
                      });
                    } else {
                      _authService.signOut();
                      setState(() {
                        _currentStep = ResetStep.enterEmail;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),

              CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white12,
                    child: Icon(
                      _getStepIcon(),
                      size: 40,
                      color: Colors.white,
                    ),
                  )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .fade(duration: 600.ms),
              const SizedBox(height: 30),
              GlassContainer(
                child: Column(
                  children: [
                    Text(
                      _getStepTitle(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(),
                    const SizedBox(height: 10),
                    Text(
                      _getStepSubtitle(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ).animate().fadeIn(delay: 150.ms).slideX(),
                    const SizedBox(height: 30),
                    ..._buildStepFields(),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : CustomButton(
                            text: _getStepButtonText(),
                            onPressed: _onStepButtonPressed(),
                          ).animate().fadeIn(delay: 250.ms).slideY(),
                    if (_currentStep == ResetStep.verifyOtp) ...[
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: _sendOtp,
                        child: const Text(
                          "Resend OTP Code",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white38,
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
