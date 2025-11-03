import 'package:flutter/material.dart';
import 'package:getwork_app/page/forgot_password_page.dart';
import 'package:getwork_app/service/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // เก็บ userId และ username หลังเข้าสู่ระบบสำเร็จ
  String? _loggedInUserId;
  String? _loggedInUsername;

  @override
  void initState() {
    super.initState();
    // listen to auth changes so login/logout immediately update navigation
    AuthService.userId.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthService.userId.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final uid = AuthService.userId.value;
    if (uid != null && uid.isNotEmpty) {
      // user logged in -> navigate to payment page once
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/paymentPage',
        arguments: {'userid': int.tryParse(uid), 'username': AuthService.username.value ?? ''},
      );
    }
    // when uid becomes null (logout) do nothing — remain on login screen
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('http://192.168.56.1:4000/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': _usernameController.text.trim(),
            'password': _passwordController.text,
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
          final username = _usernameController.text.trim();
          setState(() {
            _loggedInUserId = userId.toString();
            _loggedInUsername = username;
          });
          await prefs.setString('userid', userId.toString());
          await prefs.setString('username', username);
          await AuthService.setUser(uid: userId.toString(), name: username, image: '');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ'), backgroundColor: Colors.green),
            );
            // Navigate to main/home page after successful login
            Navigator.pushReplacementNamed(
              context,
              '/',
              arguments: {
                'userid': userId,
                'username': username,
              },
            );
          }
        } else if (response.body.contains('semaphore timeout')) {
          // กรณี timeout
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ (timeout) กรุณาตรวจสอบการเชื่อมต่อหรือ backend')),
            );
          }
        } else {
          String errorMsg = 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง';
          if (data['error'] != null && data['error'] != 'Invalid credentials') {
            errorMsg = data['error'];
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg)),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      } finally {
        // avoid returning inside finally (control_flow_in_finally)
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // ฟังก์ชันสำหรับลืมรหัสผ่าน
  void _resetPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // เปลี่ยนจาก Color(0xFF7B668C) เป็นสีขาว
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E6A7B)),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/profile');
          },
        ),
        title: const Text('เข้าสู่ระบบ', style: TextStyle(color: Color(0xFF2E6A7B))),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            margin: const EdgeInsets.symmetric(vertical: 32),
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22577A),
                      ),
                    ),
                    const Divider(height: 32, thickness: 1, color: Color(0xFFBDBDBD)),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'ชื่อผู้ใช้งาน',
                              labelStyle: const TextStyle(color: Color(0xFFA3A3A3), fontWeight: FontWeight.bold, fontSize: 18),
                              filled: true,
                              fillColor: const Color(0xFFE5E5E5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF22577A), // เปลี่ยนสีเวลาพิมพ์เป็น #22577A
                              fontWeight: FontWeight.bold,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกชื่อผู้ใช้งาน';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'รหัสผ่าน',
                              labelStyle: const TextStyle(color: Color(0xFFA3A3A3), fontWeight: FontWeight.bold, fontSize: 18),
                              filled: true,
                              fillColor: const Color(0xFFE5E5E5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.black,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF22577A), // เปลี่ยนสีเวลาพิมพ์เป็น #22577A
                              fontWeight: FontWeight.bold,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกรหัสผ่าน';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text('จำรหัสผ่านไม่ได้', style: TextStyle(color: Colors.grey, fontSize: 16)),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _resetPassword,
                                child: const Text(
                                  'ลืมรหัสผ่าน',
                                  style: TextStyle(
                                    color: Color(0xFF22577A),
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22577A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(120, 54),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              onPressed: _isLoading ? null : _login, // ปิดปุ่มขณะโหลด
                              child: _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('เข้าสู่ระบบ'),
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
        ),
      ),
    );
  }
}