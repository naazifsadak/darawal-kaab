import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/background_scaffold.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'sign_up_screen.dart';
import 'forgot_password_screen.dart';
import 'email_verification_screen.dart';
import '../main_screen.dart';
import '../../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (email.isEmpty || password.isEmpty) {
        throw 'Please enter both email and password';
      }

      await _authService.signIn(email: email, password: password);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } on supabase.AuthException catch (e) {
      if (mounted) {
        final message = e.message;
        if (message.toLowerCase().contains('email not confirmed') ||
            message.toLowerCase().contains('confirm your email') ||
            message.toLowerCase().contains('email_not_confirmed')) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(email: email),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please confirm your email address to sign in."),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
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
              // Lock Icon
              const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white12,
                    child: Icon(
                      Icons.lock_person,
                      size: 40,
                      color: Colors.white,
                    ),
                  )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .fade(duration: 600.ms),
              const SizedBox(height: 30),

              // Glass Form
              GlassContainer(
                child: Column(
                  children: [
                    const Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms)
                        .slideX(begin: -0.2, end: 0),
                    const SizedBox(height: 10),
                    const Text(
                          "Sign in to continue your journey",
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 400.ms)
                        .slideX(begin: -0.2, end: 0),
                    const SizedBox(height: 30),

                    CustomTextField(
                          controller: _emailController,
                          hintText: "Email Address",
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    CustomTextField(
                          controller: _passwordController,
                          hintText: "Password",
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 250.ms, duration: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                    const SizedBox(height: 20),

                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : CustomButton(text: "Sign In", onPressed: _signIn)
                              .animate()
                              .fadeIn(delay: 350.ms, duration: 400.ms)
                              .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.white70),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
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
