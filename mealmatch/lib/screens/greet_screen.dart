import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2D5016), // #2d5016
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                SizedBox(
                  width: 350,
                  height: 80,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'System',
                      ),
                      children: [
                        TextSpan(
                          text: 'Meal',
                          style: TextStyle(color: Color(0xFFF39321)),
                        ),
                        TextSpan(
                          text: 'Match',
                          style: TextStyle(color: Color(0xFF9DB88A)),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 40),

                // Features
                Column(
                  children: [
                    featureItem(
                      icon: Icons.restaurant_menu,
                      bgColor: Colors.white,
                      fgColor: Color(0xFFF39321),
                      label: 'Find Recipes',
                    ),
                    SizedBox(height: 16),
                    featureItem(
                      icon: Icons.local_fire_department,
                      bgColor: Colors.white,
                      fgColor: Color(0xFFF39321),
                      label: 'Track Calories',
                    ),
                  ],
                ),

                SizedBox(height: 40),

                // Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SignUpScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF39321),
                          padding: EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: Text(
                          'Sign up',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
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
                          side: BorderSide(color: Colors.white, width: 2),
                          padding: EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                        child: Text(
                          'Log In',
                          style: TextStyle(fontSize: 18, color: Colors.white),
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
    );
  }

  Widget featureItem({
    required IconData icon,
    required Color bgColor,
    required Color fgColor,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(icon, color: fgColor, size: 32),
        ),
        SizedBox(width: 16),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 20)),
      ],
    );
  }
}
