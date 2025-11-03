import 'package:flutter/material.dart';
import 'post_profile_page.dart';
import 'package:getwork_app/service/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileEducationPage extends StatefulWidget {
  const ProfileEducationPage({super.key});

  @override
  State<ProfileEducationPage> createState() => _ProfileEducationPageState();
}

class _ProfileEducationPageState extends State<ProfileEducationPage> {
  Map<String, dynamic>? _profile;
  bool _loading = false;
  final String baseUrl = 'http://192.168.100.11:4000';
  late VoidCallback _authListener;

  @override
  void initState() {
    super.initState();
    // listen to auth changes so we clear profile on logout and reload on login
    _authListener = () {
      final uid = AuthService.userId.value;
      if (uid == null || uid.isEmpty) {
        if (mounted) setState(() { _profile = null; });
      } else {
        final id = int.tryParse(uid) ?? 0;
        if (id > 0) _fetchProfile(id);
      }
    };
    AuthService.userId.addListener(_authListener);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileFromArgsOrPrefs());
  }

  @override
  void dispose() {
    AuthService.userId.removeListener(_authListener);
    super.dispose();
  }

  Future<void> _loadProfileFromArgsOrPrefs() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    String? uid = args['userid']?.toString();
    if (uid == null || uid.isEmpty) {
      uid = AuthService.userId.value;
    }
    if (uid == null || uid.isEmpty) return;
    await _fetchProfile(int.tryParse(uid) ?? 0);
  }

  // add helper
  dynamic _tryParseJson(String? text) {
    if (text == null) return null;
    final t = text.trim();
    if (t.isEmpty) return null;
    try {
      return jsonDecode(t);
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchProfile(int userId) async {
    if (userId == 0) return;
    setState(() { _loading = true; });
    try {
      final url = Uri.parse('$baseUrl/account/profile?user_id=$userId');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final parsed = _tryParseJson(res.body) as Map<String, dynamic>?;
        if (parsed != null) {
          final map = parsed;
          if (map['image'] != null && map['image'] is String) {
            final img = map['image'] as String;
            if (img.startsWith('/')) map['image'] = '$baseUrl$img';
          }
          setState(() {
            _profile = map;
          });
        }
      }
    } catch (e) {
      // ignore for now
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
  // ignore: deprecated_member_use
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;
    const blue = Color(0xFF2E628A);

    final displayName = _profile?['displayname'] ?? _profile?['username'] ?? 'ชื่อผู้ใช้';
    final about = _profile?['about_me'] ?? 'รายละเอียดภายใน';
    final educationLevel = _profile?['education_level'] ?? 'ระดับการศึกษา';
    final educationHistory = _profile?['education_history'] ?? 'ประวัติการศึกษา';
    final workExperience = _profile?['work_experience'] ?? 'ประสบการณ์/หัวข้อ';

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              // Top header: back + avatar + username
              Container(
                color: blue,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                height: 110,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: _profile != null && _profile!['image'] != null
                          ? ClipOval(child: Image.network(_profile!['image'].toString(), width: 52, height: 52, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Text('รูป', style: TextStyle(color: blue))))
                          : Text('รูป', style: TextStyle(color: blue, fontSize: 12 * textScale)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18 * textScale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Tab bar
              const Material(
                color: Colors.white,
                elevation: 2,
                child: TabBar(
                  // ปกติ: แตะแท็บจะเปลี่ยน TabBarView เท่านั้น (ไม่ push หน้าใหม่)
                  labelColor: blue,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: blue,
                  tabs: [
                    Tab(text: 'รายละเอียด'),
                    Tab(text: 'สิ่งที่โพส'),
                    Tab(text: 'รีวิว'),
                  ],
                ),
              ),

              // Tab views
              Expanded(
                child: Builder(builder: (context) {
                  // sample reviews data (replace with real data)
                  final reviews = [
                    {'name': 'ชื่อผู้ว่าจ้าง 1', 'date': '01/01/2024', 'rating': 5.0},
                    {'name': 'ชื่อผู้ว่าจ้าง 2', 'date': '02/02/2024', 'rating': 4.8},
                  ];

                  return TabBarView(
                    children: [
                      // Tab: รายละเอียด (ตามภาพ)
                      SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // รายละเอียดภายใน - big rounded box
                            const Text('รายละเอียด', style: TextStyle(color: blue, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                constraints: const BoxConstraints(minHeight: 120),
                                child: Text(
                                  about,
                                  style: TextStyle(color: Colors.black54, fontSize: 14 * textScale),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // การศึกษา section
                            const Row(
                              children: [
                                Text('การศึกษา', style: TextStyle(color: blue, fontWeight: FontWeight.w600)),
                                Spacer(),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // ระดับการศึกษา
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                child: Text(educationLevel, style: TextStyle(fontSize: 14 * textScale, color: Colors.black87)),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // ประวัติการศึกษา
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                child: Text(educationHistory, style: TextStyle(fontSize: 14 * textScale, color: Colors.black87)),
                              ),
                            ),

                            const SizedBox(height: 18),

                            // ประสบการณ์ทำงาน section
                            const Row(
                              children: [
                                Text('ประสบการณ์ทำงาน', style: TextStyle(color: blue, fontWeight: FontWeight.w600)),
                                Spacer(),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 1,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                constraints: const BoxConstraints(minHeight: 120),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(workExperience, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15 * textScale)),
                                    const SizedBox(height: 6),
                                    const Text('', style: TextStyle(color: Colors.black54)),
                                    const SizedBox(height: 6),
                                    const Text('', style: TextStyle(color: Colors.black45)),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // Tab: สิ่งที่โพส -> ใช้ PostListContent แทน placeholder
                      const PostListContent(),

                      // Tab: รีวิว -> แสดงหัวข้อ + รายการรีวิว
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                            child: Text(
                              'รีวิวจากผู้ว่าจ้าง (${reviews.length})',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: blue),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              itemCount: reviews.length,
                              itemBuilder: (ctx, i) {
                                final r = reviews[i];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.blue.shade50,
                                          child: Text('รูป', style: TextStyle(color: blue, fontSize: 11 * textScale)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                r['name'] as String,
                                                style: TextStyle(fontSize: 14 * textScale, fontWeight: FontWeight.w600),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                r['date'] as String,
                                                style: TextStyle(fontSize: 12 * textScale, color: Colors.black45),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 18),
                                            const SizedBox(width: 6),
                                            Text(
                                              (r['rating'] as double).toStringAsFixed(1),
                                              style: TextStyle(fontSize: 13 * textScale, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
             ),
           ],
         ),
       ),
     ),
   );
 }
}
