import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/sunnah_coaching_service.dart';
import '../../lib/models/sent_sunnah.dart';
import '../../lib/models/habit_item.dart';

void main() {
  group('SunnahCoachingService', () {
    late SunnahCoachingService service;

    setUp(() {
      service = SunnahCoachingService.instance;
    });

    group('SentSunnah Model', () {
      test('should create SentSunnah from constructor', () {
        // Arrange & Act
        final sentSunnah = SentSunnah(
          id: 'test123',
          senderId: 'sender456',
          recipientId: 'recipient789',
          habitId: 'habit123',
          habitTitle: 'Read Quran daily',
          note: 'This habit brings peace',
          status: 'pending',
          timestamp: DateTime(2024, 1, 1),
          senderEmail: 'sender@example.com',
        );

        // Assert
        expect(sentSunnah.id, equals('test123'));
        expect(sentSunnah.senderId, equals('sender456'));
        expect(sentSunnah.recipientId, equals('recipient789'));
        expect(sentSunnah.habitId, equals('habit123'));
        expect(sentSunnah.habitTitle, equals('Read Quran daily'));
        expect(sentSunnah.note, equals('This habit brings peace'));
        expect(sentSunnah.status, equals('pending'));
        expect(sentSunnah.senderEmail, equals('sender@example.com'));
      });

      test('should convert to and from Firestore format', () {
        // Arrange
        final originalSunnah = SentSunnah(
          id: 'test123',
          senderId: 'sender456',
          recipientId: 'recipient789',
          habitId: 'habit123',
          habitTitle: 'Read Quran daily',
          note: 'This habit brings peace',
          status: 'pending',
          timestamp: DateTime(2024, 1, 1),
          senderEmail: 'sender@example.com',
        );

        // Act
        final firestoreData = originalSunnah.toFirestore();

        // Assert Firestore format
        expect(firestoreData['sender_id'], equals('sender456'));
        expect(firestoreData['recipient_id'], equals('recipient789'));
        expect(firestoreData['habit_id'], equals('habit123'));
        expect(firestoreData['habit_title'], equals('Read Quran daily'));
        expect(firestoreData['note'], equals('This habit brings peace'));
        expect(firestoreData['status'], equals('pending'));
        expect(firestoreData['sender_email'], equals('sender@example.com'));
      });

      test('should create copy with updated fields', () {
        // Arrange
        final originalSunnah = SentSunnah(
          id: 'test123',
          senderId: 'sender456',
          recipientId: 'recipient789',
          habitId: 'habit123',
          habitTitle: 'Read Quran daily',
          note: 'This habit brings peace',
          status: 'pending',
          timestamp: DateTime(2024, 1, 1),
          senderEmail: 'sender@example.com',
        );

        // Act
        final updatedSunnah = originalSunnah.copyWith(
          status: 'accepted',
          note: 'Updated note',
        );

        // Assert
        expect(updatedSunnah.id, equals('test123')); // Unchanged
        expect(updatedSunnah.status, equals('accepted')); // Changed
        expect(updatedSunnah.note, equals('Updated note')); // Changed
        expect(updatedSunnah.habitTitle, equals('Read Quran daily')); // Unchanged
      });
    });

    group('HabitItem Model', () {
      test('should create HabitItem from constructor', () {
        // Arrange & Act
        final habitItem = HabitItem(
          name: 'Read Quran daily',
          completed: true,
        );

        // Assert
        expect(habitItem.name, equals('Read Quran daily'));
        expect(habitItem.completed, isTrue);
      });

      test('should create HabitItem with default completed value', () {
        // Arrange & Act
        final habitItem = HabitItem(name: 'Dhikr after prayer');

        // Assert
        expect(habitItem.name, equals('Dhikr after prayer'));
        expect(habitItem.completed, isFalse); // Default value
      });

      test('should convert to and from JSON', () {
        // Arrange
        final originalHabit = HabitItem(
          name: 'Morning Adhkar',
          completed: true,
        );

        // Act
        final json = originalHabit.toJson();
        final recreatedHabit = HabitItem.fromJson(json);

        // Assert
        expect(json['name'], equals('Morning Adhkar'));
        expect(json['completed'], isTrue);
        expect(recreatedHabit.name, equals('Morning Adhkar'));
        expect(recreatedHabit.completed, isTrue);
      });

      test('should create copy with updated fields', () {
        // Arrange
        final originalHabit = HabitItem(
          name: 'Evening Adhkar',
          completed: false,
        );

        // Act
        final updatedHabit = originalHabit.copyWith(completed: true);

        // Assert
        expect(originalHabit.completed, isFalse); // Original unchanged
        expect(updatedHabit.name, equals('Evening Adhkar')); // Same name
        expect(updatedHabit.completed, isTrue); // Updated field
      });

      test('should handle JSON with missing fields gracefully', () {
        // Arrange
        final incompleteJson = <String, dynamic>{}; // Empty JSON

        // Act
        final habitItem = HabitItem.fromJson(incompleteJson);

        // Assert
        expect(habitItem.name, equals('')); // Default empty string
        expect(habitItem.completed, isFalse); // Default false
      });
    });
  });
}
