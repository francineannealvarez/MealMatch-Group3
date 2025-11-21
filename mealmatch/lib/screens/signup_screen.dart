import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mealmatch/screens/homepage_screen.dart';
import '../services/auth_service.dart';
import 'getstarted_screen.dart';
import 'dart:async';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isVerificationMode = false;
  Timer? _verificationCheckTimer;

  // Resend cooldown timer
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _verificationCheckTimer?.cancel();
    _cooldownTimer?.cancel();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ✅ NEW: Start resend cooldown
  void _startResendCooldown() {
    setState(() {
      _resendCooldown = 60; // 60 seconds cooldown
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() {
          _resendCooldown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  // Navigate back to the previous screen
  void handleBack(BuildContext context) async {
    if (_isVerificationMode) {
      // ✅ If user goes back from verification, delete the unverified account
      final shouldGoBack = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Cancel Sign Up?'),
          content: Text(
            'Your email verification is incomplete. Going back will cancel your sign up.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Go Back', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (shouldGoBack == true) {
        // Delete the unverified account
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && !user.emailVerified) {
            await user.delete();
            print('🗑️ Deleted unverified account: ${user.email}');
          }
        } catch (e) {
          print('Error deleting unverified account: $e');
        }

        setState(() {
          _isVerificationMode = false;
        });
        _verificationCheckTimer?.cancel();
        _cooldownTimer?.cancel();
      }
    } else {
      Navigator.pop(context);
    }
  }

  // Placeholder for Google Sign-In
  void handleGoogleSignIn(BuildContext context) async {
    print('Continue with Google clicked');

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final UserCredential? userCredential =
          await AuthService.signInWithGoogle();

      // Close the loading indicator
      Navigator.of(context).pop();

      if (userCredential != null) {
        final user = userCredential.user;
        print("Signed in as ${user?.displayName}, ${user?.email}");

        // ✅ Check if it's a new user
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        if (isNewUser) {
          // Save data in Firestore (optional)
          // then navigate to GetStartedScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => GetStartedScreen(
                email: user?.email ?? '',
                isGoogleUser: true,
              ),
            ),
          );
        } else {
          // Returning user → Home
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        // ❌ Sign-in failed or canceled
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google sign-in canceled or failed")),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      print("Error during Google Sign-In: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xFFFFF5CF), // ✅ Solid background color
        ),
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: _isVerificationMode
                  ? _buildVerificationScreen(context)
                  : _buildMainContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 24, right: 38, bottom: 20, left: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => handleBack(context),
            ),
          ),
          Text(
            "Sign Up",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green[400],
            ),
          ),
        ],
      ),
    );
  }

  // Verification waiting screen
  Widget _buildVerificationScreen(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_unread, size: 100, color: Color(0xFF5EA140)),
            SizedBox(height: 30),
            Text(
              "Verify Your Email",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              "We've sent a verification link to:",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              emailController.text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5EA140),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFFFB74D)),
              ),
              child: Column(
                children: [
                  Text(
                    "📧 Check your email inbox",
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Click the verification link in the email",
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Then come back here to continue",
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _checkEmailVerification(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5EA140),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  "I've Verified My Email",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _resendCooldown > 0
                    ? null // ✅ Disable button during cooldown
                    : () => _resendVerificationEmail(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _resendCooldown > 0
                        ? Colors.grey.shade300
                        : Color(0xFF5EA140),
                  ),
                  backgroundColor: _resendCooldown > 0
                      ? Colors.grey.shade100
                      : Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _resendCooldown > 0
                      ? "Resend in $_resendCooldown seconds" // ✅ Show countdown
                      : "Resend Verification Email",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: _resendCooldown > 0
                        ? Colors.grey.shade500
                        : Color(0xFF5EA140),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Didn't receive the email? Check your spam folder",
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Check if email is verified
  Future<void> _checkEmailVerification(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Reload user to get latest verification status
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      Navigator.of(context).pop(); // Close loading dialog

      if (user?.emailVerified == true) {
        // ✅ Email verified! Proceed to GetStarted
        _cooldownTimer?.cancel(); // Stop countdown

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified successfully!'),
            backgroundColor: Color(0xFF5EA140),
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GetStartedScreen(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            ),
          ),
        );
      } else {
        // ❌ Not verified yet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please verify your email first by clicking the link in your inbox',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking verification: $e')),
      );
    }
  }

  // Resend verification email with cooldown
  Future<void> _resendVerificationEmail(BuildContext context) async {
    // ✅ Check if still in cooldown
    if (_resendCooldown > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please wait $_resendCooldown seconds before resending',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        // ✅ Start cooldown after successful send
        _startResendCooldown();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Check your inbox'),
            backgroundColor: Color(0xFF5EA140),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Error sending email';

      if (e.code == 'too-many-requests') {
        message = 'Too many requests. Please wait a few minutes and try again.';
        // ✅ If Firebase blocks, set longer cooldown
        setState(() {
          _resendCooldown = 300; // 5 minutes
        });
        _startResendCooldown();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildMainContent(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(top: 100, left: 40, right: 40),
        child: Column(
          children: [
            _buildBrandTitle(),
            SizedBox(height: 30),
            _buildSignUpForm(context),
            SizedBox(height: 16),
            _buildLoginPrompt(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandTitle() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "Meal",
            style: TextStyle(
              fontFamily: 'MuseoModerno',
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF48011),
            ),
          ),
          TextSpan(
            text: "Match",
            style: TextStyle(
              fontFamily: 'MuseoModerno',
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5EA140),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSignUpForm(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFFFB74D), width: 1),
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Email",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
              decoration: InputDecoration(
                hintText: "example@123.com",
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide(color: Color(0xFF5EA140), width: 2),
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Password",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            TextFormField(
              controller: passwordController,
              obscureText: !_isPasswordVisible,
              validator: _validatePassword,
              decoration: InputDecoration(
                hintText: "Password",
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide(color: Color(0xFF5EA140), width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey.shade600,
                    size: 15,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Confirm Password",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            TextFormField(
              controller: confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              validator: _validateConfirmPassword,
              decoration: InputDecoration(
                hintText: "Password",
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Color(0xFF5EA140), width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey.shade600,
                    size: 15,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 14),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _onCreateAccountPressed(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5EA140),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    "Continue",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ),
            SizedBox(height: 6),
            _buildDividerSection(),
            SizedBox(height: 4),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => handleGoogleSignIn(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.login,
                            size: 20,
                            color: Colors.black,
                          );
                        },
                      ),
                      SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Sign up with Google',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  Widget _buildDividerSection() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
            margin: EdgeInsets.only(bottom: 6),
          ),
        ),
        SizedBox(width: 10),
        Text("or", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
            margin: EdgeInsets.only(bottom: 6),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Have an account?  ",
          style: TextStyle(fontSize: 15, color: Colors.black),
        ),
        GestureDetector(
          onTap: () => _onLoginTapped(context),
          child: Text(
            "Log in",
            style: TextStyle(
              fontSize: 15,
              color: Colors.indigoAccent,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    if (value?.isEmpty == true) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value?.isEmpty == true) {
      return 'Password is required';
    }
    if (value!.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value?.isEmpty == true) {
      return 'Confirm password is required';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Create temp account and send verification email
  Future<void> _onCreateAccountPressed(BuildContext context) async {
    if (_formKey.currentState?.validate() != true) return;

    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // ✅ Check if email is already in use
      try {
        final signInMethods = await FirebaseAuth.instance
            .fetchSignInMethodsForEmail(email);

        if (signInMethods.isNotEmpty) {
          // Email already exists
          Navigator.of(context).pop();

          // Check if it's an unverified account
          try {
            final userCred = await FirebaseAuth.instance
                .signInWithEmailAndPassword(email: email, password: password);

            if (userCred.user != null && !userCred.user!.emailVerified) {
              // ✅ Same unverified account - allow resending verification
              setState(() {
                _isVerificationMode = true;
              });

              await userCred.user!.sendEmailVerification();
              _startResendCooldown();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Verification email resent! Please check your inbox',
                  ),
                  backgroundColor: Color(0xFF5EA140),
                ),
              );
              return;
            } else if (userCred.user != null && userCred.user!.emailVerified) {
              // ✅ Verified account exists
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'This email is already registered. Please log in.',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
              await FirebaseAuth.instance.signOut();
              return;
            }
          } catch (e) {
            // Wrong password or other error
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'This email is already registered. If you forgot your password, use "Forgot Password" on the login screen.',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
            return;
          }
        }
      } catch (e) {
        print('Error checking email: $e');
      }

      // ✅ Create NEW Firebase Auth account
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Send verification email
      await userCredential.user?.sendEmailVerification();

      Navigator.of(context).pop(); // Close loading

      // Switch to verification screen
      setState(() {
        _isVerificationMode = true;
      });

      _startResendCooldown();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent! Please check your inbox'),
          backgroundColor: Color(0xFF5EA140),
        ),
      );
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); // Close loading

      String message = 'Sign up failed.';
      if (e.code == 'email-already-in-use') {
        message =
            'This email is already registered. Please log in or use "Forgot Password".';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /*void _onGoogleLoginPressed(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Choose Google account'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          body: const Center(child: Text('Google Sign-In UI goes here')),
        ),
      ),
    );
  }*/

  void _onLoginTapped(BuildContext context) {
    Navigator.of(context).pushNamed('/login');
  }
}
