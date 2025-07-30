import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  String _appVersion = '';
  String _appName = '';

  @override
  void initState() {
    super.initState();
    _getAppInfo();
  }

  Future<void> _getAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _appName = packageInfo.appName;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
        _appName = 'SMS Transaction Analyzer';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        title: const Text(
          'About Us',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo and Info
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1E33),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version $_appVersion',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your Personal Finance Tracker',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App Description
            _buildSection(
              'About the App',
              'SMS Transaction Analyzer is a comprehensive personal finance tracking application that automatically analyzes your SMS transactions from mobile money services like EVC and eDahab. The app provides detailed insights into your spending patterns, budget management, and financial analytics.',
            ),
            const SizedBox(height: 20),

            // Features
            _buildSection(
              'Key Features',
              '• Automatic SMS transaction parsing\n'
              '• Real-time spending analytics\n'
              '• Budget tracking and alerts\n'
              '• Category-based expense breakdown\n'
              '• Secure data encryption\n'
              '• Cross-device synchronization\n'
              '• Detailed transaction history',
            ),
            const SizedBox(height: 20),

            // Privacy Policy
            _buildSection(
              'Privacy Policy',
              'Your privacy is our top priority. We collect and process your SMS data locally on your device to analyze transactions. All data is encrypted before being stored in our secure cloud database. We do not share your personal information with third parties without your explicit consent.',
            ),
            const SizedBox(height: 20),

            // Terms of Service
            _buildSection(
              'Terms of Service',
              'By using this app, you agree to:\n\n'
              '• Provide accurate information\n'
              '• Maintain the security of your account\n'
              '• Use the app for lawful purposes only\n'
              '• Accept responsibility for your financial decisions\n'
              '• Comply with all applicable laws and regulations',
            ),
            const SizedBox(height: 20),

            // Data Security
            _buildSection(
              'Data Security',
              'We implement industry-standard security measures to protect your data:\n\n'
              '• End-to-end encryption for all sensitive data\n'
              '• Secure cloud storage with Firebase\n'
              '• Local data processing for privacy\n'
              '• Regular security audits and updates\n'
              '• Compliance with data protection regulations',
            ),
            const SizedBox(height: 20),

            // Contact Information
            _buildSection(
              'Contact Us',
              'If you have any questions, concerns, or feedback about our app, please contact us:\n\n'
              'Email: support@smstracker.com\n'
              'Support Hours: Monday - Friday, 9:00 AM - 6:00 PM\n'
              'Response Time: Within 24 hours',
            ),
            const SizedBox(height: 20),

            // Developer Information
            _buildSection(
              'Developer Information',
              'SMS Transaction Analyzer is developed with ❤️ by a dedicated team focused on creating innovative financial technology solutions. We are committed to providing users with secure, reliable, and user-friendly financial management tools.',
            ),
            const SizedBox(height: 20),

            // Legal Notice
            _buildSection(
              'Legal Notice',
              'This app is provided "as is" without warranties of any kind. The developers are not responsible for any financial decisions made based on the app\'s analysis. Users should always verify information and consult with financial advisors for important financial decisions.',
            ),
            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                '© 2024 SMS Transaction Analyzer. All rights reserved.',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
} 