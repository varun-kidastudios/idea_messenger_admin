import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_user.dart';
import '../services/firebase_service.dart';

// Firebase service provider
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// Users future provider (manual refresh)
final usersFutureProvider = FutureProvider<List<AdminUser>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getDiscoveredUsers();
});

// Selected user provider
final selectedUserProvider = StateProvider<AdminUser?>((ref) => null);

// Search query provider
final userSearchQueryProvider = StateProvider<String>((ref) => '');

// Filtered users provider
final filteredUsersProvider = Provider<List<AdminUser>>((ref) {
  final usersAsync = ref.watch(usersFutureProvider);
  final searchQuery = ref.watch(userSearchQueryProvider);

  return usersAsync.when(
    data: (users) {
      if (searchQuery.isEmpty) {
        return users;
      }
      
      final lowerQuery = searchQuery.toLowerCase();
      return users.where((user) {
        return user.uid.toLowerCase().contains(lowerQuery) ||
               (user.email?.toLowerCase().contains(lowerQuery) ?? false) ||
               user.displayName.toLowerCase().contains(lowerQuery);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
