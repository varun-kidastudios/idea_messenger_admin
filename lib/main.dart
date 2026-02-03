import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/users_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: IdeaMessengerAdminApp(),
    ),
  );
}

class IdeaMessengerAdminApp extends ConsumerWidget {
  const IdeaMessengerAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CupertinoApp(
      title: 'idea_messenger Admin',
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
        brightness: Brightness.light,
      ),
      home: const UsersListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        return const UsersListScreen();
      },
      loading: () => const CupertinoPageScaffold(
        child: Center(
          child: CupertinoActivityIndicator(radius: 16),
        ),
      ),
      error: (error, stack) => CupertinoPageScaffold(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 64,
                color: CupertinoColors.systemRed,
              ),
              const SizedBox(height: 16),
              const Text(
                'Authentication Error',
                style: TextStyle(
                  fontSize: 18,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
