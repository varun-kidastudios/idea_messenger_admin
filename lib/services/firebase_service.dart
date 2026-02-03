import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_user.dart';
import '../models/chat.dart';
import '../models/message.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // ==================== STATS OPERATIONS ====================

  /// Gets global application statistics using efficient aggregation queries
  Future<Map<String, int>> getGlobalStats() async {
    try {
      final userCountQueryResult = await _firestore.collection('users').count().get();
      final chatCountQueryResult = await _firestore.collectionGroup('chats').count().get();
      final messageCountQueryResult = await _firestore.collectionGroup('messages').count().get();

      return {
        'totalUsers': userCountQueryResult.count ?? 0,
        'totalChats': chatCountQueryResult.count ?? 0,
        'totalMessages': messageCountQueryResult.count ?? 0,
      };
    } catch (e) {
      print('Error fetching global stats: $e');
      return {
        'totalUsers': 0,
        'totalChats': 0,
        'totalMessages': 0,
      };
    }
  }

  // ==================== USER OPERATIONS ====================

  /// Fetches all users from Firestore
  Future<List<AdminUser>> getAllUsers() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      
      List<AdminUser> users = [];
      for (var userDoc in usersSnapshot.docs) {
        // Count chats for this user
        final chatsSnapshot = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('chats')
            .get();
        
        final chatCount = chatsSnapshot.docs.length;
        
        // Create AdminUser
        users.add(AdminUser.fromMap(
          userDoc.id,
          userDoc.data(),
          chatCount,
        ));
      }
      
      // Sort by total chats (most active first)
      users.sort((a, b) => b.totalChats.compareTo(a.totalChats));
      
      return users;
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  /// Fetches all users (including discovered guest accounts) for manual refresh
  Future<List<AdminUser>> getDiscoveredUsers() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> usersMap = {
        for (var doc in usersSnapshot.docs) doc.id: doc
      };

      final Set<String> allUserIds = usersMap.keys.toSet();

      // Discovery fallback
      try {
        final chatsGroup = await _firestore.collectionGroup('chats').limit(100).get();
        for (var doc in chatsGroup.docs) {
          final parentId = doc.reference.parent.parent?.id;
          if (parentId != null) allUserIds.add(parentId);
        }
      } catch (e) {
        print('Discovery failed: $e');
      }

      List<AdminUser> users = [];
      for (var uid in allUserIds) {
        try {
          // Count chats for this user
          final chatsSnapshot = await _firestore
              .collection('users')
              .doc(uid)
              .collection('chats')
              .get();
          
          final chatCount = chatsSnapshot.docs.length;
          final userDoc = usersMap[uid];

          users.add(AdminUser.fromMap(
            uid,
            userDoc != null ? userDoc.data() : {},
            chatCount,
          ));
        } catch (e) {
          print('Error processing user $uid: $e');
        }
      }
      
      users.sort((a, b) => b.totalChats.compareTo(a.totalChats));
      return users;
    } catch (e) {
      print('Error in getDiscoveredUsers: $e');
      return [];
    }
  }

  /// Stream of all users (real-time updates) - KEEPING for backward compatibility if needed, 
  /// but UI will transition to manual refresh.
  Stream<List<AdminUser>> watchUsers() {
    print('DEBUG: watchUsers started');
    return _firestore.collection('users').snapshots().asyncMap((snapshot) async {
      print('DEBUG: watchUsers received snapshot with ${snapshot.docs.length} docs');
      
      final Set<String> userIds = snapshot.docs.map((doc) => doc.id).toSet();

      // Discovery fallback: Search for users who have chats but no user document
      print('DEBUG: Attempting discovery via chats collectionGroup...');
      try {
        final chatsGroup = await _firestore.collectionGroup('chats').limit(100).get();
        final discoveredIds = chatsGroup.docs
            .map((doc) => doc.reference.parent.parent?.id)
            .whereType<String>();
        
        userIds.addAll(discoveredIds);
        print('DEBUG: Total unique user IDs after discovery: ${userIds.length}');
      } catch (e) {
        print('DEBUG: Collection group discovery failed (likely missing index): $e');
      }

      List<AdminUser> users = [];
      for (var uid in userIds) {
        try {
          final chatsSnapshot = await _firestore
              .collection('users')
              .doc(uid)
              .collection('chats')
              .get();
          
          final chatCount = chatsSnapshot.docs.length;
          
          // Fetch the user doc specifically for metadata if it exists
          final userDoc = await _firestore.collection('users').doc(uid).get();
          
          users.add(AdminUser.fromMap(
            uid,
            userDoc.data() ?? {},
            chatCount,
          ));
        } catch (e) {
          print('DEBUG: Error processing user $uid: $e');
        }
      }
      
      users.sort((a, b) => b.totalChats.compareTo(a.totalChats));
      print('DEBUG: watchUsers returning ${users.length} users');
      return users;
    }).handleError((error) {
      print('DEBUG: watchUsers stream error: $error');
      throw error;
    });
  }

  // ==================== CHAT OPERATIONS ====================

  /// Fetches all chats for a specific user
  Future<List<Chat>> getUserChats(String userId) async {
    try {
      final chatsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .orderBy('updatedAt', descending: true)
          .get();
      
      List<Chat> chats = [];
      for (var chatDoc in chatsSnapshot.docs) {
        // Count messages for this chat
        final messagesSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('chats')
            .doc(chatDoc.id)
            .collection('messages')
            .get();
        
        final messageCount = messagesSnapshot.docs.length;
        
        chats.add(Chat.fromMap(
          chatDoc.id,
          chatDoc.data(),
          messageCount,
        ));
      }
      
      return chats;
    } catch (e) {
      print('Error fetching chats for user $userId: $e');
      return [];
    }
  }

  /// Stream of chats for a user (real-time updates)
  Stream<List<Chat>> watchUserChats(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .snapshots()
        .asyncMap((snapshot) async {
      List<Chat> chats = [];
      
      for (var chatDoc in snapshot.docs) {
        try {
          final chatData = chatDoc.data();
          
          // 1. Get messages from legacy array
          final List<dynamic> legacyMessages = chatData['messages'] ?? [];
          final Set<String> uniqueMessageIds = legacyMessages.map((m) => m['id'] as String? ?? '').where((id) => id.isNotEmpty).toSet();
          
          // 2. Get messages from new sub-collection
          final messagesSnapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('chats')
              .doc(chatDoc.id)
              .collection('messages')
              .get();
          
          for (var doc in messagesSnapshot.docs) {
            uniqueMessageIds.add(doc.id);
          }
          
          final messageCount = uniqueMessageIds.length;
          
          chats.add(Chat.fromMap(
            chatDoc.id,
            chatData,
            messageCount,
          ));
        } catch (e) {
          print('DEBUG: Error processing chat ${chatDoc.id}: $e');
        }
      }
      
      chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return chats;
    });
  }

  // ==================== MESSAGE OPERATIONS ====================

  /// Fetches all messages for a specific chat
  Future<List<Message>> getChatMessages(String userId, String chatId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();
      
      return messagesSnapshot.docs
          .map((doc) => Message.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching messages for chat $chatId: $e');
      return [];
    }
  }

  /// Stream of messages for a chat (real-time updates)
  Stream<List<Message>> watchChatMessages(String userId, String chatId) {
    // Listen to the chat document itself to get legacy messages array
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .asyncMap((docSnapshot) async {
      final Map<String, Message> allMessages = {};
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['messages'] is List) {
          final List<dynamic> legacyMessages = data['messages'];
          for (var m in legacyMessages) {
            try {
              final Map<String, dynamic> msgData = Map<String, dynamic>.from(m);
              final id = msgData['id'] ?? 'legacy_${allMessages.length}';
              allMessages[id] = Message.fromMap(id, msgData);
            } catch (e) {
              print('DEBUG: Error parsing legacy message: $e');
            }
          }
        }
      }

      // Also fetch messages from the new sub-collection
      try {
        final messagesSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .get();
        
        for (var doc in messagesSnapshot.docs) {
          try {
            allMessages[doc.id] = Message.fromMap(doc.id, doc.data());
          } catch (e) {
            print('Error parsing sub-collection message ${doc.id}: $e');
          }
        }
      } catch (e) {
        print('Error fetching messages sub-collection: $e');
      }

      final List<Message> sortedMessages = allMessages.values.toList();
      sortedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      return sortedMessages;
    });
  }

  // ==================== SEARCH & FILTER ====================

  /// Search users by email or UID
  Future<List<AdminUser>> searchUsers(String query) async {
    try {
      final allUsers = await getAllUsers();
      
      final lowerQuery = query.toLowerCase();
      return allUsers.where((user) {
        return user.uid.toLowerCase().contains(lowerQuery) ||
               (user.email?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Filter chats by category
  List<Chat> filterChatsByCategory(List<Chat> chats, String? categoryId) {
    if (categoryId == null || categoryId.isEmpty || categoryId == 'all') {
      return chats;
    }
    return chats.where((chat) => chat.categoryId == categoryId).toList();
  }
}
