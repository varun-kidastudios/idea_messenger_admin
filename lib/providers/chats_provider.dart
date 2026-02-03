import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'users_provider.dart';

// Selected chat provider
final selectedChatProvider = StateProvider<Chat?>((ref) => null);

// Category filter provider
final categoryFilterProvider = StateProvider<String?>((ref) => null);

// Chats stream provider for selected user
final userChatsStreamProvider = StreamProvider.family<List<Chat>, String>((ref, userId) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.watchUserChats(userId);
});

// Filtered chats provider
final filteredChatsProvider = Provider.family<List<Chat>, String>((ref, userId) {
  final chatsAsync = ref.watch(userChatsStreamProvider(userId));
  final categoryFilter = ref.watch(categoryFilterProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);

  return chatsAsync.when(
    data: (chats) {
      return firebaseService.filterChatsByCategory(chats, categoryFilter);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Messages stream provider for selected chat
final chatMessagesStreamProvider = StreamProvider.family<List<Message>, ChatIdentifier>((ref, identifier) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.watchChatMessages(identifier.userId, identifier.chatId);
});

// Helper class to identify a chat
class ChatIdentifier {
  final String userId;
  final String chatId;

  ChatIdentifier({required this.userId, required this.chatId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatIdentifier &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          chatId == other.chatId;

  @override
  int get hashCode => userId.hashCode ^ chatId.hashCode;
}
