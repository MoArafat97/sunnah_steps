# Sunnah Steps

A Flutter app for tracking Islamic Sunnah habits with Firebase backend.

## 🧠 Progress Engine & QA Harness (v0.3) - Complete!

This release implements comprehensive progress tracking with streak logic, weekly heatmaps, and a robust QA testing framework.

### ✅ New Features

#### 🧠 Progress Engine
- **Streak Tracking**: Consecutive day completion tracking with automatic reset logic
- **Weekly Heatmap**: 7-day visual activity display with color-coded intensity levels
- **Progress Persistence**: Local storage with SharedPreferences for offline capability
- **Smart Analytics**: Weekly summaries, consistency metrics, and personalized insights

#### 🧪 QA Harness
- **Test-Drive Mode**: Hidden debug toggle (long-press app logo) with dummy data generation
- **Comprehensive Testing**: Unit tests for streak logic, widget tests for UI components
- **Integration Tests**: End-to-end testing for critical user journeys
- **CI/CD Pipeline**: GitHub Actions workflow with automated testing and deployment

#### 📱 Enhanced UI
- **Dashboard Integration**: Real-time streak display and today's completion counter
- **Rich Progress Page**: Streak cards, heatmap visualization, and weekly insights
- **Debug Panel**: QA-friendly interface for testing different user scenarios

## 🚀 Core Data Sprint (v0.1) - Complete!

This release establishes the foundational data layer and API infrastructure.

### ✅ Delivered Features

- **Firebase Backend**: Direct Firestore SDK access with Firebase Auth
- **Authentication**: Firebase Auth integration with role-based access control
- **Data Models**: TypeScript interfaces for Users, Habits, Bundles, and Completion Logs
- **Seed Data**: 25+ authentic Sunnah habits with Arabic/English Hadith references
- **Curated Bundles**: 8 starter habit bundles (Morning Routine, Prayer Etiquette, etc.)
- **Security Rules**: Firestore rules with proper read/write permissions
- **Unit Tests**: Comprehensive Flutter widget and service tests
- **Local State**: SharedPreferences for offline-first functionality

## 🏗 Architecture

### Backend (Firebase Services)
- **Firebase Auth**: User authentication and authorization
- **Cloud Firestore**: NoSQL database for habits, bundles, and user data
- **Direct SDK Access**: Flutter app communicates directly with Firebase services

### Frontend (Flutter)
```
lib/
├── data/                # Sample data
├── models/              # Dart models
├── pages/               # UI screens
├── services/            # API services
└── widgets/             # Reusable components
```

## 🔧 Setup & Installation

### Prerequisites
- Firebase CLI
- Flutter SDK
- Firebase project

### 1. Clone & Install
```bash
git clone <repository-url>
cd sunnah_steps
npm run setup
```

### 2. Firebase Configuration
```bash
# Login to Firebase
firebase login

# Initialize project (if not done)
firebase init

# Set your project ID
firebase use your-project-id
```

### 3. Environment Setup
Create `.env` file in functions directory:
```env
FIREBASE_PROJECT_ID=your-project-id
```

## 🌱 Database Seeding

### One-Click Seeding
```bash
npm run seed:sunnah
```

This command:
- ✅ Imports 25+ authentic Sunnah habits
- ✅ Creates 8 curated habit bundles
- ✅ Idempotent (safe to run multiple times)
- ✅ Skips if data already exists

### Manual Seeding (Alternative)
```bash
cd functions
npm run build
node lib/scripts/seed.js
```

## 🚀 Running Locally

### Start Firebase Emulators
```bash
npm run serve:emulators
```

This starts:
- **Firestore**: http://localhost:8080
- **Auth**: http://localhost:9099
- **UI**: http://localhost:4000

### Start Flutter App
```bash
flutter run
```

## 🗄️ Data Access

### Firebase Services
The app uses direct Firebase SDK access for all data operations:

#### Firestore Collections
- **habits**: Sunnah habits with metadata and Islamic references
- **bundles**: Curated habit collections (Morning, Evening, etc.)
- **users**: User profiles and preferences
- **completion_log**: User habit completion tracking

#### Authentication
- **Firebase Auth**: Google Sign-In and email/password authentication
- **Security Rules**: Firestore rules ensure users can only access their own data

## 🔐 Security

### Firestore Security Rules
- **Habits & Bundles**: Read-only for authenticated users
- **Users & Completions**: Read/write only for resource owner
- **Environment Variables**: All sensitive data stored in `.env` files

## 🧪 Testing & QA

### Flutter Tests
```bash
# Run all Flutter tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test files
flutter test test/unit/progress_service_test.dart
flutter test test/unit/streak_data_test.dart
```

### Integration Tests
```bash
# Run integration tests
flutter test integration_test/

# Run specific integration test
flutter test integration_test/progress_flow_test.dart
```



### QA Test-Drive Mode
1. **Enable Debug Mode**: Long-press on "Sunnah Steps" app title
2. **Load Test Data**: Tap debug icon → "Enable Test-Drive Mode"
3. **Test Scenarios**:
   - Active user with 7-21 day streak
   - Pre-populated heatmap with realistic completion patterns
   - 3 pre-ticked habits on dashboard

### Key Test Coverage
#### Progress Engine Tests
- ✅ Streak logic (increment, reset, persistence)
- ✅ Heatmap data tracking and visualization
- ✅ Weekly summary calculations
- ✅ Data persistence across app restarts

#### UI Component Tests
- ✅ WeeklyHeatmap widget rendering
- ✅ Progress page layout and data display
- ✅ Dashboard integration with progress tracking

#### Integration Tests
- ✅ Complete habit completion flow
- ✅ Debug mode toggle and test data loading
- ✅ Progress persistence across sessions

### Data Persistence Tests
The tests verify:
- ✅ Direct Firestore SDK operations work correctly
- ✅ Local SharedPreferences persistence
- ✅ Firebase Auth integration
- ✅ Offline-first functionality
- ✅ Data synchronization between local and cloud storage



## 📊 Data Schema

### Collections Structure
```
firestore/
├── users/{uid}
│   ├── displayName, email, role, locale, createdAt
│   └── completion_log/{logId}
│       └── habitId, completedAt, source, note
├── habits/{habitId}
│   └── title, hadithArabic, hadithEnglish, benefits, tags, category, priority
└── bundles/{bundleId}
    └── name, description, habitIds[], displayOrder, createdAt
```

### Sample Data Included

#### 25+ Authentic Sunnah Habits
- **Prayer Related**: Miswak, Ayat al-Kursi, Dhikr after Salah
- **Daily Etiquette**: Eating with right hand, greeting with Salam, smiling
- **Charity Acts**: Feeding hungry, removing harmful objects, secret charity
- **Dhikr & Remembrance**: Morning/evening Adhkar, Subhanallah, Hawqala
- **Friday Specials**: Surah al-Kahf, Salawat on Prophet, best clothes

#### 8 Curated Bundles
1. **Morning Routine** - Start day with blessings
2. **Prayer Etiquette** - Mosque and Salah practices
3. **Sleep & Night** - Peaceful bedtime habits
4. **Eating Etiquette** - Blessed meal practices
5. **Social Interactions** - Community and relationships
6. **Acts of Charity** - Simple ways to help others
7. **Daily Remembrance** - Essential dhikr
8. **Friday Specials** - Jumu'ah practices

## 🚀 Deployment

### Deploy to Firebase
```bash
# Deploy functions only
npm run deploy:functions

# Deploy all (functions + rules + indexes)
firebase deploy
```

### Production Environment Variables
Set in Firebase Functions config:
```bash
firebase functions:config:set app.environment="production"
```

## 🔧 Development

### Project Structure
- **Frontend**: Flutter mobile app with direct Firebase SDK access
- **Database**: Firestore with security rules
- **Auth**: Firebase Authentication
- **Local Storage**: SharedPreferences for offline functionality
- **Testing**: Flutter widget and unit tests

### Adding New Habits
1. Add to `lib/data/sample_habits.dart`
2. Follow existing format with Arabic/English Hadith
3. Include proper tags and context
4. Update Firestore seeding scripts if needed

### Adding New Features
1. Create new widgets in `lib/widgets/`
2. Add services in `lib/services/` for business logic
3. Update models in `lib/models/` if needed
4. Add unit tests in `test/`
5. Update integration tests if needed

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Commit changes: `git commit -am 'Add new feature'`
4. Push to branch: `git push origin feature/new-feature`
5. Submit pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Authentic Hadith references from Sahih Bukhari, Muslim, and other reliable sources
- Islamic scholars for preserving and transmitting the Sunnah
- Firebase team for excellent backend infrastructure
- Flutter team for cross-platform development framework

---

**Built with ❤️ for the Muslim Ummah**

*"The best of people are those who benefit others."* - Prophet Muhammad ﷺ
