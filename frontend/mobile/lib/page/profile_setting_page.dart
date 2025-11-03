import 'package:flutter/material.dart';
import 'package:getwork_app/service/auth_service.dart';
import 'package:getwork_app/main.dart' as app_main;

class ProfileSettingPage extends StatelessWidget {
  const ProfileSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ตั้งค่าบัญชี',
          style: TextStyle(
            color: const Color(0xFF22577A),
            fontWeight: FontWeight.bold,
            fontSize: 20 * textScale,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF22577A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF22577A)),
            title: const Text('แก้ไขโปรไฟล์'),
            onTap: () {
              Navigator.pushNamed(context, '/profileDetail');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock, color: Color(0xFF22577A)),
            title: const Text('เปลี่ยนรหัสผ่าน'),
            onTap: () {
              // ไปหน้าเปลี่ยนรหัสผ่าน (เพิ่ม route ตามต้องการ)
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('ออกจากระบบ', style: TextStyle(color: Colors.red)),
            onTap: () async {
              // Perform centralized logout and redirect so all pages show logged-out UI
              try {
                await AuthService.logoutAndRedirect();
              } catch (_) {}
            },
          ),
        ],
      ),
    );
  }
}
