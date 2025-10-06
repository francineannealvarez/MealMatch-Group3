import 'package:flutter/material.dart';
import 'getstarted_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  // Navigate back to the previous screen
  void handleBack(BuildContext context) {
    Navigator.pop(context);
  }

  // Navigate to GetStartedScreen
  void handleGetStarted(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GetStartedScreen()),
    );
  }

  // Placeholder for Google Sign-In
  void handleGoogleSignIn() {
    print('Continue with Google clicked');
    // TODO: Implement Google Sign-In backend
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFD8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => handleBack(context),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Welcome Text
                      Column(
                        children: const [
                          Text(
                            'Welcome!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "We're happy to have you here.",
                            style: TextStyle(color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Let's customize MealMatch for your goals.",
                            style: TextStyle(color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      // Get Started Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => handleGetStarted(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF39321),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // OR Text
                      const Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Continue with Google Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: handleGoogleSignIn,
                          icon: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                            height: 20,
                            width: 20,
                          ),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Text(
                              'Continue with Google',
                              style: TextStyle(fontSize: 18, color: Colors.black),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
