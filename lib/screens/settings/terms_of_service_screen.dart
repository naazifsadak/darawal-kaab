import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:darawalkaab/l10n/app_localizations.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F7FA);
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey[400]! : Colors.grey[700]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.termsOfService,
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!isDark)
                const BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tusiye App Terms of Service",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Effective Date: June 08, 2026",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Divider(height: 32, thickness: 1),
              
              _buildSectionContent(
                "Welcome to Tusiye App! These Terms of Service (\"Terms\") govern your access to and use of our mobile application (the \"App\" or \"Service\") provided by Tusiye App Team (\"we,\" \"us,\" or \"our\").",
                subTextColor,
              ),
              _buildSectionContent(
                "Please read these Terms carefully before using the Service. By downloading, accessing, or using the Service, you agree to be bound by these Terms and our Privacy Policy. If you do not agree to these Terms, please do not download or use the App.",
                subTextColor,
              ),

              _buildSectionTitle("1. Description of Service", textColor),
              _buildSectionContent(
                "Tusiye App is a community-driven driver assistant app designed to provide real-time road condition updates (\"Jump Posts\"), map navigation, traffic updates, post-accident reporting, and connections to nearby automotive services such as gas stations and repair shops. We grant you a limited, non-exclusive, non-transferable, revocable license to use the App solely for your personal, non-commercial purposes.",
                subTextColor,
              ),

              _buildSectionTitle("2. User Accounts & Registration", textColor),
              _buildSectionContent(
                "To access most features of the App, you must register for an account using your email address, full name, phone number, and a secure password. You agree to:\n"
                "• Provide accurate, current, and complete information during registration.\n"
                "• Keep your password secure and confidential.\n"
                "• Promptly notify us of any unauthorized use or security breach of your account.\n"
                "• Accept responsibility for all activities that occur under your account.",
                subTextColor,
              ),

              _buildSectionTitle("3. User-Generated Content & Code of Conduct", textColor),
              _buildSectionContent(
                "You are solely responsible for the information, descriptions, photos, and videos you publish in the App (such as road hazards, street condition reports, comments, and profile edits). By posting content, you represent and warrant that:\n"
                "• You own or have the necessary rights to use and share the content.\n"
                "• The content is accurate, truthful, and helpful to other road users.\n"
                "• The content does not violate any laws or third-party rights (including copyright, trademark, or privacy rights).\n\n"
                "You agree not to post any content that is offensive, harmful, fraudulent, harassing, defamatory, or otherwise objectionable. We reserve the right, but are not obligated, to monitor, edit, or remove content that violates these Terms or is otherwise harmful to the community.",
                subTextColor,
              ),

              _buildSectionTitle("4. Privacy Policy & Data Use", textColor),
              _buildSectionContent(
                "Your privacy is important to us. Please refer to our Privacy Policy, which explains how we collect, use, and process your personal and location data when you use the App. By using Tusiye App, you consent to our collection and use of data as described in the Privacy Policy.",
                subTextColor,
              ),

              _buildSectionTitle("5. Third-Party Integrations & Services", textColor),
              _buildSectionContent(
                "The App integrates third-party tools and platforms to deliver its services, including Supabase (for authentication, database, and media storage) and Google Maps SDK (for rendering maps and routes). Your use of these features is subject to the respective terms and privacy policies of these third-party providers. We are not responsible for the performance, content, or safety of any third-party services.",
                subTextColor,
              ),

              _buildSectionTitle("6. Disclaimer of Warranties", textColor),
              _buildSectionContent(
                "The App and its content are provided on an \"as is\" and \"as available\" basis without warranties of any kind, either express or implied, including but not limited to warranties of accuracy, completeness, reliability, safety, or fitness for a particular purpose.\n\n"
                "We do not warrant that the App will be uninterrupted, error-free, or free of viruses. Road conditions and nearby service data are community-reported and third-party sourced, and you should always prioritize safe driving and follow local traffic laws.",
                subTextColor,
              ),

              _buildSectionTitle("7. Limitation of Liability", textColor),
              _buildSectionContent(
                "To the maximum extent permitted by applicable law, Tusiye App Team, its creators, and affiliates shall not be liable for any direct, indirect, incidental, special, consequential, or exemplary damages, including but not limited to damages for loss of profits, goodwill, data, vehicular accidents, personal injuries, or other losses resulting from:\n"
                "• Your use or inability to use the Service.\n"
                "• Relying on road condition updates, maps, or nearby service locations.\n"
                "• Unauthorized access to or alteration of your transmissions or data.\n"
                "• Conduct or content of any third party in the Service.",
                subTextColor,
              ),

              _buildSectionTitle("8. Account Deletion & Termination", textColor),
              _buildSectionContent(
                "We reserve the right to suspend or terminate your account and access to the Service at our sole discretion, without notice, for conduct that we believe violates these Terms or is harmful to other users or the App.\n\n"
                "You may delete your account at any time by navigating to Settings > Account Information > Delete Account inside the App, or by contacting us at tusiyeapp@gmail.com.",
                subTextColor,
              ),

              _buildSectionTitle("9. Changes to Terms of Service", textColor),
              _buildSectionContent(
                "We may modify these Terms from time to time. We will notify you of changes by posting the updated Terms on this screen and revising the \"Effective Date\" at the top. Your continued use of the App after changes are posted constitutes your acceptance of the updated Terms.",
                subTextColor,
              ),

              _buildSectionTitle("10. Governing Law", textColor),
              _buildSectionContent(
                "These Terms and your use of the Service shall be governed by and construed in accordance with the laws applicable to the developer's jurisdiction, without regard to its conflict of law principles.",
                subTextColor,
              ),

              _buildSectionTitle("11. Contact Us", textColor),
              _buildSectionContent(
                "If you have any questions or feedback regarding these Terms, please contact us at:\n\n"
                "• Email: tusiyeapp@gmail.com\n"
                "• Developer Name: Tusiye App Team",
                subTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        content,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: textColor,
          height: 1.6,
        ),
      ),
    );
  }
}
