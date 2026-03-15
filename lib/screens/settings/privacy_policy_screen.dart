import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:darawalkaab/l10n/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFF5F7FA);
    final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.privacyPolicy,
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
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.privacyPolicy,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Last updated: February 09, 2026",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("1. Introduction", textColor),
              _buildSectionContent(
                "Welcome to Darawal-Kaab. We respect your privacy and are committed to protecting your personal data.",
              ),

              _buildSectionTitle("2. Data We Collect", textColor),
              _buildSectionContent(
                "We may collect personal identification information (Name, Email, Phone number) and usage data (Location, Device info) to improve our service.",
              ),

              _buildSectionTitle("3. How We Use Your Data", textColor),
              _buildSectionContent(
                "Your data is used to provide and maintain the Service, notify you about changes, and provide customer support.",
              ),

              _buildSectionTitle("4. Data Security", textColor),
              _buildSectionContent(
                "The security of your data is important to us, but remember that no method of transmission over the Internet is 100% secure.",
              ),

              _buildSectionTitle("5. Contact Us", textColor),
              _buildSectionContent(
                "If you have any questions about this Privacy Policy, please contact us at support@darawalkaab.com.",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.grey[600],
        height: 1.6,
      ),
    );
  }
}
