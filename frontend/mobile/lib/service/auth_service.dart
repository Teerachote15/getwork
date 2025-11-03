import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:getwork_app/main.dart' as app_main;

class AuthService {
  // Notifiers used by UI to react to changes immediately
  static final ValueNotifier<String?> userId = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> username = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> profileImage = ValueNotifier<String?>(null);

  // Initialize from SharedPreferences
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    userId.value = prefs.getString('userid');
    username.value = prefs.getString('username');
    profileImage.value = prefs.getString('profileImage');
  }

  // Set user info (save to prefs + notify)
  static Future<void> setUser({required String? uid, required String? name, String? image}) async {
    final prefs = await SharedPreferences.getInstance();
    if (uid == null) {
      await prefs.remove('userid');
    } else {
      await prefs.setString('userid', uid);
    }
    if (name == null) {
      await prefs.remove('username');
    } else {
      await prefs.setString('username', name);
    }
    if (image == null) {
      await prefs.remove('profileImage');
    } else {
      await prefs.setString('profileImage', image);
    }

    userId.value = uid;
    username.value = name;
    profileImage.value = image;
  }

  // Logout: clear prefs and notify listeners
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userid');
    await prefs.remove('username');
    await prefs.remove('profileImage');
    await prefs.remove('wallet');

    userId.value = null;
    username.value = null;
    profileImage.value = null;
    // Debug log to help trace logout calls during development
    if (kDebugMode) {
      // ignore: avoid_print
      print('[AuthService] logout executed, cleared SharedPreferences and notifiers');
    }
  }

  // Internal guard to avoid concurrent logout navigations stacking routes
  static bool _isLoggingOut = false;

  /// Convenience: perform logout then navigate to the given route clearing
  /// the navigation stack so the app shows the logged-out UI everywhere.
  // By default redirect to the main route ('/') after logout so the app
  // returns to the home screen and not a profile-specific page.
  static Future<void> logoutAndRedirect({String route = '/profile', bool clearStack = true}) async {
    // Prevent concurrent logout navigations which can produce stacked/overlapping
    // pages when multiple parts of the app invoke logout at once.
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    await logout();
    try {
      final navigator = app_main.navigatorKey.currentState;
      if (navigator != null) {
        // Give UI a brief moment to rebuild after notifiers are cleared so
        // the destination page sees the logged-out state before navigation
        // completes. This reduces races that cause layered routes.
        await Future.delayed(const Duration(milliseconds: 50));
        if (clearStack) {
          // remove all routes then push the destination with a forceLogout flag
          navigator.pushNamedAndRemoveUntil(route, (r) => false, arguments: {'forceLogout': true});
        } else {
          navigator.pushNamed(route, arguments: {'forceLogout': true});
        }
      }
    } catch (_) {
      // ignore navigation errors
    } finally {
      _isLoggingOut = false;
    }
  }
}
