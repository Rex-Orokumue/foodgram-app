//import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/secure_storage.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/post/screens/create_post_screen.dart';
import '../../features/post/screens/post_detail_screen.dart';
import '../../features/stories/screens/story_viewer_screen.dart';
import '../../features/recipe/screens/recipe_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../shared/widgets/main_shell.dart';

// Route names
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String feed = '/feed';
  static const String profile = '/profile';
  static const String profileUser = '/profile/:username';
  static const String createPost = '/create-post';
  static const String postDetail = '/post/:postId';
  static const String storyViewer = '/stories/:userId';
  static const String recipe = '/recipe/:postId';
  static const String orders = '/orders';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) async {
      final isLoggedIn = await SecureStorage.isLoggedIn();
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.splash;

      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main shell — bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.feed,
            builder: (context, state) => const FeedScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.orders,
            builder: (context, state) => const OrdersScreen(),
          ),
        ],
      ),

      // Individual screens
      GoRoute(
        path: AppRoutes.profileUser,
        builder: (context, state) {
          final username = state.pathParameters['username']!;
          return ProfileScreen(username: username);
        },
      ),
      GoRoute(
        path: AppRoutes.createPost,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: AppRoutes.postDetail,
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: AppRoutes.storyViewer,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return StoryViewerScreen(userId: userId);
        },
      ),
      GoRoute(
        path: AppRoutes.recipe,
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return RecipeScreen(postId: postId);
        },
      ),
    ],
  );
});