import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'account_settings_page.dart'; // เพิ่มการนำเข้า

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกอีเมล';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'กรุณากรอกอีเมลที่ถูกต้อง';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกรหัสผ่าน';
    }
    final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])(?=.*[!@#\$%^&*(),.?":{}|<>]).{8,}$');
    if (!passwordRegex.hasMatch(value)) {
      return 'รหัสผ่านต้องมีตัวพิมพ์ใหญ่, พิมพ์เล็ก, ตัวเลข และอักษรพิเศษ';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกชื่อผู้ใช้งาน';
    }
    if (value.length < 4) {
      return 'ชื่อผู้ใช้งานต้องมีอย่างน้อย 4 ตัวอักษร';
    }
    return null;
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('http://192.168.56.1:4000/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': _usernameController.text.trim(),
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          }),
        );

        Map<String, dynamic> data = {};
        try {
          data = jsonDecode(response.body);
        } catch (_) {}

        // ดึง userId จาก response (backend ต้องแก้ให้ส่ง userId กลับมาด้วย)
        final userId = data['user_id'] ?? data['userId'];

        if (response.statusCode == 200 && data['success'] == true && userId != null) {
          // Show success quickly, then navigate — avoid holding BuildContext across await
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('สมัครสมาชิกสำเร็จ! กรุณากรอกข้อมูลบัญชี'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
          // wait, but re-check mounted before navigating
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;
          // ไปยังหน้า AccountSettings โดยตรง (ไม่ขึ้นกับ named routes)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountSettingsPage(), // ปรับชื่อคลาสหากต่างกัน
              settings: RouteSettings(arguments: {
                'username': _usernameController.text.trim(),
                'userId': userId,
              }),
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'เกิดข้อผิดพลาด')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _showPrivacyDialogAndRegister() async {
    if (_formKey.currentState!.validate()) {
      bool? accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'ยินยอมความเป็นส่วนตัว',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF22577A),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'ประกาศความเป็นส่วนตัวและการยินยอมการเก็บข้อมูลส่วนบุคคล',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Color(0xFF22577A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Divider(height: 24, thickness: 1, color: Color(0xFFBDBDBD)),
                      Text(
                        'เพื่อให้การใช้งานแอปพลิเคชันทำงานของเรามีประสิทธิภาพสูงสุดและตรงกับความต้องการของผู้ใช้งาน ทางเราจึงมีความจำเป็นต้องเก็บรวบรวม ใช้ และประมวลผลข้อมูลส่วนบุคคลของท่าน ซึ่งอาจรวมถึง\n'
                        '• ข้อมูลระบุตัวตน (เช่น ชื่อ-นามสกุล, วันเกิด, ที่อยู่, เบอร์ติดต่อ, อีเมล)\n'
                        '• ประวัติการใช้งานและประสบการณ์การทำงาน\n'
                        '• เอกสารแสดงตัว เช่น รูปถ่าย, เอกสาร, บัตรประชาชน, รูปถ่าย\n'
                        '• พฤติกรรมการใช้งาน เพื่อปรับปรุงบริการให้เหมาะสมยิ่งขึ้น\n'
                        'ข้อมูลของท่านจะถูกใช้เพื่อวัตถุประสงค์ดังต่อไปนี้:\n'
                        '• เพื่อให้บริการรับสมัครระหว่างผู้หางานและผู้ประกอบการ\n'
                        '• เพื่อวิเคราะห์และปรับปรุงบริการของเรา\n'
                        '• เพื่อแจ้งข่าวสารหรือโอกาสงานที่เกี่ยวข้องกับความสนใจของท่าน\n'
                        '• เพื่อใช้ในการติดต่อกลับเมื่อจำเป็น\n\n'
                        'เราจะเก็บรักษาข้อมูลของท่านอย่างปลอดภัย และจะไม่เปิดเผยข้อมูลตามที่กล่าวข้างต้นโดยไม่ได้รับความยินยอม เว้นแต่จะเป็นไปตามกฎหมายที่เกี่ยวข้อง',
                        style: TextStyle(fontSize: 15, color: Color(0xFF22577A)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFBDBDBD)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            side: const BorderSide(color: Color(0xFF22577A)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('ไม่ยอมรับ', style: TextStyle(fontSize: 18, color: Color(0xFF22577A))),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22577A),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('ยอมรับ', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (accepted == true) {
        await _register();
      }
      // ถ้าไม่ยอมรับ ไม่ต้องทำอะไร
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final userId = args['userId'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E6A7B)),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/profile');
          },
        ),
        title: const Text('สมัครสมาชิก', style: TextStyle(color: Color(0xFF2E6A7B))),
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
                      'สมัครสมาชิก',
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ชื่อผู้ใช้งาน',
                            style: TextStyle(
                              color: Color(0xFF22577A),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFE3EAF2),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF22577A),
                              fontWeight: FontWeight.bold,
                            ),
                            validator: _validateUsername,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'อีเมล',
                            style: TextStyle(
                              color: Color(0xFF22577A),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFE3EAF2),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF22577A),
                              fontWeight: FontWeight.bold,
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'รหัสผ่าน',
                            style: TextStyle(
                              color: Color(0xFF22577A),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFE3EAF2),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF22577A),
                              fontWeight: FontWeight.bold,
                            ),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'ยืนยันรหัสผ่าน',
                            style: TextStyle(
                              color: Color(0xFF22577A),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFE3EAF2),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.black),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF22577A),
                              fontWeight: FontWeight.bold,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกยืนยันรหัสผ่าน';
                              }
                              if (value != _passwordController.text) {
                                return 'รหัสผ่านไม่ตรงกัน';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
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
                              // เปลี่ยนจาก _register เป็น _showPrivacyDialogAndRegister
                              onPressed: _isLoading ? null : _showPrivacyDialogAndRegister,
                              child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('สมัครสมาชิก'),
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
