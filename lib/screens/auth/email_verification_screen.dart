import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/background_scaffold.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';

import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  Timer? _timer;
  int _start = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
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
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.resendOtp(widget.email);
      startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Confirmation email resent successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        String message = e.message;
        if (message.toLowerCase().contains('rate limit')) {
          message =
              'Rate limit exceeded. Please wait a bit before requesting a new confirmation email.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white12,
                    child: Icon(
                      Icons.mark_email_read_outlined,
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
                    const Text(
                      "Verify Your Email",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideX(),
                    const SizedBox(height: 10),
                    Text(
                      "We have sent a verification link to\n${widget.email}\n\nPlease check your email inbox and click the confirmation link to activate your account.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ).animate().fadeIn(delay: 150.ms).slideX(),
                    const SizedBox(height: 30),

                    // Resend Timer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Didn't receive email? ",
                          style: TextStyle(color: Colors.white70),
                        ),
                        if (_canResend)
                          GestureDetector(
                            onTap: _resendEmail,
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
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : CustomButton(
                            text: "Back to Sign In",
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ).animate().fadeIn(delay: 250.ms).slideY(),
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
