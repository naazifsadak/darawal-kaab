import 'package:flutter/material.dart';
import '../widgets/background_scaffold.dart';
import '../widgets/glass_container.dart';
import '../widgets/custom_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'auth/sign_in_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          children: [
            const Spacer(),
            // Logo / Icon
            GlassContainer(
                  borderRadius: BorderRadius.circular(30),
                  padding: const EdgeInsets.all(30),
                  child: const Icon(
                    Icons.directions_car_filled_outlined,
                    size: 60,
                    color: Colors.white,
                  ),
                )
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .fade(duration: 600.ms),
            const SizedBox(height: 40),
            // Title
            const Text(
                  "Drive Smarter with\nDarawal-Kaab",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                )
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms)
                .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
            const SizedBox(height: 20),
            // Subtitle
            Text(
                  "Find the best services, connect with other drivers, and navigate your city with ease.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[300],
                    height: 1.5,
                  ),
                )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
            const Spacer(),
            // Get Started Button
            CustomButton(
                  text: "Get Started",
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SignInScreen(),
                      ),
                    );
                  },
                )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: 0.4, end: 0, curve: Curves.easeOutBack),
            const SizedBox(height: 20),
            // Footer text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "By continuing, you agree to our Terms & Privacy Policy",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
