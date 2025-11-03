import 'package:flutter/material.dart';
// เพิ่ม import ถ้าจำเป็น
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:getwork_app/service/auth_service.dart'; // add
import 'package:getwork_app/widgets/bottom_nav_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int? userId;
  String? username;
  String? authToken; // <-- new
  String? _profileImageUrl; // added
  final String baseUrl = 'http://192.168.1.179:4000';

  @override
  void initState() {
    super.initState();
    // Use AuthService instead of reading SharedPreferences directly
    // React to changes so logout is reflected immediately
    AuthService.userId.addListener(_onAuthChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLoginAndMaybeRedirect());
  }

  @override
  void dispose() {
    AuthService.userId.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    // If user became logged out, clear local state so logged-out UI is shown.
    final uid = AuthService.userId.value;
    if (uid == null) {
      _clearLocalUserState();
      return;
    }
    // If user became logged in, simply refresh local state (DO NOT navigate here)
    // This avoids pushing another route on top of current one and causing overlap.
    final id = int.tryParse(uid) ?? 0;
    if (id > 0) {
      // refresh profile data but do not Navigator.push/replace
      _fetchProfileFromApi(id).then((profile) {
        if (profile != null && mounted) {
          final prefsFuture = SharedPreferences.getInstance();
          prefsFuture.then((prefs) async {
            final serverUsername = (profile['displayname'] ?? profile['username'])?.toString() ?? AuthService.username.value ?? '';
            await prefs.setString('username', serverUsername);
            final image = profile['image']?.toString();
            if (image != null) {
              await prefs.setString('profileImage', image);
              AuthService.profileImage.value = image;
            }
            AuthService.username.value = serverUsername;
            // update local UI
            if (mounted) {
              setState(() {
              username = serverUsername;
              _profileImageUrl = profile['image']?.toString();
            });
            }
          });
        }
      }).catchError((_) {});
      return;
    }
  }

  Future<void> _checkLoginAndMaybeRedirect() async {
    // Prefer AuthService for authoritative state
    final uid = AuthService.userId.value;
    final uname = AuthService.username.value;
    final token = (await SharedPreferences.getInstance()).getString('authToken'); // optional
    if (uid == null || uid.isEmpty) {
      // Not logged in — clear any cached local state so UI shows logged-out view
      // (do NOT read values from SharedPreferences here). Keep things simple:
      if (!mounted) return;
      setState(() {
        userId = null;
        username = null; // do not display any cached username after logout
        authToken = null;
        _profileImageUrl = null; // do not display cached profile image after logout
      });
      return;
    }
    // logged in -> refresh profile data but DO NOT navigate from here
    final id = int.tryParse(uid) ?? 0;
    if (id > 0) {
      final profile = await _fetchProfileFromApi(id);
      if (profile != null) {
        final prefs = await SharedPreferences.getInstance();
        final serverUsername = (profile['displayname'] ?? profile['username'])?.toString() ?? uname ?? '';
        await prefs.setString('username', serverUsername);
        final image = profile['image']?.toString();
        if (image != null) {
          await prefs.setString('profileImage', image);
          AuthService.profileImage.value = image;
        }
        AuthService.username.value = serverUsername;
        if (!mounted) return;
        setState(() {
          userId = id;
          username = serverUsername;
          _profileImageUrl = profile['image']?.toString();
        });
      }
      return;
    }
  }

  dynamic _tryParseJson(String? text) {
    if (text == null) return null;
    final t = text.trim();
    if (t.isEmpty) return null;
    try {
      return jsonDecode(t);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchProfileFromApi(int userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/account/profile?user_id=$userId'));
      if (res.statusCode == 200) {
        final parsed = _tryParseJson(res.body) as Map<String, dynamic>?;
        if (parsed == null) return null;
        final map = parsed;
        // normalize image
        if (map['image'] != null && map['image'] is String) {
          var img = map['image'] as String;
          if (img.startsWith('/')) img = '$baseUrl$img';
          map['image'] = img;
        }
        return map;
      }
    } catch (_) {}
    return null;
  }

  // Helper: login POST snippet (copied from login_page.dart).
  // Call this manually if needed; it will save authToken/userid/username to prefs.
  Future<Map<String, dynamic>?> _loginPostSnippet(String uname, String pwd) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': uname.trim(),
          'password': pwd,
        }),
      );

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      if (response.statusCode == 200 && data['data'] != null && data['data']['authToken'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', data['data']['authToken']);
        final userId = data['data']['userid'];
        await prefs.setString('userid', userId.toString());
        await prefs.setString('username', uname);
        return data;
      } else {
        return data; // caller can inspect for errors
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  void _clearLocalUserState() {
    if (!mounted) return;
    setState(() {
      userId = null;
      username = null;
      authToken = null;
      _profileImageUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
  final argUserId = args['userid'];
  final argUsername = args['username'];
  final forceLogout = args['forceLogout'] == true;
    // Make the UI reactive to changes in AuthService.userId/username so logout
    // updates the UI immediately. We prioritize a `forceLogout` route arg.
    return ValueListenableBuilder<String?>(
      valueListenable: AuthService.userId,
      builder: (context, liveUserId, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: AuthService.username,
          builder: (context, liveUsername, __) {
            // prefer passed args, otherwise use live AuthService state
            final effectiveUserId = forceLogout
                ? null
                : (argUserId ?? (liveUserId != null ? int.tryParse(liveUserId) : null));
            final effectiveUsername = forceLogout ? null : (argUsername ?? liveUsername);
            final effectiveToken = authToken; // kept for display if present

            // When effectiveUserId is null -> show logged-out UI (Login/Register).
            // Treat presence of a userId as authoritative for "logged in" even if
            // the username is temporarily missing. This avoids showing the
            // Register/Login buttons when the app actually has a userid saved.
            if (effectiveUserId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            color: const Color(0xFF3A5A99),
            child: SafeArea(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      // When logged out we must not show any user-provided image.
                      // Always show the app logo instead.
                      backgroundImage: const AssetImage('assets/images/logogetwork.png'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 100),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      foregroundColor: const Color(0xFF357393),
                    ),
                    child: Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        color: const Color(0xFF357393),
                        fontWeight: FontWeight.w500,
                        fontSize: 18 * textScale,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 160,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/register');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      foregroundColor: const Color(0xFF357393),
                    ),
                    child: Text(
                      'สมัครสมาชิก',
                      style: TextStyle(
                        color: const Color(0xFF357393),
                        fontWeight: FontWeight.w500,
                        fontSize: 18 * textScale,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF3A5A99),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white,
          onTap: (index) {
            final uid = effectiveUserId;
            final uname = effectiveUsername;
            final loggedIn = uid != null;
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, '/', arguments: {'userid': uid, 'username': uname});
                break;
              case 1:
                if (loggedIn) {
                  Navigator.pushReplacementNamed(context, '/status', arguments: {'userid': uid, 'username': uname});
                } else {
                  Navigator.pushReplacementNamed(context, '/login');
                }
                break;
              case 2:
                if (loggedIn) {
                  Navigator.pushReplacementNamed(context, '/postJob', arguments: {'userid': uid, 'username': uname});
                } else {
                  Navigator.pushReplacementNamed(context, '/login');
                }
                break;
              case 3:
                if (loggedIn) {
                  Navigator.pushReplacementNamed(context, '/notifications', arguments: {'userid': uid, 'username': uname});
                } else {
                  Navigator.pushReplacementNamed(context, '/login');
                }
                break;
              case 4:
                if (loggedIn) {
                  Navigator.pushReplacementNamed(context, '/paymentPage', arguments: {'userid': uid, 'username': uname});
                } else {
                  Navigator.pushReplacementNamed(context, '/profile', arguments: {'userid': uid, 'username': uname});
                }
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/homepage.png')),
              label: 'หน้าหลัก',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/status.png')),
              label: 'สถานะ',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/postjob.png')),
              label: 'โพสต์',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/notification.png')),
              label: 'แจ้งเตือน',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/images/profile.png')),
              label: 'โปรไฟล์',
            ),
          ],
        ),
      );
    }

    // ถ้าเข้าสู่ระบบแล้ว แสดงชื่อผู้ใช้และข้อมูลบัญชี
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          color: const Color(0xFF3A5A99),
          child: SafeArea(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                    child: _profileImageUrl == null
                        ? ClipOval(
                            child: Image.asset(
                              'assets/images/logogetwork.png',
                              width: 56,
                              height: 56,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                // แสดงชื่อผู้ใช้ และ user id
                if (effectiveUsername != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        effectiveUsername,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22 * textScale,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (effectiveUserId != null)
                        Text(
                          'User ID: $effectiveUserId',
                          style: TextStyle(color: Colors.white70, fontSize: 12 * textScale),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    try {
                      await AuthService.logoutAndRedirect();
                    } catch (_) {}
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('ออกจากระบบ', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4,
        onTap: (index) {
          final uid = effectiveUserId;
          final uname = effectiveUsername;
          final loggedIn = uid != null;

          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/', arguments: {'userid': uid, 'username': uname});
              break;
            case 1:
              if (loggedIn) {
                Navigator.pushReplacementNamed(context, '/status', arguments: {'userid': uid, 'username': uname});
              } else {
                Navigator.pushReplacementNamed(context, '/login');
              }
              break;
            case 2:
              if (loggedIn) {
                Navigator.pushReplacementNamed(context, '/postJob', arguments: {'userid': uid, 'username': uname});
              } else {
                Navigator.pushReplacementNamed(context, '/login');
              }
              break;
            case 3:
              if (loggedIn) {
                Navigator.pushReplacementNamed(context, '/notifications', arguments: {'userid': uid, 'username': uname});
              } else {
                Navigator.pushReplacementNamed(context, '/login');
              }
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/paymentPage', arguments: {'userid': uid, 'username': uname});
              break;
          }
        },
      ),
    );
          },
        );
      },
    );
  }
}




