import 'package:flutter/material.dart';
import 'package:getwork_app/page/category_page.dart';
import 'package:getwork_app/page/post_job_page.dart';
import 'package:getwork_app/page/login_page.dart';
import 'package:getwork_app/page/register_page.dart';
import 'package:getwork_app/page/notification_page.dart';
// import 'package:flutter_svg/flutter_svg.dart'; // ไม่ใช้แล้ว

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
        '/notifications': (context) => const NotificationPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showAuthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('กรุณาเข้าสู่ระบบ'),
          content: const Text('คุณต้องเข้าสู่ระบบหรือสมัครสมาชิกก่อนใช้งาน'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('เข้าสู่ระบบ'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/register');
              },
              child: const Text('สมัครสมาชิก'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final userId = args['userid'];
    final username = args['username'];
    final isLoggedIn = userId != null && username != null;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: const Color(0xFF7B668C),
      appBar: AppBar(
        title: Text('หน้าหลัก', style: TextStyle(color: Colors.white, fontSize: 18 * textScale)),
        backgroundColor: const Color(0xFF7B668C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 12),
              child: Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
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
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: screenWidth * 0.95),
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
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenHeight * 0.015),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.01),
                    Text('ค้นหาบริการ', style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold)),
                    SizedBox(height: screenHeight * 0.01),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'ค้นหาบริการ...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                        ),
                        style: TextStyle(fontSize: 14 * textScale),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text('เลือกดูโพส', style: TextStyle(fontSize: 15 * textScale)),
                    SizedBox(height: screenHeight * 0.01),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (isLoggedIn) {
                                Navigator.pushNamed(
                                  context,
                                  '/postFindJobList',
                                  arguments: {'postType': 'worker'},
                                );
                              } else {
                                _showAuthDialog(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                              elevation: 0,
                              minimumSize: Size(screenWidth * 0.25, screenHeight * 0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('โพสต์หางาน', style: TextStyle(fontSize: 14 * textScale)),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (isLoggedIn) {
                                Navigator.pushNamed(
                                  context,
                                  '/postFindJobList',
                                  arguments: {'postType': 'employer'},
                                );
                              } else {
                                _showAuthDialog(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                              elevation: 0,
                              minimumSize: Size(screenWidth * 0.25, screenHeight * 0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('โพสต์จ้างงาน', style: TextStyle(fontSize: 14 * textScale)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      children: [
                        Text('หมวดหมู่ทั้งหมด', style: TextStyle(fontSize: 15 * textScale, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          onPressed: () {
                            if (isLoggedIn) {
                              Navigator.pushNamed(context, '/category', arguments: {'userid': userId, 'username': username});
                            } else {
                              _showAuthDialog(context);
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Row(
                      children: [
                        Expanded(
                          child: _CategoryIcon(
                            label: 'แนะนำ',
                            icon: 'assets/images/homepage.png',
                            onTap: () {
                              if (isLoggedIn) {
                                Navigator.pushNamed(context, '/category', arguments: {'userid': userId, 'username': username});
                              } else {
                                _showAuthDialog(context);
                              }
                            },
                            fontSize: 12 * textScale,
                            iconSize: screenWidth * 0.07,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.015),
                        Expanded(
                          child: _CategoryIcon(
                            label: 'ออกแบบกราฟิก',
                            icon: 'assets/images/status.png',
                            onTap: () {
                              if (isLoggedIn) {
                                Navigator.pushNamed(context, '/category', arguments: {'userid': userId, 'username': username});
                              } else {
                                _showAuthDialog(context);
                              }
                            },
                            fontSize: 12 * textScale,
                            iconSize: screenWidth * 0.07,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.015),
                        Expanded(
                          child: _CategoryIcon(
                            label: 'เว็บไซต์',
                            icon: 'assets/images/postjob.png',
                            onTap: () {
                              if (isLoggedIn) {
                                Navigator.pushNamed(context, '/category', arguments: {'userid': userId, 'username': username});
                              } else {
                                _showAuthDialog(context);
                              }
                            },
                            fontSize: 12 * textScale,
                            iconSize: screenWidth * 0.07,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.018),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: screenHeight * 0.012,
                      crossAxisSpacing: screenWidth * 0.02,
                      childAspectRatio: 1.4,
                      children: [
                        _ServiceCard(
                          image: 'assets/images/web_card.png',
                          label: 'เว็บไซต์',
                          onTap: () {
                            if (isLoggedIn) {
                              Navigator.pushNamed(context, '/category', arguments: {'userid': userId, 'username': username});
                            } else {
                              _showAuthDialog(context);
                            }
                          },
                          fontSize: 11 * textScale,
                          imageHeight: screenHeight * 0.05,
                        ),
                        _ServiceCard(
                          image: 'assets/images/graphic_card.png',
                          label: 'ออกแบบกราฟิก',
                          onTap: () {
                            if (isLoggedIn) {
                              Navigator.pushNamed(context, '/category', arguments: {'userid': userId, 'username': username});
                            } else {
                              _showAuthDialog(context);
                            }
                          },
                          fontSize: 11 * textScale,
                          imageHeight: screenHeight * 0.05,
                        ),
                        _ServiceCard(
                          image: 'assets/images/video_card.png',
                          label: 'ตัดต่อวิดีโอ',
                          onTap: () {
                            if (isLoggedIn) {
                              Navigator.pushNamed(context, '/category', arguments: {'userid': userId, 'username': username});
                            } else {
                              _showAuthDialog(context);
                            }
                          },
                          fontSize: 11 * textScale,
                          imageHeight: screenHeight * 0.05,
                        ),
                        _ServiceCard(
                          image: 'assets/images/fortune_card.png',
                          label: 'ดูดวง',
                          onTap: () {
                            if (isLoggedIn) {
                              Navigator.pushNamed(context, '/category', arguments: {'userid': userId, 'username': username});
                            } else {
                              _showAuthDialog(context);
                            }
                          },
                          fontSize: 11 * textScale,
                          imageHeight: screenHeight * 0.05,
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _NavIcon(
                            asset: 'assets/images/homepage.png',
                            onTap: () {
                              // already on home - do nothing or refresh
                            },
                          ),
                          _NavIcon(
                            asset: 'assets/images/status.png',
                            onTap: () {
                              if (isLoggedIn) {
                                Navigator.pushNamed(context, '/status', arguments: {'userid': userId, 'username': username});
                              } else {
                                _showAuthDialog(context);
                              }
                            },
                          ),
                          _NavIcon(
                            asset: 'assets/images/postjob.png',
                            onTap: () {
                              if (isLoggedIn) {
                                Navigator.pushNamed(context, '/postJob', arguments: {'userid': userId, 'username': username});
                              } else {
                                _showAuthDialog(context);
                              }
                            },
                          ),
                          _NavIcon(
                            asset: 'assets/images/notification.png',
                            onTap: () {
                              if (isLoggedIn) {
                                Navigator.pushNamed(context, '/notifications', arguments: {'userid': userId, 'username': username});
                              } else {
                                _showAuthDialog(context);
                              }
                            },
                          ),
                          _NavIcon(
                            asset: 'assets/images/profile.png',
                            onTap: () {
                              if (isLoggedIn) {
                                Navigator.pushNamed(context, '/paymentPage', arguments: {'userid': userId, 'username': username});
                              } else {
                                _showAuthDialog(context);
                              }
                            },
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

class _NavIcon extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;
  const _NavIcon({required this.asset, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(
        asset,
        width: screenWidth * 0.06,
        height: screenWidth * 0.06,
        color: const Color(0xFF1A237E),
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;
  final double fontSize;
  final double iconSize;
  const _CategoryIcon({
    required this.label,
    required this.icon,
    required this.onTap,
    this.fontSize = 12,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(iconSize * 0.25),
            child: Image.asset(
              icon,
              width: iconSize,
              height: iconSize,
              color: const Color(0xFF1A237E),
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
            ),
          ),
        ),
        SizedBox(height: fontSize * 0.33),
        Text(label, style: TextStyle(fontSize: fontSize)),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String image;
  final String label;
  final VoidCallback onTap;
  final double fontSize;
  final double imageHeight;
  const _ServiceCard({
    required this.image,
    required this.label,
    required this.onTap,
    this.fontSize = 11,
    this.imageHeight = 36,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: imageHeight * 2,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.asset(
                image,
                fit: BoxFit.contain,
                width: double.infinity,
                height: imageHeight,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) return child;
                    if (frame == null) return const Center(child: CircularProgressIndicator());
                    return child;
                  },
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(vertical: fontSize * 0.18),
              child: Center(
                child: Text(label, style: TextStyle(fontSize: fontSize)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


