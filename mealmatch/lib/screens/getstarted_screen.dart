import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  int currentStep = 1;
  final int totalSteps = 5;

  // User data
  String name = '';
  List<String> goals = [];
  String activityLevel = '';
  String gender = '';
  String age = '';
  String height = '';
  String weight = '';
  String goalWeight = '';
  String email = '';
  String password = '';
  bool agreedToTerms = false;

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
    if (currentStep == 4) return gender.isEmpty || age.isEmpty || height.isEmpty || weight.isEmpty || goalWeight.isEmpty;
    if (currentStep == 5) return email.isEmpty || password.length < 10 || !agreedToTerms;
    return false;
  }

  // --- Signup function ---
  void handleNext() async {
    if (currentStep < totalSteps) {
      setState(() {
        currentStep++;
      });
    } else {
      // Final step: sign up
      setState(() => isLoading = true);

      final userId = await _firebaseService.signUpUser(
        name: name,
        goals: goals,
        activityLevel: activityLevel,
        gender: gender,
        age: int.tryParse(age) ?? 0,
        height: double.tryParse(height) ?? 0,
        weight: double.tryParse(weight) ?? 0,
        goalWeight: double.tryParse(goalWeight) ?? 0,
        email: email,
        password: password,
      );

      setState(() => isLoading = false);

      if (userId != null) {
        // Save user ID locally for auto-login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);

        // Navigate to Home Screen (replace with your route)
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup failed! Check your email or password.')),
        );
      }
    }
  }

  void handleGoogleSignIn() {
    // TODO: Implement Google Sign-In
    print('Continue with Google clicked');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFD8),
      body: Column(
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
                    onPressed: previousStep,
                  ),
                ),
                const Center(
                  child: Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: List.generate(totalSteps, (index) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    decoration: BoxDecoration(
                      color: index < currentStep ? Colors.green : Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
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
                      goals.contains(goal) ? goals.remove(goal) : goals.add(goal);
                    }),
                    activityLevel: activityLevel,
                    setActivityLevel: (val) => setState(() => activityLevel = val),
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
                    email: email,
                    setEmail: (val) => setState(() => email = val),
                    password: password,
                    setPassword: (val) => setState(() => password = val),
                    agreedToTerms: agreedToTerms,
                    setAgreedToTerms: (val) => setState(() => agreedToTerms = val),
                  ),
          ),

          // Next/Finish Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: previousStep,
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isNextDisabled() || isLoading ? null : handleNext,
                    child: Text(currentStep == totalSteps ? 'Finish' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
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
  final String email;
  final void Function(String) setEmail;
  final String password;
  final void Function(String) setPassword;
  final bool agreedToTerms;
  final void Function(bool) setAgreedToTerms;

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
    required this.email,
    required this.setEmail,
    required this.password,
    required this.setPassword,
    required this.agreedToTerms,
    required this.setAgreedToTerms,
  });

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case 1:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: setName,
              decoration: const InputDecoration(
                  labelText: 'Preferred Name', border: OutlineInputBorder()),
            ),
          ),
        );
      case 2:
        final goalOptions = [
          "Lose weight",
          "Gain weight",
          "Maintain weight",
          "Learn to cook",
          "Discover recipes",
          "Eat healthy"
        ];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: goalOptions.map((goal) {
            final selected = goals.contains(goal);
            return ListTile(
              title: Text(goal),
              trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () => toggleGoal(goal),
            );
          }).toList(),
        );
      case 3:
        final options = ["Sedentary", "Lightly active", "Active", "Very active"];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: options
              .map((option) => RadioListTile(
                    title: Text(option),
                    value: option,
                    groupValue: activityLevel,
                    onChanged: (val) => setActivityLevel(val ?? ''),
                  ))
              .toList(),
        );
      case 4:
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const Text('Gender'),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: gender == 'Male' ? Colors.blue : Colors.grey[300]),
                      onPressed: () => setGender('Male'),
                      child: const Text('Male'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: gender == 'Female' ? Colors.pink : Colors.grey[300]),
                      onPressed: () => setGender('Female'),
                      child: const Text('Female'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: setAge,
                decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: setHeight,
                decoration:
                    const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: setWeight,
                decoration:
                    const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: setGoalWeight,
                decoration: const InputDecoration(
                    labelText: 'Goal Weight (kg)', border: OutlineInputBorder()),
              ),
            ],
          ),
        );
      case 5:
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              TextField(
                onChanged: setEmail,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: setPassword,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: agreedToTerms,
                onChanged: (val) => setAgreedToTerms(val ?? false),
                title: const Text('I agree to the Terms and Conditions'),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
