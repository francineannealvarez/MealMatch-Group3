# 🍽️ MealMatch
### *Recipes You Can Cook, Calories You Can Trust*
 
MealMatch is a mobile application that helps everyday cooks make the most of what they already have at home. Input your available ingredients, get recipe recommendations instantly, and track your calorie intake — all in one place.
 
---
 
## 📖 About the Project
 
Food waste is a real problem. According to the Philippine Institute for Development Studies (PIDS), around **2,000 tons of food are wasted daily** in the Philippines — and a huge chunk of that comes from households not knowing how to use what's already in their kitchens.
 
At the same time, most people who want to eat healthier don't have an easy way to track calories *while* they cook. Existing recipe apps give you inspiration but rarely factor in what ingredients you actually own, let alone your nutritional goals.
 
**MealMatch bridges that gap.**
 
We built this as our capstone project for *IT331 – Application Development and Emerging Technologies* at Batangas State University – The National Engineering University (BatState-U Alangilan). The goal was simple: make cooking smarter, reduce food waste, and make calorie tracking feel natural — not like a chore.
 
This project also aligns with:
- 🌾 **SDG 2: Zero Hunger** — promoting accessible, nutritious meals
- ♻️ **SDG 12: Responsible Consumption and Production** — reducing household food waste
 
---
 
## ✨ Features
 
- 🔍 **What Can I Cook?** — Enter the ingredients you have, get recipe recommendations categorized as *complete matches* (you have everything) or *partial matches* (you're close)
- 📊 **Calorie Tracker** — Personalized daily calorie goals calculated from your demographics, fitness goals, and activity level using the Mifflin-St Jeor equation + TDEE
- 📋 **Food Log** — Log meals by category (Breakfast, Lunch, Dinner, Snacks) and track your intake in real time
- 🧑‍🍳 **User Recipes** — Create, upload, and share your own recipes with ingredients, step-by-step instructions, prep/cook time, and photos
- ❤️ **Favorites** — Save recipes you love for quick access later
- 🏆 **Progress Tracking** — Monitor streaks, weekly calorie goals, weight progress, and achievements
- 🔔 **Notifications** — Meal reminders and milestone alerts
 
---
 
## 🛠️ Tech Stack
 
| Category | Technology |
|---|---|
| **Framework** | Flutter 3.35.3 |
| **Language** | Dart 3.9.2 |
| **Database** | Firebase Firestore |
| **Authentication** | Firebase Authentication |
| **Storage** | Firebase Storage |
| **IDE / Dev Tools** | VS Code, Android Studio, Android SDK |
| **Design** | Figma, Canva |
| **Version Control** | GitHub |
 
### External APIs
 
| API | Purpose |
|---|---|
| [TheMealDB](https://www.themealdb.com/) | Recipe data, images, and cooking instructions |
| [USDA FoodData Central](https://fdc.nal.usda.gov/) | Authoritative nutritional data |
| [OpenFoodFacts](https://world.openfoodfacts.org/) | Supplementary nutritional data for packaged foods |
 
---
 
## 🏗️ Architecture
 
MealMatch follows a **layered architecture** with feature-based organization:
 
```
lib/
├── screens/       # 20+ UI screens (homepage, logfood, recipe details, etc.)
├── widgets/       # Reusable UI components
├── services/      # 12 service files — Firebase, API integrations, business logic
├── models/        # 6 data models (FoodItem, MealLog, Recipe, UserRecipe, etc.)
├── utils/         # Utility and text formatting helpers
└── helpers/       # Notification scheduling and other helpers
```
 
**Data flow:** UI → Business Logic Layer (Services) → External APIs / Firebase → Back to UI via Flutter's `setState`
 
---
 
## 📋 Requirements
 
- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Android 6.0+ / iOS 13.0+
- Active internet connection (offline mode is not supported)
- Firebase project with Firestore and Authentication enabled
 
---
 
## 🚀 Getting Started
 
### 1. Clone the repository
 
```bash
git clone https://github.com/francineannealvarez/MealMatch-Group3.git
cd MealMatch-Group3
```
 
### 2. Install dependencies
 
```bash
flutter pub get
```
 
### 3. Firebase Setup
 
This project uses Firebase. You'll need to connect your own Firebase project:
 
1. Go to [Firebase Console](https://console.firebase.google.com/) and create a project
2. Enable **Firestore Database** and **Firebase Authentication** (Email/Password)
3. Download `google-services.json` (Android) and/or `GoogleService-Info.plist` (iOS)
4. Place them in the appropriate directories:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
 
### 4. API Keys
 
Add your API keys for USDA FoodData Central. Create a `.env` file or configure them directly in your service files (refer to `lib/services/food_api_service.dart`):
 
```
USDA_API_KEY=your_api_key_here
```
 
> TheMealDB and OpenFoodFacts are free and do not require API keys.
 
### 5. Run the app
 
```bash
flutter run
```
 
To run on a specific device:
 
```bash
flutter run -d <device_id>
```
 
List available devices with `flutter devices`.
 
---
 
## 📱 Screens Overview
 
| Screen | Description |
|---|---|
| Splash / Greet | App intro and onboarding |
| Sign Up / Log In | Account creation with profile setup (goals, activity level, demographics) |
| Home / Dashboard | Daily calorie summary, quick access to features, cook-again suggestions |
| What Can I Cook? | Ingredient-based recipe search with complete/partial match display |
| Discover Recipes | Browse all recipes; filter by Favorites or My Recipes |
| Recipe Details | Full recipe view with ingredients, instructions, nutrition info, and timer |
| Log Food | Search and log meals from USDA/OpenFoodFacts databases |
| Log History | View calorie history by day, week, or custom date range |
| Upload Recipe | Create and publish your own recipes to the community |
| Profile | Stats, streaks, achievements, and personal recipe collection |
| Settings | Edit profile, modify goals, update weight, change password |
 
---

## 👥 Team

| Name | GitHub |
|---|---|
| Alvarez, Francine Anne V. | [@francineannealvarez](https://github.com/francineannealvarez) |
| Bandola, Jobelyn G. | — |
| Cantos, Iloiza Jhane C. | [@cantos-iloiza](https://github.com/cantos-iloiza) |
| Castillo, Cloyd Robin C. | — |
| Mercado, Andrea Sophia D. | — |
 
---
 
## 📄 License
 
This project was developed for academic purposes under Batangas State University, The National Engineering University. All rights reserved by the authors.
 
---
 
<p align="center">
  <em>MealMatch — Cooking with a purpose. 🥘</em>
</p>
