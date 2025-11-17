import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mealmatch/screens/homepage_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // ignore: unused_field
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isPasswordVisible = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _initializeLogin();
  }

  // ✅ UPDATED: Initialize login check
  Future<void> _initializeLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isRemembered = prefs.getBool('remember_me') ?? false;

    // If not remembered, sign out
    if (!isRemembered) {
      await _firebaseService.signOut();
      return;
    }

    final currentUser = _firebaseService.getCurrentUser();
    if (currentUser != null) {
      // Check deletion status
      final status = await _firebaseService.checkDeletionStatus();

      if (status != null && status['isScheduled'] == true) {
        final daysRemaining = status['daysRemaining'] as int?;

        // If expired, delete and show message
        if (daysRemaining != null && daysRemaining <= 0) {
          await _firebaseService.permanentlyDeleteAccount();
          await prefs.setBool('remember_me', false);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Your account has been permanently deleted. Please create a new account.',
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          });
          return;
        }

        // If still within grace period, show dialog on home screen
      }

      // Navigate to home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
    }

    // ✅ Navigate to home (HomePage will show dialog if scheduled)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  // ✅ UPDATED: Handle login using FirebaseService
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // ✅ Use FirebaseService instead of direct Firebase Auth
      final result = await _firebaseService.signInUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result['success'] == true) {
        // ✅ Save remember me preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', _rememberMe);

        // ✅ Navigate to home
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (result['accountDeleted'] == true) {
        // ✅ Account was deleted
        if (mounted) {
          _showDialog(
            'Account Deleted',
            result['message'] ?? 'Your account has been permanently deleted.',
          );
        }
      } else if (result['scheduledForDeletion'] == true) {
        // ✅ Account is scheduled for deletion
        final days = result['daysRemaining'];
        if (mounted) {
          _showCancelDeletionDialog(days);
        }
      } else {
        // ✅ Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Login failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ Add these helper methods sa login screen
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCancelDeletionDialog(int daysRemaining) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Account Scheduled for Deletion'),
        content: Text(
          'Your account will be permanently deleted in $daysRemaining days. '
          'Would you like to cancel the deletion and restore your account?',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Cancel deletion
              final result = await _firebaseService.cancelAccountDeletion();
              Navigator.pop(context);

              if (result['success'] == true) {
                // Account restored - go to home
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account restored successfully!'),
                    ),
                  );
                  Navigator.pushReplacementNamed(context, '/home');
                }
              }
            },
            child: const Text('Cancel Deletion'),
          ),
          TextButton(
            onPressed: () async {
              // User wants to proceed with deletion
              await _firebaseService.signOut();
              Navigator.pop(context);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void handleBack() {
    Navigator.pop(context); // Navigate back to greet/welcome screen
  }

  void handleGoogleLogin(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Call AuthService
    final UserCredential? userCredential = await AuthService.signInWithGoogle();

    // Remove loading screen
    if (mounted) Navigator.of(context).pop();

    if (userCredential != null) {
      // ✅ Check deletion status
      final status = await _firebaseService.checkDeletionStatus();

      if (status != null && status['isScheduled'] == true) {
        final daysRemaining = status['daysRemaining'] as int?;

        // If expired, delete account
        if (daysRemaining != null && daysRemaining <= 0) {
          await _firebaseService.permanentlyDeleteAccount();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Your account has been permanently deleted. Please create a new account.',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        // If within grace period, show dialog
        if (mounted) {
          _showCancelDeletionDialog(daysRemaining ?? 0);
          return;
        }
      }

      // ✅ Navigate to home
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } else {
      // Sign-in failed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google sign-in canceled or failed")),
        );
      }
    }
  }

  void handleForgotPassword() async {
    final TextEditingController emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Enter your registered email',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;

              try {
                await _auth.sendPasswordResetEmail(email: email);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Password reset link sent to $email')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to send reset email')),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF5CF), Color(0xFFCFEBB7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
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
                        'Login',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 560),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: 40),
                            SizedBox(
                              width: 280,
                              height: 60,
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'MuseoModerno',
                                    letterSpacing: -1,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Meal',
                                      style: TextStyle(
                                        color: Color(0xFFF48011),
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Match',
                                      style: TextStyle(
                                        color: Color(0xFF5EA140),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 38),

                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Color(0xFFA7D6A0)),
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    offset: Offset(0, 4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(32),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Email',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: _validateEmail,
                                      decoration: InputDecoration(
                                        hintText: 'example@123.com',
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 18,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFF5EA140),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 12),

                                    Text(
                                      'Password',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: !_isPasswordVisible,
                                      validator: _validatePassword,
                                      decoration: InputDecoration(
                                        hintText: 'Password',
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 18,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFF5EA140),
                                            width: 2,
                                          ),
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
                                              _isPasswordVisible =
                                                  !_isPasswordVisible;
                                            });
                                          },
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 10),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: _rememberMe,
                                              onChanged: (v) => setState(
                                                () => _rememberMe = v ?? false,
                                              ),
                                            ),
                                            Text('Remember me'),
                                          ],
                                        ),
                                        TextButton(
                                          onPressed: handleForgotPassword,
                                          child: Text(
                                            'Forgot password?',
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 12),

                                    Center(
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _handleLogin,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF5EA140),
                                            padding: EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            foregroundColor: Colors.white,
                                          ),
                                          child: Text(
                                            'Login',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: 10),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            margin: EdgeInsets.only(bottom: 6),
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'or',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Container(
                                            height: 1,
                                            margin: EdgeInsets.only(bottom: 6),
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 10),

                                    Center(
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              handleGoogleLogin(context),
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            side: BorderSide(
                                              color: Colors.grey.shade400,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical: 14,
                                              horizontal: 16,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Image.network(
                                                'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                                                width: 20,
                                                height: 20,
                                                fit: BoxFit.contain,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
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
                                                  'Login with Google',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                            ),

                            SizedBox(height: 14),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('No account?  '),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushNamed('/signup');
                                  },
                                  child: Text(
                                    'Sign up',
                                    style: TextStyle(
                                      color: Colors.indigoAccent,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}?$').hasMatch(value)) {
      // Fallback simple validation if pattern above fails
    }
    final simpleEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!simpleEmail.hasMatch(value)) return 'Please enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  /*void _onLoginPressed() {
    if (_formKey.currentState?.validate() != true) return;
    _handleLogin();
  }*/
}
