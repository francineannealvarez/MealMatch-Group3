import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';

// Preferences flow UI

String _stepTitle(int step) {
  switch (step) {
    case 1:
      return 'Preferred Name';
    case 2:
      return 'Select your Main Goal';
    case 3:
      return 'Select your Activity Level';
    case 4:
      return 'Tell us about yourself';
    default:
      return '';
  }
}

String _stepSubtitle(int step) {
  switch (step) {
    case 1:
      return 'What should we call you?';
    case 2:
      return 'Choose at least one goal:';
    case 3:
      return 'Choose what describes you best:';
    case 4:
      return 'Please select which sex we should use to calculate your calorie needs:';
    default:
      return '';
  }
}

class GetStartedScreen extends StatefulWidget {
  final String email;
  final String password;

  const GetStartedScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final FirebaseService firebase_service = FirebaseService();

  int currentStep = 1;
  final int totalSteps = 4;

  // User data
  String name = '';
  List<String> goals = [];
  String activityLevel = '';
  String gender = '';
  String age = '';
  String height = '';
  String weight = '';
  String goalWeight = '';
  // Account is created earlier; only preferences collected here

  bool isLoading = false; // to show a loading indicator

  // --- Navigation ---
  void previousStep() {
    if (currentStep > 1) {
      setState(() {
        currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  bool isNextDisabled() {
    if (currentStep == 1) return name.isEmpty;
    if (currentStep == 2) return goals.isEmpty;
    if (currentStep == 3) return activityLevel.isEmpty;
    if (currentStep == 4)
      return gender.isEmpty ||
          age.isEmpty ||
          height.isEmpty ||
          weight.isEmpty ||
          goalWeight.isEmpty;
    return false;
  }

  // --- Signup function ---
 // --- Handle next button ---
  void handleNext() async {
    if (currentStep < totalSteps) {
      setState(() => currentStep++);
      return;
    }

    // When preferences complete → create Firebase user
    setState(() => isLoading = true);
    try {
      final result = await firebase_service.signUpUser(
        email: widget.email,
        password: widget.password,
        name: name,
        goals: goals,
        activityLevel: activityLevel,
        gender: gender,
        age: int.tryParse(age) ?? 0,
        height: double.tryParse(height) ?? 0,
        weight: double.tryParse(weight) ?? 0,
        goalWeight: double.tryParse(goalWeight) ?? 0,
      );

      if (result != null) {
        // Success → go to login
        if (mounted) {
          // ✅ Sign out the newly created Firebase user to prevent auto-login
          await FirebaseAuth.instance.signOut();
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('remembered_email');

          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        // Firebase returned an error — clean it up for readability
        final errorMessage = result.toString().replaceAll(RegExp(r'\[.*?\]\s*'), '');
        print('Signup failed: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: $errorMessage'), backgroundColor: Colors.red),
        );
      }
    } catch (e, stack) {
      print('🔥 SIGNUP ERROR: $e');
      print(stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void handleGoogleSignIn() {
    // TODO: Implement Google Sign-In
    print('Continue with Google clicked');
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> bgTop = [
      const Color(0xFFD5E3CC),
      const Color(0xFFD5E3CC),
      const Color(0xFFFFE1C7),
      const Color(0xFFFFE1C7),
    ];
    final List<Color> bgBottom = [
      const Color(0xFFC8DBB8),
      const Color(0xFFC8DBB8),
      const Color(0xFFFFD3AD),
      const Color(0xFFFFD3AD),
    ];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop[currentStep - 1], bgBottom[currentStep - 1]],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: List.generate(totalSteps, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      decoration: BoxDecoration(
                        color: index < currentStep
                            ? (index % 2 == 0
                                  ? const Color(0xFF67B14D)
                                  : const Color(0xFFF39321))
                            : const Color(0x99FFFFFF),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Titles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  Text(
                    _stepTitle(currentStep),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7A6F5D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _stepSubtitle(currentStep),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF7A6F5D),
                    ),
                  ),
                ],
              ),
            ),

            // Step Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : StepContent(
                      step: currentStep,
                      name: name,
                      setName: (val) => setState(() => name = val),
                      goals: goals,
                      toggleGoal: (goal) => setState(() {
                        goals.contains(goal)
                            ? goals.remove(goal)
                            : goals.add(goal);
                      }),
                      activityLevel: activityLevel,
                      setActivityLevel: (val) =>
                          setState(() => activityLevel = val),
                      gender: gender,
                      setGender: (val) => setState(() => gender = val),
                      age: age,
                      setAge: (val) => setState(() => age = val),
                      height: height,
                      setHeight: (val) => setState(() => height = val),
                      weight: weight,
                      setWeight: (val) => setState(() => weight = val),
                      goalWeight: goalWeight,
                      setGoalWeight: (val) => setState(() => goalWeight = val),
                    ),
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E42),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: isNextDisabled() || isLoading
                          ? null
                          : handleNext,
                      child: Text(
                        currentStep == totalSteps ? 'Create Account' : 'Next',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6B5F3B),
                        side: const BorderSide(color: Colors.transparent),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: previousStep,
                      child: const Text(
                        'Go Back',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Step Content Widget ---
class StepContent extends StatelessWidget {
  final int step;
  final String name;
  final void Function(String) setName;
  final List<String> goals;
  final void Function(String) toggleGoal;
  final String activityLevel;
  final void Function(String) setActivityLevel;
  final String gender;
  final void Function(String) setGender;
  final String age;
  final void Function(String) setAge;
  final String height;
  final void Function(String) setHeight;
  final String weight;
  final void Function(String) setWeight;
  final String goalWeight;
  final void Function(String) setGoalWeight;

  const StepContent({
    super.key,
    required this.step,
    required this.name,
    required this.setName,
    required this.goals,
    required this.toggleGoal,
    required this.activityLevel,
    required this.setActivityLevel,
    required this.gender,
    required this.setGender,
    required this.age,
    required this.setAge,
    required this.height,
    required this.setHeight,
    required this.weight,
    required this.setWeight,
    required this.goalWeight,
    required this.setGoalWeight,
  });

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case 1:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              TextField(
                onChanged: setName,
                decoration: InputDecoration(
                  hintText: 'Name',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        );
      case 2:
        final goalOptions = [
          "Lose weight",
          "Gain weight",
          "Maintain weight",
          "Learn to cook",
          "Discover recipes",
          "Eat healthy",
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: goalOptions.map((goal) {
              final selected = goals.contains(goal);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                    color: Color(0x0D000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => toggleGoal(goal),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF1E88E5)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            goal,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF67B14D),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      case 3:
        final options = [
          "Sedentary",
          "Lightly active",
          "Active",
          "Very active",
        ];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: options.map((option) {
              final selected = activityLevel == option;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                    color: Color(0x0D000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setActivityLevel(option),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 80),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF1E88E5)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                option,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _activityDescription(option),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle, color: Color(0xFF67B14D)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      case 4:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gender == 'Male'
                            ? const Color(0xFF90CAF9)
                            : Colors.white,
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => setGender('Male'),
                      child: const Text('Male'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gender == 'Female'
                            ? const Color(0xFFF48FB1)
                            : Colors.white,
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => setGender('Female'),
                      child: const Text('Female'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _numberField(hint: 'Age', onChanged: setAge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _numberField(hint: 'Height', onChanged: setHeight),
                  ),
                  const SizedBox(width: 12),
                  _unitChip('cm'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _numberField(hint: 'Weight', onChanged: setWeight),
                  ),
                  const SizedBox(width: 12),
                  _unitChip('kg'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      hint: 'Goal Weight',
                      onChanged: setGoalWeight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _unitChip('kg'),
                ],
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

// --- Helpers ---
Widget _numberField({
  required String hint,
  required void Function(String) onChanged,
}) {
  return Stack(
    children: [
      TextField(
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ],
  );
}

Widget _unitChip(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
    decoration: BoxDecoration(
      color: const Color(0xFFF39321),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    ),
  );
}

String _activityDescription(String option) {
  switch (option) {
    case 'Sedentary':
      return 'Spend most of the day sitting';
    case 'Lightly active':
      return 'Spend a good part of the day on your feet';
    case 'Active':
      return 'Spend a good part of the day doing physical activity';
    case 'Very active':
      return 'Spend a good part of the day doing heavy physical activity';
    default:
      return '';
  }
}
