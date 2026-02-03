import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUser {
  final String uid;
  final int totalChats;
  final DateTime? lastActive;
  final String? email;
  final String? profileName;
  final bool isAnonymous;

  AdminUser({
    required this.uid,
    required this.totalChats,
    this.lastActive,
    this.email,
    this.profileName,
    required this.isAnonymous,
  });

  factory AdminUser.fromMap(String uid, Map<String, dynamic> data, int chatCount) {
    DateTime? lastActive;
    if (data['lastActive'] is Timestamp) {
      lastActive = (data['lastActive'] as Timestamp).toDate();
    } else if (data['lastActive'] is String) {
      lastActive = DateTime.tryParse(data['lastActive'] as String);
    }

    return AdminUser(
      uid: uid,
      totalChats: chatCount,
      lastActive: lastActive,
      email: data['email'],
      profileName: data['displayName'],
      isAnonymous: data['isAnonymous'] ?? (data['email'] == null),
    );
  }

  String get displayName {
    if (profileName != null && profileName!.isNotEmpty) {
      return profileName!;
    }
    if (email != null && email!.isNotEmpty) {
      return email!;
    }
    final String safeUid = uid.length > 8 ? uid.substring(0, 8) : uid;
    return isAnonymous ? 'Guest User' : 'User $safeUid...';
  }

  String get truncatedUid {
    return uid.length > 12 ? '${uid.substring(0, 12)}...' : uid;
  }
}
