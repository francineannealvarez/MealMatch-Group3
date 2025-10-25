import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade300, width: 1.5),
          ),
          child: SingleChildScrollView(
            child: const Text('''
Welcome to MealMatch!
Last Updated: 10/08/2025

Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your information when you use our mobile application, MealMatch (the “App”).

By using MealMatch, you agree to the collection and use of information as described in this policy.

I. Information We Collect
We collect information to provide and improve the App’s services. The types of data we collect include:

Personal Information
When you create an account, we may collect:
- Your name or username
- Email address
- Profile picture (if uploaded)
- Other optional details (e.g., bio or preferences)

Usage Data
When you use the App, we automatically collect:
- Device information (model, operating system, app version)
- Log data (IP address, time, and usage activity)
- Clicks, views, and recipe interactions (for analytics)

Recipe and Nutrition Data
When you use features like ingredient-based searches, calorie tracking, or community sharing, we collect:
- Ingredients you input
- Recipes you post, rate, or save
- Nutrition and calorie information you track
This data helps improve recommendations and personalize your experience.

Cookies and Similar Technologies
We may use cookies or local storage to:
- Keep you signed in
- Save preferences
- Measure app performance
You can disable cookies in your device settings, but some features may not work properly.

II. How We Use Your Information
We use the collected data to:
- Provide and improve our services and user experience
- Personalize recipe suggestions based on your ingredients
- Track your calorie intake and progress
- Enable community features (posting, rating, and saving recipes)
- Send optional notifications or updates (you can opt out anytime)
- Maintain security and prevent fraud
- Analyze usage trends for improvement

III. Sharing and Disclosure
We do not sell or rent your personal data to third parties.
However, we may share information in the following cases:

Service Providers
We may use third-party tools to help us operate the App, such as:
- Analytics tools (e.g., Google Analytics for Firebase)
- Cloud storage and database providers
- Crash reporting and bug tracking tools
These providers only access data as needed to perform their functions and must comply with privacy regulations.

Legal Requirements
We may disclose your information if required by law or to:
- Comply with legal obligations
- Protect our rights, property, and safety
- Prevent fraud or misuse

Community Sharing
When you post recipes or comments, your username, profile, and recipe content may be visible to other users.

IV. Data Retention
We keep your personal information only as long as necessary to:
- Provide our services
- Fulfill legal or regulatory requirements
- Resolve disputes and enforce agreements
You can request deletion of your account and data at any time (see Section 8).

V. Data Security
We use reasonable technical and organizational measures to protect your data from unauthorized access, loss, or misuse.
However, no system is 100% secure, and we cannot guarantee absolute security.

VI. Children’s Privacy
MealMatch is not directed at children under 13 years old.
If we discover that a child under 13 has provided personal data, we will promptly delete it.
Parents or guardians may contact us to request data removal.

VII. Your Rights and Choices
You have the right to:
- Access the data we hold about you
- Request correction of inaccurate data
- Request deletion of your account and personal data
- Opt out of analytics or promotional notifications
To exercise these rights, contact us at group3@gmail.com.

VIII. International Data Transfers
If you access MealMatch from outside the Philippines, note that your data may be transferred and processed in countries where data protection laws may differ.

IX. Updates to This Policy
We may update this Privacy Policy from time to time.
If we make significant changes, we’ll notify you via the App or by email.
The updated version will always include the “Last Updated” date at the top.

X. Contact Us
If you have questions or concerns about these Terms or MealMatch, please contact us at:
📧 group3@gmail.com
📍 Alangilangan, Batangas City
              ''', style: TextStyle(fontSize: 14, height: 1.5)),
          ),
        ),
      ),
    );
  }
}
