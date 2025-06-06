import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sent_sunnah.dart';
import '../models/habit_item.dart';
import '../services/firebase_service.dart';
import '../services/checklist_service.dart';

/// Service for peer-to-peer Sunnah coaching functionality
class SunnahCoachingService {
  static final SunnahCoachingService _instance = SunnahCoachingService._internal();
  factory SunnahCoachingService() => _instance;
  SunnahCoachingService._internal();

  static SunnahCoachingService get instance => _instance;

  /// Send a Sunnah recommendation to another user
  Future<void> sendSunnahToFriend({
    required String recipientEmail,
    required String habitId,
    required String habitTitle,
    String? note,
  }) async {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to send Sunnah recommendations');
    }

    print('SunnahCoachingService: Attempting to send Sunnah from ${currentUser.email} to $recipientEmail');

    // Ensure current user's document exists
    try {
      await FirebaseService.createUserDocument(currentUser);
      print('SunnahCoachingService: Ensured sender user document exists');
    } catch (e) {
      print('SunnahCoachingService: Error ensuring sender user document: $e');
      throw Exception('Failed to prepare sender account: $e');
    }

    // Find recipient by email
    final normalizedEmail = recipientEmail.trim().toLowerCase();
    print('SunnahCoachingService: Looking up recipient by email: $normalizedEmail');

    final recipientQuery = await FirebaseService.firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    print('SunnahCoachingService: Email lookup query returned ${recipientQuery.docs.length} results');

    if (recipientQuery.docs.isEmpty) {
      print('SunnahCoachingService: No user found with email $normalizedEmail');
      throw Exception('User with email $normalizedEmail not found. They may need to create an account first.');
    }

    final recipientId = recipientQuery.docs.first.id;
    print('SunnahCoachingService: Found recipient with ID: $recipientId');

    // Don't allow sending to yourself
    if (recipientId == currentUser.uid) {
      throw Exception('You cannot send Sunnah recommendations to yourself');
    }

    // Create the recommendation document
    final sentSunnah = SentSunnah(
      id: '', // Will be set by Firestore
      senderId: currentUser.uid,
      recipientId: recipientId,
      habitId: habitId,
      habitTitle: habitTitle,
      note: note?.trim(),
      status: 'pending',
      timestamp: DateTime.now(),
      senderEmail: currentUser.email,
    );

    print('SunnahCoachingService: Creating Sunnah document with senderId: ${currentUser.uid}');

    // Save to Firestore
    try {
      final docRef = await FirebaseService.firestore
          .collection('sent_sunnahs')
          .add(sentSunnah.toFirestore());
      print('SunnahCoachingService: Successfully created Sunnah document with ID: ${docRef.id}');
    } catch (e) {
      print('SunnahCoachingService: Error creating Sunnah document: $e');
      throw Exception('Failed to send Sunnah recommendation: $e');
    }
  }

  /// Get all Sunnah recommendations received by the current user
  Stream<List<SentSunnah>> getReceivedRecommendations() {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return FirebaseService.firestore
        .collection('sent_sunnahs')
        .where('recipient_id', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SentSunnah.fromFirestore(doc))
            .toList());
  }

  /// Get all Sunnah recommendations sent by the current user
  Stream<List<SentSunnah>> getSentRecommendations() {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return FirebaseService.firestore
        .collection('sent_sunnahs')
        .where('sender_id', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SentSunnah.fromFirestore(doc))
            .toList());
  }

  /// Accept a Sunnah recommendation and add it to user's habit list
  Future<void> acceptRecommendation(String recommendationId) async {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to accept recommendations');
    }

    // Get the recommendation document
    final docRef = FirebaseService.firestore
        .collection('sent_sunnahs')
        .doc(recommendationId);
    
    final doc = await docRef.get();
    if (!doc.exists) {
      throw Exception('Recommendation not found');
    }

    final recommendation = SentSunnah.fromFirestore(doc);
    
    // Verify the current user is the recipient
    if (recommendation.recipientId != currentUser.uid) {
      throw Exception('You can only accept recommendations sent to you');
    }

    // Update the recommendation status
    await docRef.update({'status': 'accepted'});

    // Add the habit to the user's checklist
    // Note: This integrates with the existing ChecklistService
    final habitItem = HabitItem(
      name: recommendation.habitTitle,
      completed: false,
    );

    // Add to the user's daily habits (you may want to make this configurable)
    await ChecklistService.instance.addHabitToUserList(habitItem, 'daily');
  }

  /// Decline a Sunnah recommendation
  Future<void> declineRecommendation(String recommendationId) async {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to decline recommendations');
    }

    // Get the recommendation document
    final docRef = FirebaseService.firestore
        .collection('sent_sunnahs')
        .doc(recommendationId);
    
    final doc = await docRef.get();
    if (!doc.exists) {
      throw Exception('Recommendation not found');
    }

    final recommendation = SentSunnah.fromFirestore(doc);
    
    // Verify the current user is the recipient
    if (recommendation.recipientId != currentUser.uid) {
      throw Exception('You can only decline recommendations sent to you');
    }

    // Update the recommendation status
    await docRef.update({'status': 'declined'});
  }

  /// Delete a Sunnah recommendation permanently
  Future<void> deleteRecommendation(String recommendationId) async {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      throw Exception('User must be authenticated to delete recommendations');
    }

    // Get the recommendation document
    final docRef = FirebaseService.firestore
        .collection('sent_sunnahs')
        .doc(recommendationId);

    final doc = await docRef.get();
    if (!doc.exists) {
      throw Exception('Recommendation not found');
    }

    final recommendation = SentSunnah.fromFirestore(doc);

    // Verify the current user is the recipient
    if (recommendation.recipientId != currentUser.uid) {
      throw Exception('You can only delete recommendations sent to you');
    }

    // Delete the recommendation permanently
    await docRef.delete();

    print('SunnahCoachingService: Recommendation $recommendationId deleted');
  }

  /// Get count of pending recommendations for the current user
  Future<int> getPendingRecommendationsCount() async {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      return 0;
    }

    final snapshot = await FirebaseService.firestore
        .collection('sent_sunnahs')
        .where('recipient_id', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.length;
  }

  /// Check if a user exists by email
  Future<bool> userExistsByEmail(String email) async {
    try {
      final query = await FirebaseService.firestore
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
