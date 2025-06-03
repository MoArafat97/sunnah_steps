import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase_options.dart';

class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Initialize Firebase
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      // If Firebase is already initialized, this will throw an error
      // We can safely ignore this error as it means Firebase is already ready
      if (e.toString().contains('duplicate-app')) {
        print('Firebase already initialized, continuing...');
      } else {
        // Re-throw if it's a different error
        rethrow;
      }
    }

    // Configure for local development if needed
    if (const bool.fromEnvironment('USE_EMULATOR', defaultValue: false)) {
      await _connectToEmulators();
    }
  }

  /// Connect to Firebase emulators for local development
  static Future<void> _connectToEmulators() async {
    const host = 'localhost';

    // Connect to Auth emulator
    await auth.useAuthEmulator(host, 9099);

    // Connect to Firestore emulator
    firestore.useFirestoreEmulator(host, 8080);
  }

  /// Get current user
  static User? get currentUser => auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get current user's ID token
  static Future<String?> getIdToken() async {
    final user = currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  /// Sign in with email and password
  static Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password
  ) async {
    return await auth.signInWithEmailAndPassword(
      email: email,
      password: password
    );
  }

  /// Create account with email and password
  static Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password
  ) async {
    try {
      return await auth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
    } on FirebaseAuthException catch (e) {
      // Re-throw with more specific error codes for better handling
      switch (e.code) {
        case 'weak-password':
          throw FirebaseAuthException(
            code: 'weak-password',
            message: 'The password provided is too weak. Please choose a stronger password.',
          );
        case 'email-already-in-use':
          throw FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'An account already exists for this email. Please sign in instead.',
          );
        case 'invalid-email':
          throw FirebaseAuthException(
            code: 'invalid-email',
            message: 'The email address is not valid.',
          );
        case 'operation-not-allowed':
          throw FirebaseAuthException(
            code: 'operation-not-allowed',
            message: 'Email/password accounts are not enabled. Please contact support.',
          );
        default:
          rethrow;
      }
    }
  }

  /// Sign in with Google
  static Future<UserCredential> signInWithGoogle() async {
    try {
      // Sign out from Google first to force account selection
      await GoogleSignIn().signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw FirebaseAuthException(
            code: 'account-exists-with-different-credential',
            message: 'An account already exists with the same email address but different sign-in credentials.',
          );
        case 'invalid-credential':
          throw FirebaseAuthException(
            code: 'invalid-credential',
            message: 'The credential received is malformed or has expired.',
          );
        case 'operation-not-allowed':
          throw FirebaseAuthException(
            code: 'operation-not-allowed',
            message: 'Google sign-in is not enabled. Please contact support.',
          );
        case 'user-disabled':
          throw FirebaseAuthException(
            code: 'user-disabled',
            message: 'This user account has been disabled.',
          );
        default:
          rethrow;
      }
    } catch (e) {
      // Handle other errors (like ApiException: 10)
      if (e.toString().contains('ApiException: 10')) {
        throw Exception('Google sign-in configuration error. Please ensure SHA1 fingerprint is added to Firebase Console.');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error. Please check your connection and try again.');
      } else {
        rethrow;
      }
    }
  }

  /// Create user document in Firestore
  static Future<void> createUserDocument(User user) async {
    print('FirebaseService: Creating/updating user document for ${user.email} (UID: ${user.uid})');

    final userDoc = firestore.collection('users').doc(user.uid);

    try {
      // Check if user document already exists
      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        print('FirebaseService: User document does not exist, creating new one');
        await userDoc.set({
          'email': user.email?.toLowerCase(), // Normalize email for consistent lookups
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'hasCompletedOnboarding': false, // Track onboarding completion in Firestore
          'dailyHabits': [], // User's selected daily habits
          'weeklyHabits': [], // User's selected weekly habits
        });
        print('FirebaseService: Successfully created new user document for ${user.email}');
      } else {
        print('FirebaseService: User document exists, updating last login time');
        // Update last login time for existing users
        await userDoc.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        print('FirebaseService: Successfully updated existing user document for ${user.email}');
      }
    } catch (e) {
      print('FirebaseService: Error creating/updating user document for ${user.email}: $e');
      rethrow;
    }
  }

  /// Check if current user has completed onboarding (from Firestore)
  static Future<bool> hasCompletedOnboarding() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['hasCompletedOnboarding'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking onboarding completion: $e');
      return false;
    }
  }

  /// Mark onboarding as completed for current user (in Firestore)
  static Future<void> markOnboardingCompleted() async {
    final user = currentUser;
    if (user == null) return;

    try {
      await firestore.collection('users').doc(user.uid).update({
        'hasCompletedOnboarding': true,
        'onboardingCompletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking onboarding as completed: $e');
      rethrow;
    }
  }

  /// Get user's selected habits from Firestore
  static Future<Map<String, List<String>>> getUserHabits() async {
    final user = currentUser;
    if (user == null) return {'daily': [], 'weekly': []};

    try {
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final dailyHabits = List<String>.from(data['dailyHabits'] ?? []);
        final weeklyHabits = List<String>.from(data['weeklyHabits'] ?? []);
        return {'daily': dailyHabits, 'weekly': weeklyHabits};
      }
      return {'daily': [], 'weekly': []};
    } catch (e) {
      print('Error getting user habits: $e');
      return {'daily': [], 'weekly': []};
    }
  }

  /// Save user's selected habits to Firestore
  static Future<void> saveUserHabits({
    required List<String> dailyHabits,
    required List<String> weeklyHabits,
  }) async {
    final user = currentUser;
    if (user == null) return;

    try {
      await firestore.collection('users').doc(user.uid).update({
        'dailyHabits': dailyHabits,
        'weeklyHabits': weeklyHabits,
        'habitsUpdatedAt': FieldValue.serverTimestamp(),
      });
      print('FirebaseService: Saved user habits - daily: ${dailyHabits.length}, weekly: ${weeklyHabits.length}');
    } catch (e) {
      print('Error saving user habits: $e');
      rethrow;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    // Sign out from Google first
    await GoogleSignIn().signOut();
    // Then sign out from Firebase
    await auth.signOut();
  }

  /// Listen to auth state changes
  static Stream<User?> get authStateChanges => auth.authStateChanges();
}
