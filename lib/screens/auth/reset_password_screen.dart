import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../widgets/background_scaffold.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';

import 'dart:async';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final bool isRecovery;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    this.isRecovery = false,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isRecovery) {
      startTimer();
    }
  }

  void startTimer() {
    setState(() {
      _start = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resendCode() async {
    try {
      await _authService.recoverPassword(widget.email);
      startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Code resent successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newPassword = _newPasswordController.text.trim();

      if (widget.isRecovery) {
        if (newPassword.isEmpty) {
          throw 'Please enter a new password';
        }
        if (newPassword.length < 6) {
          throw 'Password must be at least 6 characters long';
        }

        // 1. Update Password directly (already authenticated via recovery link)
        await _authService.updatePassword(newPassword);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Password updated successfully! Welcome back."),
              backgroundColor: Colors.green,
            ),
          );
          // Reset the recovery state to trigger home screen reload
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.setNeedsPasswordReset(false);
        }
      } else {
        final otp = _otpController.text.trim();
        if (otp.isEmpty || newPassword.isEmpty) {
          throw 'Please fill in all fields';
        }
        if (newPassword.length < 6) {
          throw 'Password must be at least 6 characters long';
        }

        // 1. Verify OTP (Recovery type)
        await _authService.verifyRecoveryOtp(email: widget.email, token: otp);

        // 2. Update Password (now authenticated)
        await _authService.updatePassword(newPassword);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Password updated successfully! Welcome back."),
              backgroundColor: Colors.green,
            ),
          );
          // Pop all the way back to the root route (which rebuilds to MainScreen now that they are authenticated)
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
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
                  onPressed: () async {
                    if (widget.isRecovery) {
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      await userProvider.signOut();
                      userProvider.setNeedsPasswordReset(false);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
              const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white12,
                    child: Icon(Icons.lock_open, size: 40, color: Colors.white),
                  )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .fade(duration: 600.ms),
              const SizedBox(height: 30),
              GlassContainer(
                child: Column(
                  children: [
                    const Text(
                      "Reset Password",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(),
                    const SizedBox(height: 10),
                    Text(
                      widget.isRecovery
                          ? "Enter your new password below"
                          : "Enter the code and your new password",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ).animate().fadeIn(delay: 150.ms).slideX(),
                    const SizedBox(height: 30),
                    if (!widget.isRecovery) ...[
                      CustomTextField(
                        controller: _otpController,
                        hintText: "6-digit Recovery Code",
                        prefixIcon: Icons.lock_clock_outlined,
                        keyboardType: TextInputType.number,
                      ).animate().fadeIn(delay: 200.ms).slideY(),
                      const SizedBox(height: 15),
                    ],
                    CustomTextField(
                      controller: _newPasswordController,
                      hintText: "New Password",
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      suffixIcon: const Icon(
                        Icons.visibility_off,
                        color: Colors.white70,
                      ),
                    ).animate().fadeIn(delay: 250.ms).slideY(),
                    const SizedBox(height: 20),

                    if (!widget.isRecovery) ...[
                      // Resend Timer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Didn't receive code? ",
                            style: TextStyle(color: Colors.white70),
                          ),
                          if (_canResend)
                            GestureDetector(
                              onTap: _resendCode,
                              child: const Text(
                                "Resend",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                ),
                              ),
                            )
                          else
                            Text(
                              "Resend in $_start s",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ).animate().fadeIn(delay: 220.ms),
                      const SizedBox(height: 30),
                    ],

                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : CustomButton(
                            text: widget.isRecovery ? "Update Password" : "Set New Password",
                            onPressed: _resetPassword,
                          ).animate().fadeIn(delay: 300.ms).slideY(),
                    
                    if (widget.isRecovery) ...[
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () async {
                          final userProvider = Provider.of<UserProvider>(context, listen: false);
                          await userProvider.signOut();
                          userProvider.setNeedsPasswordReset(false);
                        },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white38,
                          ),
                        ),
                      ).animate().fadeIn(delay: 350.ms),
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
