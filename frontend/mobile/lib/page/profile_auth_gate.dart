import 'package:flutter/material.dart';

class ProfileAuthGatePage extends StatelessWidget {
  const ProfileAuthGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B668C),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200], // สีเทา
                  elevation: 2,
                  shadowColor: Colors.black26,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // กรอบสี่เหลี่ยมมนเล็กน้อย
                  ),
                  side: const BorderSide(color: Colors.grey), // กรอบ
                ),
                child: const Text(
                  'เข้าสู่ระบบ',
                  style: TextStyle(
                    color: Color(0xFF2E6A7B),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200], // สีเทา
                  elevation: 2,
                  shadowColor: Colors.black26,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // กรอบสี่เหลี่ยมมนเล็กน้อย
                  ),
                  side: const BorderSide(color: Colors.grey), // กรอบ
                ),
                child: const Text(
                  'สมัครสมาชิก',
                  style: TextStyle(
                    color: Color(0xFF2E6A7B),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
