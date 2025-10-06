import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void handleBack() {
    Navigator.pop(context); // Navigate back to greet/welcome screen
  }

  void handleLogin() {
    print('Login with: ${emailController.text}, ${passwordController.text}');
    // TODO: Connect to backend
  }

  void handleGoogleLogin() {
    print('Continue with Google');
    // TODO: Connect to Google Sign-In backend
  }

  void handleForgotPassword() {
    print('Forgot password clicked');
    // TODO: Implement forgot password flow
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5EFD8),
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
                      icon: Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: handleBack,
                    ),
                  ),
                  Center(
                    child: Text(
                      'Log In',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  children: [
                    // Logo
                    SizedBox(
                      width: 280,
                      height: 60,
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'System',
                            letterSpacing: -1,
                          ),
                          children: [
                            TextSpan(text: 'Meal', style: TextStyle(color: Color(0xFFF39321))),
                            TextSpan(text: 'Match', style: TextStyle(color: Color(0xFF6B9B4A))),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 40),

                    // Email Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email Address', style: TextStyle(color: Colors.black, fontSize: 14)),
                        SizedBox(height: 8),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide: BorderSide(color: Color(0xFF6B9B4A), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Password Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Password', style: TextStyle(color: Colors.black, fontSize: 14)),
                        SizedBox(height: 8),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide: BorderSide(color: Color(0xFF6B9B4A), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF6B9B4A),
                          padding: EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        ),
                        child: Text('Log In', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),

                    SizedBox(height: 12),

                    // Forgot Password
                    TextButton(
                      onPressed: handleForgotPassword,
                      child: Text('Forgot password?', style: TextStyle(color: Colors.black, fontSize: 14)),
                    ),

                    SizedBox(height: 16),

                    // OR Divider
                    Text('OR', style: TextStyle(color: Colors.black)),

                    SizedBox(height: 16),

                    // Continue with Google Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: handleGoogleLogin,
                        icon: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                          width: 20,
                          height: 20,
                        ),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Text('Continue with Google', style: TextStyle(fontSize: 18, color: Colors.black)),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
