import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for Sunnah recommendations sent between users
class SentSunnah {
  final String id;
  final String senderId;
  final String recipientId;
  final String habitId;
  final String habitTitle;
  final String? note;
  final String status; // "pending", "accepted", "declined"
  final DateTime timestamp;
  final String? senderEmail; // For display purposes

  const SentSunnah({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.habitId,
    required this.habitTitle,
    this.note,
    required this.status,
    required this.timestamp,
    this.senderEmail,
  });

  /// Create from Firestore document
  factory SentSunnah.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SentSunnah(
      id: doc.id,
      senderId: data['sender_id'] ?? '',
      recipientId: data['recipient_id'] ?? '',
      habitId: data['habit_id'] ?? '',
      habitTitle: data['habit_title'] ?? '',
      note: data['note'],
      status: data['status'] ?? 'pending',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      senderEmail: data['sender_email'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'sender_id': senderId,
      'recipient_id': recipientId,
      'habit_id': habitId,
      'habit_title': habitTitle,
      'note': note,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'sender_email': senderEmail,
    };
  }

  /// Create a copy with updated fields
  SentSunnah copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? habitId,
    String? habitTitle,
    String? note,
    String? status,
    DateTime? timestamp,
    String? senderEmail,
  }) {
    return SentSunnah(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      habitId: habitId ?? this.habitId,
      habitTitle: habitTitle ?? this.habitTitle,
      note: note ?? this.note,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      senderEmail: senderEmail ?? this.senderEmail,
    );
  }

  @override
  String toString() {
    return 'SentSunnah(id: $id, senderId: $senderId, recipientId: $recipientId, habitTitle: $habitTitle, status: $status)';
  }
}
