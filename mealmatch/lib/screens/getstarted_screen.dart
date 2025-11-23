// lib/screens/getstarted_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../widgets/avatar_picker.dart';

String _stepTitle(int step, bool showWeightPace) {
  if (showWeightPace && step == 3) {
    return 'Select Your Pace';
  }

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

String _stepSubtitle(int step, bool showWeightPace, bool isLosingWeight) {
  if (showWeightPace && step == 3) {
    return isLosingWeight
        ? 'How fast do you want to lose weight?'
        : 'How fast do you want to gain weight?';
  }

  switch (step) {
    case 1:
      return 'What should we call you? (Avatar is optional)';
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
  final String? password;
  final bool isGoogleUser;

  const GetStartedScreen({
    super.key,
    required this.email,
    this.password,
    this.isGoogleUser = false,
  });

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final FirebaseService firebase_service = FirebaseService();

  int currentStep = 1;
  int totalSteps = 4; // Will become 5 if weight pace is needed

  // User data
  String name = '';
  String? selectedAvatar;
  List<String> goals = [];
  String activityLevel = '';
  String weightPace = 'steady';
  String gender = '';
  String age = '';
  String height = '';
  String weight = '';
  String goalWeight = '';

  bool _agreedToTerms = false;
  bool isLoading = false;

  // Check if user needs weight pace selection
  bool get _needsWeightPaceSelection {
    return goals.any(
      (g) =>
          g.toLowerCase().contains('lose') || g.toLowerCase().contains('gain'),
    );
  }

  bool get _isLosingWeight {
    return goals.any((g) => g.toLowerCase().contains('lose'));
  }

  @override
  void initState() {
    super.initState();
    _updateTotalSteps();
  }

  void _updateTotalSteps() {
    setState(() {
      totalSteps = _needsWeightPaceSelection ? 5 : 4;
    });
  }

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
    if (currentStep == 1) {
      return name.isEmpty;
    }
    if (currentStep == 2) {
      return goals.isEmpty;
    }
    if (currentStep == 3) {
      // If weight pace is needed, step 3 is weight pace selection
      if (_needsWeightPaceSelection) {
        return weightPace.isEmpty;
      }
      // Otherwise step 3 is activity level
      return activityLevel.isEmpty;
    }
    if (currentStep == 4) {
      // If weight pace was shown, step 4 is activity level
      if (_needsWeightPaceSelection) {
        return activityLevel.isEmpty;
      }
      // Otherwise step 4 is the final form
      return gender.isEmpty ||
          age.isEmpty ||
          height.isEmpty ||
          weight.isEmpty ||
          goalWeight.isEmpty ||
          !_agreedToTerms;
    }
    if (currentStep == 5) {
      // Step 5 only exists if weight pace was needed
      return gender.isEmpty ||
          age.isEmpty ||
          height.isEmpty ||
          weight.isEmpty ||
          goalWeight.isEmpty ||
          !_agreedToTerms;
    }
    return false;
  }

  // --- Signup function ---
  void handleNext() async {
    // Update total steps when moving from step 2 (goals selection)
    if (currentStep == 2) {
      _updateTotalSteps();
    }

    if (currentStep < totalSteps) {
      setState(() => currentStep++);
      return;
    }

    setState(() => isLoading = true);

    try {
      final success = await firebase_service.saveUserProfile(
        name: name,
        avatar: selectedAvatar,
        goals: goals,
        activityLevel: activityLevel,
        gender: gender,
        age: int.tryParse(age) ?? 0,
        height: double.tryParse(height) ?? 0,
        weight: double.tryParse(weight) ?? 0,
        goalWeight: double.tryParse(goalWeight) ?? 0,
      );

      if (success) {
        if (mounted) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('remembered_email', widget.email);
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        throw Exception('Failed to save user profile');
      }
    } catch (e, stack) {
      print('🔥 SIGNUP ERROR: $e');
      print(stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> bgTop = [
      const Color(0xFFD5E3CC),
      const Color(0xFFFFE1C7),
      const Color(0xFFD5E3CC),
      const Color(0xFFFFE1C7),
      const Color(0xFFD5E3CC),
    ];
    final List<Color> bgBottom = [
      const Color(0xFFC8DBB8),
      const Color(0xFFFFD3AD),
      const Color(0xFFC8DBB8),
      const Color(0xFFFFD3AD),
      const Color(0xFFC8DBB8),
    ];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bgTop[currentStep - 1 < bgTop.length ? currentStep - 1 : 0],
              bgBottom[currentStep - 1 < bgBottom.length ? currentStep - 1 : 0],
            ],
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
                    _stepTitle(currentStep, _needsWeightPaceSelection),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7A6F5D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _stepSubtitle(
                      currentStep,
                      _needsWeightPaceSelection,
                      _isLosingWeight,
                    ),
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
                      showWeightPace: _needsWeightPaceSelection,
                      isLosingWeight: _isLosingWeight,
                      name: name,
                      setName: (val) => setState(() => name = val),
                      selectedAvatar: selectedAvatar,
                      setAvatar: (val) => setState(() => selectedAvatar = val),
                      goals: goals,
                      toggleGoal: (goal) => setState(() {
                        goals.contains(goal)
                            ? goals.remove(goal)
                            : goals.add(goal);
                      }),
                      activityLevel: activityLevel,
                      setActivityLevel: (val) =>
                          setState(() => activityLevel = val),
                      weightPace: weightPace,
                      setWeightPace: (val) => setState(() => weightPace = val),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreedToTerms = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFFF59E42),
                      ),
                      Expanded(
                        child: Wrap(
                          children: [
                            const Text(
                              "I agree to the ",
                              style: TextStyle(fontSize: 14),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/terms'),
                              child: const Text(
                                "Terms and Conditions",
                                style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const Text(" and "),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/privacy'),
                              child: const Text(
                                "Privacy Policy",
                                style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

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
                      onPressed:
                          (isNextDisabled() || isLoading || !_agreedToTerms)
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
  final bool showWeightPace;
  final bool isLosingWeight;
  final String name;
  final void Function(String) setName;
  final String? selectedAvatar;
  final void Function(String?) setAvatar;
  final List<String> goals;
  final void Function(String) toggleGoal;
  final String activityLevel;
  final void Function(String) setActivityLevel;
  final String weightPace;
  final void Function(String) setWeightPace;
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
    required this.showWeightPace,
    required this.isLosingWeight,
    required this.setName,
    required this.name,
    required this.selectedAvatar,
    required this.setAvatar,
    required this.goals,
    required this.toggleGoal,
    required this.activityLevel,
    required this.setActivityLevel,
    required this.weightPace,
    required this.setWeightPace,
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
    // Determine actual step content based on whether weight pace is shown
    if (showWeightPace && step >= 3) {
      // If weight pace is needed:
      // Step 3 = Weight Pace
      // Step 4 = Activity Level
      // Step 5 = Personal Info
      if (step == 3) {
        return _buildWeightPaceSelection();
      } else if (step == 4) {
        return _buildActivityLevelSelection();
      } else if (step == 5) {
        return _buildPersonalInfoForm();
      }
    } else {
      // If weight pace is NOT needed:
      // Step 3 = Activity Level
      // Step 4 = Personal Info
      if (step == 3) {
        return _buildActivityLevelSelection();
      } else if (step == 4) {
        return _buildPersonalInfoForm();
      }
    }

    // Steps 1 and 2 are the same regardless
    switch (step) {
      case 1:
        return _buildNameAndAvatarStep();
      case 2:
        return _buildGoalsSelection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameAndAvatarStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
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
            const SizedBox(height: 24),
            const Text(
              'Choose your Avatar (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7A6F5D),
              ),
            ),
            const SizedBox(height: 16),
            AvatarPicker(
              selectedAvatar: selectedAvatar,
              onAvatarSelected: setAvatar,
              showSkipOption: true,
              isGridView: true,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsSelection() {
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
                      const Icon(Icons.check_circle, color: Color(0xFF67B14D)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Weight Pace Selection
  Widget _buildWeightPaceSelection() {
    final paceOptions = [
      {
        'value': 'relaxed',
        'title': 'Relaxed',
        'subtitle': isLosingWeight
            ? 'Lose ½ kg per week'
            : 'Gain ½ kg per week',
        'color': const Color(0xFF4CAF50),
        'icon': Icons.spa,
      },
      {
        'value': 'steady',
        'title': 'Steady',
        'subtitle': isLosingWeight
            ? 'Lose ½ kg per week'
            : 'Gain ½ kg per week',
        'color': const Color(0xFF2196F3),
        'icon': Icons.trending_up,
        'recommended': true,
      },
      {
        'value': 'accelerated',
        'title': 'Accelerated',
        'subtitle': isLosingWeight
            ? 'Lose ¾ kg per week'
            : 'Gain ¾ kg per week',
        'color': const Color(0xFFFF9800),
        'icon': Icons.fast_forward,
      },
      {
        'value': 'vigorous',
        'title': 'Vigorous',
        'subtitle': isLosingWeight
            ? 'Lose 1 kg per week'
            : 'Gain 1 kg per week',
        'color': const Color(0xFFF44336),
        'icon': Icons.flash_on,
        'warning': true,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: paceOptions.map((pace) {
          final selected = weightPace == pace['value'];
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
              onTap: () => setWeightPace(pace['value'] as String),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? (pace['color'] as Color)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (pace['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        pace['icon'] as IconData,
                        color: pace['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                pace['title'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (pace['recommended'] == true) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Recommended',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                              if (pace['warning'] == true) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Not Recommended',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pace['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle, color: pace['color'] as Color),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityLevelSelection() {
    final options = [
      "Sedentary",
      "Lightly active",
      "Moderately active",
      "Extremely active",
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
                            style: const TextStyle(fontWeight: FontWeight.w700),
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
  }

  Widget _buildPersonalInfoForm() {
    return SingleChildScrollView(
      child: Padding(
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
    case 'Moderately active':
      return 'Spend a good part of the day doing physical activity';
    case 'Extremely active':
      return 'Spend a good part of the day doing heavy physical activity';
    default:
      return '';
  }
}
