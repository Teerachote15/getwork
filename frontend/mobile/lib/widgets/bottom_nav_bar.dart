import 'package:flutter/material.dart';
import 'package:getwork_app/page/category_page.dart';
import 'package:getwork_app/page/post_job_page.dart';
import 'package:getwork_app/page/job_status_page.dart'; // เพิ่มหน้าสถานะงาน
import 'package:getwork_app/page/profile_page.dart'; // เพิ่มหน้าประวัติผู้ใช้
import 'package:getwork_app/page/login_page.dart'; // Import LoginPage
import 'package:getwork_app/page/register_page.dart'; // Import RegisterPage
import 'package:getwork_app/service/auth_service.dart';
import 'package:getwork_app/page/notification_page.dart'; // Import NotificationPage
// removed self-import (was causing unused-import)

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GetWork App',
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/postJob': (context) => const PostJobPage(),
        '/category': (context) => const CategoryPage(),
        '/workStatus': (context) => const JobStatusPage(),
        '/notifications': (context) => const NotificationPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  String _getRouteName(int index) {
    switch (index) {
      case 0:
        return '/';
      case 1:
        return '/workStatus';
      case 2:
        return '/postJob';
      case 3:
        return '/notifications';
      case 4:
        return '/paymentPage';
      default:
        return '/';
    }
  }

  void _navigateWithAuthCheck(BuildContext context, String routeName, {Map<String, dynamic>? extraArgs}) {
    final uid = AuthService.userId.value;
    final loggedIn = uid != null && uid.isNotEmpty;
    if (!loggedIn) {
      Navigator.pushNamed(context, '/login');
    } else {
      Navigator.pushNamed(context, routeName, arguments: {
        if (uid != null) 'userid': int.tryParse(uid),
        ...?extraArgs,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.userId.value;
    final loggedIn = uid != null && uid.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GetWork!'),
        backgroundColor: const Color(0xFFFFA500),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search หาบริการ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาบริการ...',
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'หมวดหมู่ทั้งหมด',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CategoryItem(
                    label: "แนะนำ",
                    onTap: () => _navigateWithAuthCheck(context, '/category'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CategoryItem(
                    label: "ออกแบบกราฟิก",
                    onTap: () => _navigateWithAuthCheck(context, '/category'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CategoryItem(
                    label: "เว็บไซต์",
                    onTap: () => _navigateWithAuthCheck(context, '/category'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CategoryItem(
                    label: "ตัดต่อวิดีโอ",
                    onTap: () => _navigateWithAuthCheck(context, '/postJob'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CategoryItem(
                    label: "ดูดวง",
                    onTap: () => _navigateWithAuthCheck(context, '/postJob'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!loggedIn) ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('เข้าสู่ระบบ'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text('สมัครสมาชิก'),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          String routeName = _getRouteName(index);
          _navigateWithAuthCheck(context, routeName);
        },
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const CategoryItem({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFA500),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap; // optional: callers can provide custom handler

  const BottomNavBar({super.key, required this.currentIndex, this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white60,
      backgroundColor: const Color(0xFF3A5A99),
      onTap: (index) async {
        // If caller provided a custom onTap, use it.
        if (onTap != null) {
          onTap!(index);
          return;
        }

        // Default behavior: require login for indices 1,2,3 (status, post, notifications)
  final uid = AuthService.userId.value;
  final loggedIn = uid?.isNotEmpty ?? false;

        // Map index -> routeName locally
        String routeName;
        switch (index) {
          case 0:
            routeName = '/';
            break;
          case 1:
            routeName = '/workStatus';
            break;
          case 2:
            routeName = '/postJob';
            break;
          case 3:
            routeName = '/notifications';
            break;
          case 4:
            routeName = '/paymentPage';
            break;
          default:
            routeName = '/';
        }

        if ([1, 2, 3].contains(index) && !loggedIn) {
          Navigator.pushNamed(context, '/login');
          return;
        }

        if (index == 4) {
          if (loggedIn) {
            Navigator.pushNamed(context, '/paymentPage', arguments: {'userid': uid != null ? int.tryParse(uid) : null, 'username': AuthService.username.value});
          } else {
            Navigator.pushNamed(context, '/profile');
          }
          return;
        }

        Navigator.pushNamed(context, routeName, arguments: {
          if (uid != null) 'userid': int.tryParse(uid),
          'username': AuthService.username.value,
        });
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, size: screenWidth * 0.05),
          label: 'หน้าหลัก',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment, size: screenWidth * 0.05),
          label: 'สถานะ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle, size: screenWidth * 0.05),
          label: 'โพสต์',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications, size: screenWidth * 0.05),
          label: 'แจ้งเตือน',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person, size: screenWidth * 0.05),
          label: 'โปรไฟล์',
        ),
      ],
      selectedLabelStyle: TextStyle(fontSize: 13 * textScale),
      unselectedLabelStyle: TextStyle(fontSize: 12 * textScale),
    );
  }
}
