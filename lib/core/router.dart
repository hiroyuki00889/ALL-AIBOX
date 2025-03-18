import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/auth/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/new_registration_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/chat/buddy_chat_screen.dart';
import '../presentation/screens/chat/past_buddy_chat_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';

// Define routes for the application
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const NewRegistrationScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final String buddyId = state.pathParameters['buddyId'] ?? '';
        return BuddyChatScreen(buddyId: buddyId);
      },
    ),
    GoRoute(
      path: '/past-chats',
      builder: (context, state) => const PastBuddyChatScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);