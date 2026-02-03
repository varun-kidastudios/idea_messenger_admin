import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'users_provider.dart';

final statsProvider = FutureProvider<Map<String, int>>((ref) async {
  final firebaseService = ref.watch(firebaseServiceProvider);
  // Auto-refresh stats when users change, but throttle it if needed.
  // For now, we'll just fetch once or on explicit refresh.
  return firebaseService.getGlobalStats();
});
