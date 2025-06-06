# Firebase Setup Guide for Sunnah Steps

This guide will help you configure Firebase Authentication and resolve common issues.

## 🔧 Firebase Console Configuration

### 1. Enable Email/Password Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `sunnah-steps-82d64`
3. Navigate to **Authentication** > **Sign-in method**
4. Click on **Email/Password**
5. Enable **Email/Password** (first option)
6. Click **Save**

### 2. Configure Google Sign-In

1. In **Authentication** > **Sign-in method**
2. Click on **Google**
3. Enable **Google** sign-in
4. Set **Project support email** to your email
5. Click **Save**

### 3. Add SHA-1 Fingerprints (Critical for Android)

#### Get Debug SHA-1:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### Get Release SHA-1:
```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your-alias-name
```

#### Add to Firebase:
1. Go to **Project Settings** (gear icon)
2. Select **Your apps** tab
3. Find your Android app: `com.example.sunnah_steps`
4. Click **Add fingerprint**
5. Paste the SHA-1 fingerprint
6. Click **Save**

**⚠️ Important**: Add both debug AND release SHA-1 fingerprints!

### 4. Download Updated google-services.json

1. In **Project Settings** > **Your apps**
2. Click **Download google-services.json**
3. Replace the file in `android/app/google-services.json`

## 🐛 Common Issues & Solutions

### Issue 1: ApiException: 10 (Google Sign-In)

**Cause**: Missing or incorrect SHA-1 fingerprint

**Solution**:
1. Generate SHA-1 fingerprint (see commands above)
2. Add to Firebase Console
3. Download updated `google-services.json`
4. Clean and rebuild app:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --debug
   ```

### Issue 2: Email Sign-Up Fails

**Cause**: Email/Password authentication not enabled

**Solution**:
1. Enable Email/Password in Firebase Console
2. Check error messages in app for specific issues
3. Verify network connection

### Issue 3: Application ID Mismatch

**Current App ID**: `com.example.sunnah_steps`

**Verify in**:
- `android/app/build.gradle.kts`: `applicationId = "com.example.sunnah_steps"`
- Firebase Console: App should match this ID exactly

## 📱 Testing Checklist

### Before Testing:
- [ ] Email/Password enabled in Firebase Console
- [ ] Google Sign-In enabled in Firebase Console
- [ ] SHA-1 fingerprints added (debug + release)
- [ ] Updated `google-services.json` downloaded
- [ ] App rebuilt after configuration changes

### Test Cases:
- [ ] Email sign-up with new account
- [ ] Email sign-in with existing account
- [ ] Google sign-in on real Android device
- [ ] Error handling for invalid credentials
- [ ] Onboarding flow completion
- [ ] Checklist prompt appears once for new users

## 🔍 Debug Commands

### Check SHA-1 fingerprint:
```bash
# Debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1

# Release keystore (if you have one)
keytool -list -v -keystore /path/to/release.keystore -alias your-alias | grep SHA1
```

### Flutter commands:
```bash
# Clean build
flutter clean
flutter pub get

# Debug build
flutter build apk --debug

# Check logs
flutter logs
```

## 📋 Firebase Project Details

- **Project ID**: `sunnah-steps-82d64`
- **Android App ID**: `1:799717436277:android:e82cb357d50c47329fc13c`
- **Package Name**: `com.example.sunnah_steps`

## 🚀 Next Steps

After completing Firebase setup:

1. Test authentication on real Android device
2. Verify onboarding flow works correctly
3. Check that checklist prompt appears once for new users
4. Test error handling for various scenarios

## 📞 Support

If issues persist:
1. Check Firebase Console logs
2. Review Flutter logs with `flutter logs`
3. Verify all configuration steps completed
4. Test on multiple devices if possible
