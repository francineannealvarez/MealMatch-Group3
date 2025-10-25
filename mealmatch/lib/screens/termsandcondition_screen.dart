import 'package:flutter/material.dart';

class TermsConditionScreen extends StatelessWidget {
  const TermsConditionScreen({super.key});

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
          'Terms of Service',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: const Text('''
Welcome to MealMatch!
Last Updated: 10/08/2025

Please read these Terms of Service carefully before using the MealMatch mobile application operated by Group 3.

By downloading, accessing, or using MealMatch, you agree to be bound by these Terms.

I. Overview
MealMatch is a mobile application designed to help users:
- Find recipes based on ingredients they already have.
- Track calorie intake through built-in nutritional data.
- Share, rate, and save personal recipes with the MealMatch community.
- Promote sustainable eating and minimize food waste in support of Zero Hunger and Responsible Consumption goals.

MealMatch aims to provide an enjoyable, educational, and health-conscious experience — but should not be considered a substitute for professional dietary or medical advice.

II. Eligibility
You must be at least 13 years old to use MealMatch.
If you are under 18, you must have the permission and supervision of a parent or guardian.

III. Account Registration
To access certain features (such as posting or saving recipes), you may need to create an account.
You agree to:
- Provide accurate, current, and complete information.
- Keep your login credentials secure.
- Be responsible for all activity under your account.
We reserve the right to suspend or terminate accounts that violate these Terms or engage in abusive, fraudulent, or harmful behavior.

IV. User-Generated Content
MealMatch allows users to post, share, and rate recipes (“User Content”).
By submitting User Content, you grant us a non-exclusive, royalty-free, worldwide, transferable license to use, display, modify, and distribute your content within the App and its promotional materials.
You represent and warrant that:
- You own or have the right to share the content you post.
- Your content does not violate any copyright, trademark, or privacy rights.
- Your content is appropriate and not offensive, harmful, or misleading.
We reserve the right to review, moderate, or remove any content that violates these Terms.

V. Health and Nutrition Disclaimer
MealMatch provides nutritional and calorie data for informational purposes only.
We do not guarantee the accuracy, completeness, or reliability of this information.
Always consult a qualified healthcare or nutrition professional for dietary advice.
You are responsible for your own health choices and meal decisions.

VI. Acceptable Use
You agree not to:
- Use the App for unlawful or harmful purposes.
- Upload viruses, malware, or harmful code.
- Harass, spam, or defame other users.
- Copy, scrape, or reproduce the App’s data or features for commercial use without permission.
Violation of these rules may result in account suspension or legal action.

VII. Intellectual Property
All content and materials in MealMatch — including text, graphics, logos, recipes (not user-submitted), and software — are the property of Group 3 or its authors.
You may not reproduce, modify, or distribute them without our written consent.

VIII. Privacy
Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your data.

IX. Updates and Changes
We may update or modify MealMatch and these Terms at any time.
Continued use of the App after changes take effect means you accept the revised Terms.

X. Limitation of Liability
MealMatch is provided “as is” and “as available.”
We make no guarantees about uninterrupted or error-free operation.
To the fullest extent permitted by law, we are not liable for any damages, losses, or injuries arising from your use of the App or reliance on its content.

XI. Termination
We may suspend or terminate your access to MealMatch at any time if you violate these Terms or engage in misuse of the App.
Upon termination, your right to use the App will immediately end.

XII. Governing Law
These Terms are governed by and interpreted in accordance with the laws of the Republic of the Philippines, without regard to conflict of law principles.

XIII. Contact Us
If you have questions or concerns about these Terms or MealMatch, please contact us at:
📧 group3@gmail.com
📍 Alangilangan, Batangas City
                    ''', style: TextStyle(fontSize: 14, height: 1.5)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
