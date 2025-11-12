import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF4E6), Color(0xFFE8F5D8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(height: 40),

                  Column(
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'System',
                          ),
                          children: [
                            TextSpan(
                              text: 'Meal',
                              style: TextStyle(
                                fontFamily: 'MuseoModerno',
                                color: Color(0xFFF39321),
                              ),
                            ),
                            TextSpan(
                              text: 'Match',
                              style: TextStyle(
                                fontFamily: 'MuseoModerno',
                                color: Color(0xFF7FA85C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Find Recipes. Track Calories.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B9D83),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/images/greetscreen.png',
                        height: 280,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF39321), Color(0xFF7FA85C)],
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => SignUpScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LoginScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Color(0xFF8B9D83),
                              width: 2,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF8B9D83),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
