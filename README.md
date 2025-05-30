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

- **Firebase Backend**: Complete Cloud Functions API with REST and GraphQL endpoints
- **Authentication**: Firebase Auth integration with role-based access control
- **Data Models**: TypeScript interfaces for Users, Habits, Bundles, and Completion Logs
- **Seed Data**: 25+ authentic Sunnah habits with Arabic/English Hadith references
- **Curated Bundles**: 8 starter habit bundles (Morning Routine, Prayer Etiquette, etc.)
- **Security Rules**: Firestore rules with proper read/write permissions
- **Unit Tests**: Comprehensive tests for POST /completions endpoint
- **API Documentation**: Postman collection with sample requests

## 🏗 Architecture

### Backend (Firebase Cloud Functions)
```
functions/
├── src/
│   ├── models/           # TypeScript interfaces
│   ├── routes/           # REST API endpoints
│   ├── graphql/          # GraphQL server
│   ├── middleware/       # Auth & validation
│   ├── scripts/          # Seed data script
│   ├── triggers/         # Auth triggers
│   └── test/            # Unit tests
├── package.json
└── tsconfig.json
```

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
- Node.js 18+
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
- **Functions**: http://localhost:5001
- **Firestore**: http://localhost:8080
- **Auth**: http://localhost:9099
- **UI**: http://localhost:4000

### Start Flutter App
```bash
flutter run
```

## 📡 API Endpoints

### Base URL
- **Local**: `http://localhost:5001/sunnah-steps-82d64/us-central1/api`
- **Production**: `https://us-central1-sunnah-steps-82d64.cloudfunctions.net/api`

### REST Endpoints

#### Habits
- `GET /habits` - List habits with filtering
- `GET /habits/:id` - Get specific habit
- `GET /habits/search/:query` - Search habits

#### Bundles
- `GET /bundles` - List habit bundles
- `GET /bundles/:id` - Get specific bundle
- `GET /bundles/:id/habits` - Get habits in bundle

#### Users
- `POST /users` - Create user profile
- `GET /users/:userId` - Get user profile
- `PUT /users/:userId` - Update user profile

#### Completions
- `POST /completions` - Log habit completion ⭐
- `GET /completions/:userId` - Get completion history
- `GET /completions/:userId/stats` - Get completion statistics

### GraphQL Endpoint
- `POST /graphql` - GraphQL queries and mutations
- **Playground**: Available in development mode

## 🔐 Authentication

All endpoints require Firebase Auth token in header:
```
Authorization: Bearer <firebase-id-token>
```

### Security Rules
- **Habits & Bundles**: Read-only for authenticated users
- **Users & Completions**: Read/write only for resource owner or coach role

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

### Backend Tests
```bash
# Run Firebase Functions tests
npm run test:functions

# Run with coverage
cd functions && npm test -- --coverage
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

### Backend API Tests
The unit test verifies:
- ✅ Writes to correct Firestore path: `users/{uid}/completion_log/{logId}`
- ✅ Rejects unauthenticated requests
- ✅ Validates required fields
- ✅ Checks habit existence
- ✅ Returns proper response format

### API Testing with Postman
1. Import `postman_collection.json`
2. Set variables:
   - `base_url`: Your API base URL
   - `firebase_token`: Valid Firebase ID token
   - `user_id`: Test user ID
3. Run requests

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
- **Backend**: TypeScript Cloud Functions with Express.js
- **Database**: Firestore with security rules
- **Auth**: Firebase Authentication with custom claims
- **API**: REST + GraphQL endpoints
- **Testing**: Jest unit tests

### Adding New Habits
1. Add to `functions/src/scripts/seed.ts`
2. Follow existing format with Arabic/English Hadith
3. Include proper tags and context
4. Run seed script to update database

### Adding New Endpoints
1. Create route in `functions/src/routes/`
2. Add authentication middleware
3. Update GraphQL schema if needed
4. Add unit tests
5. Update Postman collection

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
