import 'package:getwork_app/page/login_page.dart';
import 'package:flutter/material.dart';
import 'package:getwork_app/page/category_page.dart';
import 'package:getwork_app/page/post_job_page.dart';
import 'package:getwork_app/page/register_page.dart';
import 'package:getwork_app/page/notification_page.dart' as notify;
import 'package:getwork_app/page/notification_detail_page.dart';
import 'package:getwork_app/page/job_status_page.dart';
import 'package:getwork_app/page/profile_page.dart';
import 'package:getwork_app/page/account_settings_page.dart';
import 'package:getwork_app/page/topup_select_method_page.dart';
import 'package:getwork_app/page/topup_form_page.dart';
import 'package:getwork_app/page/withdraw_page.dart';
import 'package:getwork_app/page/profile_detail_page.dart';
import 'package:getwork_app/page/profile_education_page.dart';
import 'package:getwork_app/page/profile_experience_page.dart';
import 'package:getwork_app/page/profile_posts_page.dart';
import 'package:getwork_app/page/profile_reviews_page.dart';
import 'package:getwork_app/page/payment_page.dart';
import 'package:getwork_app/page/profile_auth_gate_page.dart';
import 'package:getwork_app/page/post_job_hire_page.dart';
import 'package:getwork_app/page/post_job_find_page.dart';
import 'package:getwork_app/page/job_status_detail_page.dart';
import 'package:getwork_app/page/job_status_show_page.dart';
import 'package:getwork_app/page/post_find_job_list_page.dart';
import 'package:getwork_app/page/chat_page.dart';
import 'package:getwork_app/page/chat_list_page.dart';
import 'package:getwork_app/page/post_job_logo_page.dart';
import 'package:getwork_app/page/post_job_details_page.dart';
import 'package:getwork_app/page/job_status_finish_page.dart';
import 'package:getwork_app/page/review_page.dart';
import 'package:getwork_app/page/post_service_page.dart';
import 'package:getwork_app/page/send_details_freelance_page.dart';
import 'package:getwork_app/page/forgot_newpassword_page.dart';
import 'package:getwork_app/service/auth_service.dart'; // add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init(); // initialize auth state before app run
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GetWork App',
      navigatorKey: navigatorKey, // <-- added so logout can navigate reliably
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/postJob': (context) => const PostJobPage(),
        '/category': (context) => const CategoryPage(),
        '/notifications': (context) => const notify.NotificationPage(),
        '/notificationDetail': (context) => const NotificationDetailPage(),
        '/status': (context) => const JobStatusPage(),
        '/profile': (context) => const ProfilePage(),
        '/accountSettings': (context) => const AccountSettingsPage(),
        '/topup': (context) => const TopupSelectMethodPage(),
        '/topupForm': (context) => const TopupFormPage(),
        '/withdraw': (context) => const WithdrawPage(),
        '/profileDetail': (context) => const ProfileDetailPage(),
        '/profileEducation': (context) => const ProfileEducationPage(),
        '/profileExperience': (context) => const ProfileExperiencePage(),
        '/profilePosts': (context) => const ProfilePostsPage(),
        '/profileReviews': (context) => const ProfileReviewsPage(),
        '/paymentPage': (context) => const PaymentPage(),
        '/profileAuthGate': (context) => const ProfileAuthGatePage(),
        '/postJobHire': (context) => const PostJobHirePage(),
        '/postJobFind': (context) => const PostJobFindPage(),
        '/jobStatusDetail': (context) => const JobStatusDetailPage(),
        '/jobStatusShow': (context) => const JobStatusShowPage(),
        '/jobStatusFinish': (context) => const JobStatusFinishPage(),
        '/postFindJobList': (context) => const JobListHirePage(),
        '/chat': (context) => const ChatPage(),
        '/chatList': (context) => const ChatListPage(),
        '/jobListHire': (context) => const JobListHirePage(),
        '/postJobLogo': (context) => const PostJobLogoPage(),
        '/postJobDetails': (context) => const PostJobDetailsPage(),
        '/review': (context) => const ReviewPage(),
        '/postService': (context) => const PostServicePage(),
        '/sendDetailsFreelance': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final Map? mapArgs = args is Map ? args : null;
          final postId = mapArgs != null && mapArgs['postId'] != null
              ? (mapArgs['postId'] is int ? mapArgs['postId'] as int : int.tryParse('${mapArgs['postId']}') ?? 0)
              : 0;
          final employerId = mapArgs != null && mapArgs['employerId'] != null
              ? (mapArgs['employerId'] is int ? mapArgs['employerId'] as int : int.tryParse('${mapArgs['employerId']}') ?? 0)
              : 0;
          return SendDetailsFreelancePage(postId: postId, employerId: employerId);
        },
        '/notification_detail': (context) => const NotificationDetailPage(),
        '/account_settings': (context) => const AccountSettingsPage(),
        '/forgotNewPassword': (context) => const ForgotNewPasswordPage(),
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
  final int _selectedIndex = 0;
  bool _isButtonDisabled = false;

  static const List<String> _routes = [
    '/', '/status', '/postJob', '/notifications', '/profile',
  ];

  @override
  void initState() {
    super.initState();
    // removed manual AuthService listeners: UI now uses ValueListenableBuilder
  }

  @override
  void dispose() {
    // ...existing code...
    super.dispose();
  }

  void _onItemTapped(int index) async {
    if (_isButtonDisabled) return;
    if (!mounted) return;
    setState(() { _isButtonDisabled = true; });
    try {
      final uidStr = AuthService.userId.value;
      final uid = uidStr != null ? int.tryParse(uidStr) : null;
      final uname = AuthService.username.value;

      // Require login for Status (index 1), Post (index 2) and Notifications (index 3)
      if ([1, 2, 3].contains(index)) {
        final loggedIn = uid != null;
        if (!loggedIn) {
          // send user to login page if not logged in
          await Navigator.pushNamed(context, '/login');
          return;
        }
      }

      if (index == 4) {
        if (uid != null) {
          await Navigator.pushReplacementNamed(context, '/paymentPage', arguments: {'userid': uid, 'username': uname});
        } else {
          await Navigator.pushReplacementNamed(context, '/profile');
        }
      } else {
        await Navigator.pushReplacementNamed(context, _routes[index], arguments: {'userid': uid, 'username': uname});
      }
    } finally {
      // avoid returning inside finally (control_flow_in_finally)
      if (mounted) {
        setState(() { _isButtonDisabled = false; });
      }
    }
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  void _navigateWithAuthCheck(BuildContext context, String routeName) {
    // ไม่ต้องเช็ค isLoggedIn ให้ไปหน้า routeName ได้เลย
    Navigator.pushNamed(context, routeName);
  }

  // ฟังก์ชันสำหรับนำทางไปหน้า login/register โดยตรง
  void _goToLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }
  void _goToRegister(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/register');
  }

  Future<void> _handleButton(Function action) async {
    if (_isButtonDisabled) return;
    if (!mounted) return;
    setState(() {
      _isButtonDisabled = true;
    });
    try {
      await action();
    } finally {
      // avoid returning inside finally (control_flow_in_finally)
      if (mounted) {
        setState(() {
          _isButtonDisabled = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;

    // Rebuild UI whenever auth state changes so logout is reflected immediately
    return ValueListenableBuilder<String?>(
      valueListenable: AuthService.userId,
      builder: (context, uid, _) {
        final bool isLoggedIn = uid != null;
        final int? userId = uid != null ? int.tryParse(uid) : null;
        final String? username = AuthService.username.value;

        // Rebuild UI when auth state changes
        return Scaffold(
          backgroundColor: const Color(0xFF3A5A99),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text('หน้าหลัก', style: TextStyle(color: Colors.white, fontSize: 18 * textScale)),
            backgroundColor: const Color(0xFF3A5A99),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (isLoggedIn)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (username != null) Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        if (userId != null) Text('ID: $userId', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Container(
                // constraints: const BoxConstraints(maxWidth: 280), // ลบออกเพื่อให้เต็มจอ
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
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenHeight * 0.01,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.01),
                    // เปลี่ยน header ให้เป็นแถวมีข้อความทางซ้ายและไอคอนวงกลมทางขวา
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'search หาบริการ',
                            style: TextStyle(
                              fontSize: 16 * textScale,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.black54),
                            onPressed: _isButtonDisabled
                                ? null
                                : () => _handleButton(() async {
                                      // Require login for some chat actions; open chat list page
                                      if (!isLoggedIn) {
                                        await Navigator.pushNamed(context, '/login');
                                      } else {
                                        await Navigator.pushNamed(context, '/chatList');
                                      }
                                    }),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),

                    // แถวของช่องค้นหา + ปุ่มค้นหาขั้นสูง (วงกลม)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: TextField(
                              style: TextStyle(fontSize: 14 * textScale),
                              decoration: InputDecoration(
                                hintText: 'ค้นหา...',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenHeight * 0.014,
                                ),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 8, right: 8),
                                  child: Icon(Icons.search, size: 20, color: Colors.black45),
                                ),
                                prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.star_border, color: Colors.black87, size: 20),
                            onPressed: _isButtonDisabled
                                ? null
                                : () => _handleButton(() async {
                                      // ตัวอย่าง action สำหรับ "ค้นหาขั้นสูง"
                                      Navigator.pushNamed(context, '/category', arguments: {'userid': userId, 'username': username});
                                    }),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'เลือกดูโพส',
                      style: TextStyle(
                        fontSize: 15 * textScale,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isButtonDisabled
                                ? null
                                : () => _handleButton(() async {
                                    Navigator.pushNamed(context, '/postFindJobList', arguments: {'userid': userId, 'username': username});
                                  }),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                              elevation: 0,
                              minimumSize: Size(screenWidth * 0.4, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'โพสต์หางาน',
                              style: TextStyle(fontSize: 14 * textScale),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isButtonDisabled
                                ? null
                                : () => _handleButton(() async {
                                    Navigator.pushNamed(context, '/postFindJobList', arguments: {'userid': userId, 'username': username});
                                  }),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                              elevation: 0,
                              minimumSize: Size(screenWidth * 0.4, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'โพสต์จ้างงาน',
                              style: TextStyle(fontSize: 14 * textScale),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      children: [
                        Text(
                          'หมวดหมู่ทั้งหมด',
                          style: TextStyle(
                            fontSize: 15 * textScale,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          onPressed: _isButtonDisabled
                              ? null
                              : () => _handleButton(() async {
                                  Navigator.pushNamed(context, '/postFindJobList', arguments: {'userid': userId, 'username': username});
                                }),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: screenHeight * 0.012,
                      crossAxisSpacing: screenWidth * 0.02,
                      childAspectRatio: 1.25, // ปรับให้การ์ดเป็นสี่เหลี่ยมผืนผ้ามากขึ้น
                      children: [
                        _ServiceCard(
                          image: 'assets/images/website.png',
                          label: 'เว็บไซต์',
                          onTap: _isButtonDisabled
                              ? () {}
                              : () => _handleButton(() async {
                                  Navigator.pushNamed(context, '/postFindJobList', arguments: {'userid': userId, 'username': username});
                                }),
                          textColor: Colors.black,
                          fontSize: 13 * textScale, // เพิ่มขนาดตัวอักษร
                          imageHeight: screenHeight * 0.16, // ปรับให้ภาพใหญ่ขึ้น
                        ),
                        _ServiceCard(
                          image: 'assets/images/designgraphic.png',
                          label: 'ออกแบบกราฟิก',
                          onTap: _isButtonDisabled
                              ? () {}
                              : () => _handleButton(() async {
                                  Navigator.pushNamed(context, '/postFindJobList', arguments: {'userid': userId, 'username': username});
                                }),
                          textColor: Colors.black,
                          fontSize: 13 * textScale,
                          imageHeight: screenHeight * 0.16,
                        ),
                        _ServiceCard(
                          image: 'assets/images/market.png',
                          label: 'การตลาดโฆษณา',
                          onTap: _isButtonDisabled
                              ? () {}
                              : () => _handleButton(() async {
                                  Navigator.pushNamed(context, '/postFindJobList', arguments: {'userid': userId, 'username': username});
                                }),
                          textColor: Colors.black,
                          fontSize: 13 * textScale,
                          imageHeight: screenHeight * 0.16,
                        ),
                        _ServiceCard(
                          image: 'assets/images/engineer.png',
                          label: 'สถาปัตย์และวิศวกรรม',
                          onTap: _isButtonDisabled
                              ? () {}
                              : () => _handleButton(() async {
                                  Navigator.pushNamed(context, '/postFindJobList', arguments: {'userid': userId, 'username': username});
                                }),
                          textColor: Colors.black,
                          fontSize: 13 * textScale,
                          imageHeight: screenHeight * 0.16,
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.015),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF3A5A99),
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white,
            currentIndex: _selectedIndex,
            onTap: (index) {
              // Use the up-to-date auth data when handling taps
              _onItemTapped(index); // _onItemTapped now reads AuthService directly (no change needed)
            },
            items: const [
              BottomNavigationBarItem(icon: ImageIcon(AssetImage('assets/images/homepage.png')), label: 'หน้าหลัก'),
              BottomNavigationBarItem(icon: ImageIcon(AssetImage('assets/images/status.png')), label: 'สถานะ'),
              BottomNavigationBarItem(icon: ImageIcon(AssetImage('assets/images/postjob.png')), label: 'โพสต์'),
              BottomNavigationBarItem(icon: ImageIcon(AssetImage('assets/images/notification.png')), label: 'แจ้งเตือน'),
              BottomNavigationBarItem(icon: ImageIcon(AssetImage('assets/images/profile.png')), label: 'โปรไฟล์'),
            ],
          ),
        );
      },
    );
  }
}

class _NavIcon extends StatelessWidget {
  final String asset;
  final VoidCallback? onTap;
  const _NavIcon({required this.asset, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Simpler: do not call another State's setState (invalid). Delegate navigation only.
        if (asset == 'assets/images/profile.png') {
          final uidStr = AuthService.userId.value;
          final uid = uidStr != null ? int.tryParse(uidStr) : null;
          final uname = AuthService.username.value;
          if (uid != null) {
            await Navigator.pushReplacementNamed(context, '/paymentPage', arguments: {'userid': uid, 'username': uname});
          } else {
            await Navigator.pushReplacementNamed(context, '/profile');
          }
        } else if (onTap != null) {
          onTap!();
        }
      },
      child: Image.asset(
        asset,
        width: 24,
        height: 24,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;
  final Color textColor;
  final double fontSize;
  final double iconSize;
  const _CategoryIcon({
    required this.label,
    required this.icon,
    required this.onTap,
    this.textColor = Colors.black,
    this.fontSize = 12.0,
    this.iconSize = 40.0,
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
            child: icon.isEmpty
                ? SizedBox(
                    width: iconSize,
                    height: iconSize,
                  )
                : Image.asset(
                    icon,
                    width: iconSize,
                    height: iconSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => SizedBox(
                      width: iconSize,
                      height: iconSize,
                    ),
                  ),
          ),
        ),
        SizedBox(height: fontSize * 0.33),
        Text(label, style: TextStyle(fontSize: fontSize, color: textColor)),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String image;
  final String label;
  final VoidCallback onTap;
  final Color textColor;
  final double fontSize;
  final double imageHeight;
  const _ServiceCard({
    required this.image,
    required this.label,
    required this.onTap,
    this.textColor = Colors.black,
    this.fontSize = 11,
    this.imageHeight = 36,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: imageHeight + 40, // เพิ่มความสูงของ container
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
          mainAxisAlignment: MainAxisAlignment.center, // จัดให้อยู่ตรงกลาง
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(
                  image,
                  fit: BoxFit.cover, // ปรับให้ภาพเต็มพื้นที่มากขึ้น
                  width: double.infinity,
                  height: imageHeight,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: fontSize * 0.18),
              child: Center(
                child: Text(label, style: TextStyle(fontSize: fontSize, color: textColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}










