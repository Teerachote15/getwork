import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'report_issue_page.dart';
import 'package:getwork_app/service/auth_service.dart';
import 'package:getwork_app/main.dart' as app_main;

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

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? userIdStr;
  String? username;
  double wallet = 0.0;
  String? profileImageUrl;
  // Ensure this matches the main backend host used across the app.
  final String baseUrl = 'http://192.168.100.11:4000';
  bool _isLoggingOut = false; // new: prevent multi-click logout

  @override
  void initState() {
    super.initState();
    // listen for auth changes so logout elsewhere updates this page
    AuthService.userId.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthService.userId.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final uid = AuthService.userId.value;
    if (uid == null) {
      // logged out -> clear local state (do NOT navigate here)
      if (mounted) {
        setState(() {
          userIdStr = null;
          username = null;
          profileImageUrl = null;
          wallet = 0.0;
        });
      }
      return;
    }
    // logged in -> refresh profile data only (no navigation)
    final id = int.tryParse(uid) ?? 0;
    if (id > 0) {
      _fetchFullProfile(id);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final argUserId = args['userid'];
    final argUsername = args['username'];
    if (argUserId != null || argUsername != null) {
      userIdStr = argUserId?.toString();
      username = argUsername?.toString();
      if (argUserId != null) _fetchFullProfile(int.tryParse(argUserId.toString()) ?? 0);
      return;
    }
    _loadFromPrefsIfNeeded().then((_) {
      final id = int.tryParse(userIdStr ?? '') ?? 0;
      if (id > 0) _fetchFullProfile(id);
    });
  }

  Future<void> _loadFromPrefsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUid = prefs.getString('userid');
    final storedUname = prefs.getString('username');
    final storedImage = prefs.getString('profileImage');
    if (!mounted) return;
    setState(() {
      userIdStr = storedUid;
      username = storedUname;
      profileImageUrl = storedImage;
    });
  }

  Future<void> _fetchFullProfile(int userId) async {
    if (userId == 0) return;
    try {
      final res = await http.get(Uri.parse('$baseUrl/account/profile?user_id=$userId'));
      if (res.statusCode == 200) {
        final parsed = _tryParseJson(res.body) as Map<String, dynamic>?;
        if (parsed == null) return;
        final data = parsed;
        final moneyVal = data['money'];
        final money = moneyVal != null ? double.tryParse(moneyVal.toString()) ?? (moneyVal as num?)?.toDouble() ?? 0.0 : 0.0;
        final serverName = (data['displayname'] ?? data['username'])?.toString() ?? '';
        String? img;
        if (data['image'] != null) {
          img = data['image'].toString();
          if (img.startsWith('/')) img = '$baseUrl$img';
        }
        // persist in AuthService & prefs
        await AuthService.setUser(uid: userId.toString(), name: serverName.isNotEmpty ? serverName : null, image: img);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userid', userId.toString());
        if (serverName.isNotEmpty) await prefs.setString('username', serverName);
        if (img != null && img.isNotEmpty) await prefs.setString('profileImage', img);
        await prefs.setString('wallet', money.toString());

        if (!mounted) return;
        setState(() {
          wallet = money;
          username = serverName.isNotEmpty ? serverName : username;
          profileImageUrl = img ?? profileImageUrl;
          userIdStr = userId.toString();
        });
      }
    } catch (_) {
      // ignore network errors for now
    }
  }

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
      final parsed = _tryParseJson(response.body);
      if (parsed is Map<String, dynamic>) data = parsed;

      if (response.statusCode == 200 && data['data'] != null && data['data']['authToken'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', data['data']['authToken']);
        final userId = data['data']['userid'];
        await prefs.setString('userid', userId.toString());
        await prefs.setString('username', uname);
        // update AuthService
        await AuthService.setUser(uid: userId.toString(), name: uname, image: prefs.getString('profileImage'));
        return data;
      } else {
        return data; // caller can inspect for errors
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Widget _buildFullWidthWalletCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.zero,
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: const Color(0xFFF6EEF8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF255E78),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Get work wallet',
                    style: TextStyle(fontSize: 16, color: Color(0xFF1E5368)),
                  ),
                ),
                Text('฿${wallet.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF22577A))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New: perform logout once and navigate to profile via global navigatorKey
  Future<void> _performLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    // Temporarily remove our auth listener so it does not react during logout
    try {
      AuthService.userId.removeListener(_onAuthChanged);
    } catch (_) {}

    try {
      // 0) attempt server-side logout/revoke if server reachable
      try {
        final prefs = await SharedPreferences.getInstance();
        final storedUid = prefs.getString('userid');
        final storedAuthToken = prefs.getString('authToken'); // token returned from /auth/login
        if (storedUid != null) {
          final resp = await http.post(
            Uri.parse('$baseUrl/auth/logout'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': storedUid, 'authToken': storedAuthToken}),
          );
          // ignore body details; just attempt to inform server
          if (resp.statusCode != 200) {
            // optional: log, but continue with local logout
          }
        }
      } catch (e) {
        // network error - continue with client logout anyway
      }

      // 1) Clear persistent auth and notify listeners (centralized)
      await AuthService.logout();

      // 1.5) Also ensure AuthService in-memory state is cleared (defensive)
      try {
        await AuthService.setUser(uid: null, name: null, image: null);
      } catch (_) {}

      // 2) Clear any local UI state to avoid briefly showing old data
      if (mounted) {
        setState(() {
          userIdStr = null;
          username = null;
          profileImageUrl = null;
          wallet = 0.0;
        });
      }

      // 2.5) Ensure SharedPreferences doesn't contain stale values (defensive)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('userid');
        await prefs.remove('username');
        await prefs.remove('profileImage');
        await prefs.remove('authToken');
        await prefs.remove('wallet');
      } catch (_) {}

      // 3) Navigate to profile (logged-out) and clear navigation stack.
      // Pass explicit nulls as arguments so the profile page won't pick up any
      // stale values from route args.
      app_main.navigatorKey.currentState?.pushNamedAndRemoveUntil('/profile', (route) => false, arguments: {'userid': null, 'username': null});
    } catch (e) {
      // optional: show error and re-enable button
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
        setState(() => _isLoggingOut = false);
      }
    } finally {
      // No need to re-add listener: after navigation this page will be disposed.
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textScale = MediaQuery.of(context).textScaleFactor;

    // Use AuthService values live (avoid stale local userIdStr)
    final displayUserId = AuthService.userId.value ?? '';
    final displayUsername = AuthService.username.value ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('บัญชี2', style: TextStyle(color: Colors.white, fontSize: 18 * textScale)),
        backgroundColor: const Color(0xFF3A5A99),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.95),
          margin: EdgeInsets.symmetric(vertical: screenHeight * 0.04),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // header
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.03),
                        decoration: const BoxDecoration(
                          color: Color(0xFF3A5A99),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/profileEducation');
                              },
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white,
                                backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
                                child: profileImageUrl == null ? const Text('รูป', style: TextStyle(color: Color(0xFF3A5A99))) : null,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              displayUserId != '' && displayUsername != ''
                                  ? 'User: $displayUsername (ID: $displayUserId)'
                                  : displayUserId != ''
                                      ? 'User ID: $displayUserId'
                                      : 'ชื่อผู้ใช้งาน',
                              style: TextStyle(color: Colors.white, fontSize: 18 * textScale, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      // settings row
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                        child: Row(
                          children: [
                            Icon(Icons.settings, color: const Color(0xFF3A5A99), size: screenWidth * 0.06),
                            SizedBox(width: screenWidth * 0.02),
                            Text('การตั้งค่า', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16 * textScale, color: const Color(0xFF3A5A99))),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/accountSettings', arguments: {'userid': displayUserId, 'username': displayUsername});
                              },
                              child: Text('ตั้งค่าบัญชี', style: TextStyle(color: const Color(0xFF3A5A99), fontSize: 15 * textScale)),
                            ),
                          ],
                        ),
                      ),
                      // report button
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => ReportIssuePage(
                                    userid: displayUserId.isEmpty ? null : displayUserId,
                                    username: displayUsername.isEmpty ? null : displayUsername,
                                  ),
                                ),
                              );
                            },
                            child: Text('รายงานปัญหา', style: TextStyle(color: const Color(0xFF3A5A99), fontSize: 15 * textScale)),
                          ),
                        ),
                      ),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFBDBDBD)),
                      SizedBox(height: screenHeight * 0.01),
                      // Wallet card
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                        child: _buildFullWidthWalletCard(context),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      // topup/withdraw buttons
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/topup', arguments: {'userid': displayUserId, 'username': displayUsername});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6EF178),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                  minimumSize: Size(screenWidth * 0.35, screenHeight * 0.06),
                                ),
                                child: Text('เติมเงิน', style: TextStyle(color: const Color(0xFF22577A), fontWeight: FontWeight.bold, fontSize: 15 * textScale)),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/withdraw', arguments: {'userid': displayUserId, 'username': displayUsername});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF3D3D),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                  minimumSize: Size(screenWidth * 0.35, screenHeight * 0.06),
                                ),
                                child: Text('ถอนเงิน', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15 * textScale)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      // logout button
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.04),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoggingOut ? null : _performLogout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.red,
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              textStyle: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold),
                            ),
                            child: _isLoggingOut
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.red)))
                                : const Text('ออกจากระบบ'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
