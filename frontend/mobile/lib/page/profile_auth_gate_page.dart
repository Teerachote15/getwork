import 'package:flutter/material.dart';

class ProfileAuthGatePage extends StatelessWidget {
  const ProfileAuthGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3A5A99),
      body: Column(
        children: [
          // Header with icon in white circle
          Container(
            width: double.infinity,
            color: const Color(0xFF3A5A99),
            padding: const EdgeInsets.only(top: 40, bottom: 16),
            child: const Row(
              children: [
                SizedBox(width: 16),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_circle, color: Color(0xFF3A5A99), size: 40),
                      SizedBox(height: 2),
                      Text(
                        'Get Work!',
                        style: TextStyle(
                          color: Color(0xFF3A5A99),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // White card with buttons
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Login Button
                    SizedBox(
                      width: 140,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          elevation: 4,
                          shadowColor: Colors.black26,
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text(
                          'เข้าสู่ระบบ',
                          style: TextStyle(
                            color: Color(0xFF3A5A99),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Register Button
                    SizedBox(
                      width: 140,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          elevation: 4,
                          shadowColor: Colors.black26,
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/register');
                        },
                        child: const Text(
                          'สมัครสมาชิก',
                          style: TextStyle(
                            color: Color(0xFF3A5A99),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF3A5A99),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        currentIndex: 4,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/status');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/postJob');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/notifications');
              break;
            case 4:
              // Stay on this page
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
}
