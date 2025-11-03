import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;

  void _sendOtp() async {
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    if (email.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกอีเมลและชื่อผู้ใช้งาน')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = true);
    // จำลองการส่ง OTP
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _otpSent = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ส่งรหัส OTP ไปยังอีเมลเรียบร้อยแล้ว')),
    );
  }

  void _submit() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    // จำลองการตรวจสอบ OTP
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);
    // ไปหน้าหลัก main.dart
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E6A7B)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
        title: const Text('ลืมรหัสผ่าน', style: TextStyle(color: Color(0xFF2E6A7B))),
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
                      'ลืมรหัสผ่าน',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22577A),
                      ),
                    ),
                    const Divider(height: 32, thickness: 1, color: Color(0xFFBDBDBD)),
                    // ช่องกรอกอีเมล
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'อีเมล',
                        hintStyle: const TextStyle(color: Color(0xFFA3A3A3), fontWeight: FontWeight.bold, fontSize: 18),
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
                        color: Color(0xFF22577A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ช่องกรอกชื่อผู้ใช้งาน
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'ชื่อผู้ใช้งาน',
                        hintStyle: const TextStyle(color: Color(0xFFA3A3A3), fontWeight: FontWeight.bold, fontSize: 18),
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
                        color: Color(0xFF22577A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ปุ่มส่ง OTP
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22577A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(120, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isLoading ? null : _sendOtp,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('ส่งรหัส OTP'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // ปุ่มยืนยัน
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _otpSent ? const Color(0xFF22577A) : Colors.grey, // สีเทาถ้ายังไม่ได้ส่ง OTP
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(120, 54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        onPressed: (_otpSent && !_isLoading) ? _submit : null, // กดได้เมื่อส่ง OTP แล้ว
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('ยืนยัน'),
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
