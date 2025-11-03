import 'package:flutter/material.dart';
import 'package:getwork_app/page/category_page.dart';
import 'package:getwork_app/page/post_job_page.dart';
import 'package:getwork_app/page/login_page.dart';  // เพิ่มการ import LoginPage
import 'package:getwork_app/page/register_page.dart';  // เพิ่มการ import RegisterPage
import 'package:getwork_app/service/auth_service.dart';
import 'package:getwork_app/widgets/bottom_nav_bar.dart';

void main() {
  runApp(const MyApp());
}

// use AuthService.userId to check login state

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GetWork App',
      initialRoute: '/', 
      routes: {
        '/': (context) => const HomePage(), // หน้าแรก
        '/login': (context) => const LoginPage(),  
        '/register': (context) => const RegisterPage(),  
        '/postJob': (context) => const PostJobPage(),
        '/category': (context) => const CategoryPage(),
        '/loginOrRegister': (context) => const LoginOrRegisterPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(  
                  child: CategoryItem(
                    label: "แนะนำ",
                    icon: Icons.star,
                    onTap: () => _navigateWithAuthCheck(context, '/category'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(  
                  child: CategoryItem(
                    label: "ออกแบบกราฟิก",
                    icon: Icons.design_services,
                    onTap: () => _navigateWithAuthCheck(context, '/category'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(  
                  child: CategoryItem(
                    label: "เว็บไซต์",
                    icon: Icons.web,
                    onTap: () => _navigateWithAuthCheck(context, '/category'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        backgroundColor: const Color(0xFFFFA500),
        onTap: (index) {
          final uid = AuthService.userId.value;
          final loggedIn = uid != null && uid.isNotEmpty;
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/');
              break;
            case 1:
              if (loggedIn) {
                Navigator.pushNamed(context, '/category');
              } else {
                Navigator.pushNamed(context, '/loginOrRegister');
              }
              break;
            case 2:
              if (loggedIn) {
                Navigator.pushNamed(context, '/postJob');
              } else {
                Navigator.pushNamed(context, '/loginOrRegister');
              }
              break;
            case 3:
              if (loggedIn) {
                Navigator.pushNamed(context, '/notifications');
              } else {
                Navigator.pushNamed(context, '/loginOrRegister');
              }
              break;
            case 4:
              Navigator.pushNamed(context, '/register');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Category'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Post Job'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
    );
  }

  // ฟังก์ชันเช็คสถานะการล็อกอิน
  void _navigateWithAuthCheck(BuildContext context, String routeName) {
    final uid = AuthService.userId.value;
    final loggedIn = uid != null && uid.isNotEmpty;
    if (!loggedIn) {
      Navigator.pushNamed(context, '/loginOrRegister'); // ถ้ายังไม่ได้ล็อกอิน ให้ไปหน้า Login/SignUp
    } else {
      Navigator.pushNamed(context, routeName); // หากล็อกอินแล้ว ให้ไปยังหน้าใน app
    }
  }
}

class CategoryItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const CategoryItem({super.key, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.grey, blurRadius: 4, spreadRadius: 2),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.orange),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginOrRegisterPage extends StatelessWidget {
  const LoginOrRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login or Register'),
        backgroundColor: const Color(0xFFFFA500),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Row ที่มีปุ่ม Login และ Register อยู่แถวเดียวกัน
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ปุ่ม Login
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20), // ปรับขนาดปุ่ม
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // ขนาดตัวอักษรใหญ่ขึ้น
                    ),
                  ),
                ),
                const SizedBox(width: 16), // ระยะห่างระหว่างปุ่ม
                // ปุ่ม Register
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20), // ปรับขนาดปุ่ม
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // ขนาดตัวอักษรใหญ่ขึ้น
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
