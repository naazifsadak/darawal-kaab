import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/background_scaffold.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../main_screen.dart';
import '../../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // Added for future use
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        throw 'Please fill in all required fields';
      }

      final credential = await _authService.signUp(
        email: email,
        password: password,
      );

      if (credential != null && credential.user != null) {
        await credential.user!.updateDisplayName(name);
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
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
              // Lock Icon
              const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white12,
                    child: Icon(
                      Icons.person_add,
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
                          "Create Account",
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
                          "Join us and start driving smarter",
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 400.ms)
                        .slideX(begin: -0.2, end: 0),
                    const SizedBox(height: 30),

                    CustomTextField(
                          controller: _nameController,
                          hintText: "Full Name",
                          prefixIcon: Icons.person_outline,
                        )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    CustomTextField(
                          controller: _phoneController,
                          hintText: "Phone Number",
                          prefixIcon: Icons.phone_iphone,
                          keyboardType: TextInputType.phone,
                        )
                        .animate()
                        .fadeIn(delay: 250.ms, duration: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    CustomTextField(
                          controller: _emailController,
                          hintText: "Email Address",
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    CustomTextField(
                          controller: _passwordController,
                          hintText: "Password",
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          suffixIcon: const Icon(
                            Icons.visibility_off_outlined,
                            color: Colors.white70,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 350.ms, duration: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 30),

                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : CustomButton(text: "Sign Up", onPressed: _signUp)
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 400.ms)
                              .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.white70),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
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
