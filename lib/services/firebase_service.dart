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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

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
    return await auth.createUserWithEmailAndPassword(
      email: email,
      password: password
    );
  }

  /// Sign in with Google
  static Future<UserCredential> signInWithGoogle() async {
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
  }

  /// Sign out
  static Future<void> signOut() async {
    await auth.signOut();
  }

  /// Listen to auth state changes
  static Stream<User?> get authStateChanges => auth.authStateChanges();
}
