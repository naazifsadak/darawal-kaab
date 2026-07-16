import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/background_scaffold.dart';
import '../widgets/glass_container.dart';
import '../widgets/custom_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:darawalkaab/l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import 'auth/sign_in_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings/privacy_policy_screen.dart';
import 'settings/terms_of_service_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _showLanguageBottomSheet(
    BuildContext context,
    SettingsProvider settings,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Language",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(context, settings, 'English', 'en', '🇺🇸'),
              _buildLanguageOption(
                context,
                settings,
                'Somali',
                'so',
                '🇸🇴',
                isEnabled: false,
              ),
              _buildLanguageOption(context, settings, 'Arabic', 'ar', '🇸🇦'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    SettingsProvider settings,
    String name,
    String code,
    String flag, {
    bool isEnabled = true,
  }) {
    final isSelected = settings.locale.languageCode == code;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(
        name,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isEnabled
              ? (isSelected ? Colors.blue : Colors.black)
              : Colors.grey,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        if (!isEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name language will be coming soon!'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        settings.setLocale(Locale(code));
        Navigator.pop(context);
      },
    );
  }

  void _showTermsPrivacyBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomSheetBgColor = isDark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: bottomSheetBgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Legal Agreements",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please review the Terms of Service and Privacy Policy for using Tusiye App.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.description_outlined, color: Colors.blue),
                ),
                title: Text(
                  AppLocalizations.of(context)!.termsOfService,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsOfServiceScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.privacy_tip_outlined, color: Colors.blue),
                ),
                title: Text(
                  AppLocalizations.of(context)!.privacyPolicy,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final currentLanguageCode = settings.locale.languageCode;
    String currentFlag = '🇺🇸';
    String currentLangName = 'ENG';

    if (currentLanguageCode == 'so') {
      currentFlag = '🇸🇴';
      currentLangName = 'SOM';
    } else if (currentLanguageCode == 'ar') {
      currentFlag = '🇸🇦';
      currentLangName = 'عربي';
    }

    return BackgroundScaffold(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      children: [
                        // Language Selector at the Top Right
                        Align(
                          alignment: Alignment.topRight,
                          child:
                              GestureDetector(
                                    onTap: () =>
                                        _showLanguageBottomSheet(context, settings),
                                    child: GlassContainer(
                                      borderRadius: BorderRadius.circular(20),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            currentFlag,
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            currentLangName,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 500.ms)
                                  .slideY(begin: -0.2, end: 0),
                        ),
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
                        Text(
                              AppLocalizations.of(context)!.welcomeTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
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
                              AppLocalizations.of(context)!.welcomeSubtitle,
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
                              text: AppLocalizations.of(context)!.getStarted,
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
                          child: GestureDetector(
                            onTap: () => _showTermsPrivacyBottomSheet(context),
                            child: Text(
                              AppLocalizations.of(context)!.termsPrivacy,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.grey[600],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
