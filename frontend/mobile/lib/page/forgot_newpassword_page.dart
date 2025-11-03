import 'package:flutter/material.dart';

class ForgotNewPasswordPage extends StatefulWidget {
  const ForgotNewPasswordPage({super.key});

  @override
  State<ForgotNewPasswordPage> createState() => _ForgotNewPasswordPageState();
}

class _ForgotNewPasswordPageState extends State<ForgotNewPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;

  @override
  Widget build(BuildContext context) {
  // ignore: deprecated_member_use
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF22577A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'เปลี่ยนรหัสผ่าน',
          style: TextStyle(
            color: const Color(0xFF22577A),
            fontWeight: FontWeight.bold,
            fontSize: 20 * textScale,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[300],
            height: 1,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: screenHeight * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'อีเมล',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            // Username
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'ชื่อผู้ใช้งาน',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            // Old Password
            TextField(
              controller: oldPasswordController,
              obscureText: _obscureOldPassword,
              decoration: InputDecoration(
                labelText: 'รหัสผ่านเดิม',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureOldPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black,
                  ),
                  onPressed: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            // New Password
            TextField(
              controller: newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: 'รหัสผ่านใหม่',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black,
                  ),
                  onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            // Password requirements
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Text(
                '-กรอกรหัสผ่านอย่างน้อย 8 ตัวอักษร\n'
                '-รหัสผ่านต้องมีทั้งตัวพิมพ์ใหญ่,พิมพ์เล็ก,ตัวเลข\n'
                'และอักขระพิเศษ',
                style: TextStyle(color: Colors.red, fontSize: 14 * textScale),
              ),
            ),
            const Spacer(),
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
                onPressed: () {
                  // TODO: Implement password change logic
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('เปลี่ยนรหัสผ่าน')),
                  );
                },
                child: Text('ตกลง', style: TextStyle(fontSize: 20 * textScale)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
