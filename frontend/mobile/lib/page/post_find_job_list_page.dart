import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class JobListHirePage extends StatefulWidget {
  const JobListHirePage({super.key});

  @override
  State<JobListHirePage> createState() => _JobListHirePageState();
}

class _JobListHirePageState extends State<JobListHirePage> {
  late Future<List<JobPost>> _futurePosts;
  String? postType;
  int? categoryId;
  String? categoryName;
  Map<String, String> userIdToDisplayName = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    postType = args['postType'] as String?;
    categoryId = args['category'] is int ? args['category'] : int.tryParse('${args['category'] ?? ''}');
    categoryName = args['categoryName'] as String?;
    _futurePosts = fetchJobPosts();
  }

  Future<List<JobPost>> fetchJobPosts() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:4000/job/posts'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List data = decoded is List
            ? decoded
            : (decoded is Map && decoded['data'] is List ? decoded['data'] : []);
        final posts = data.map((e) => JobPost.fromJson(e)).toList();

        // Filter posts by approved status, postType and category BEFORE fetching names
        final filtered = posts.where((p) {
          final approved = _isApproved(p.status);
          final typeMatch = postType == null || p.postType == postType;
          final catMatch = categoryId == null || p.categoryId == categoryId;
          return approved && typeMatch && catMatch;
        }).toList();

        // ดึง user displayname เฉพาะโพสต์ที่ผ่านการอนุมัติแล้ว
        await fetchUserNames(filtered);
        return filtered;
      } else {
        throw Exception('Failed to load job posts');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchUserNames(List<JobPost> posts) async {
    final userIds = posts.map((p) => p.posterUid).where((id) => id != null).toSet();
    Map<String, String> result = {};
    for (final uid in userIds) {
      if (uid == null) continue;
      if (userIdToDisplayName.containsKey(uid)) continue;
      try {
        final res = await http.get(Uri.parse('http://localhost:4000/account/profile?user_id=$uid'));
        if (res.statusCode == 200) {
          final jsonMap = json.decode(res.body);
          final displayname = (jsonMap['displayname'] ?? '').toString();
          final username = (jsonMap['username'] ?? '').toString();
          result[uid] = displayname.isNotEmpty ? displayname : username;
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        userIdToDisplayName.addAll(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaleFactor;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF22577A)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Text(
              postType == 'worker'
                  ? 'หางาน'
                  : postType == 'employer'
                      ? 'จ้างงาน'
                      : 'โพสต์',
              style: TextStyle(
                color: const Color(0xFF22577A),
                fontWeight: FontWeight.bold,
                fontSize: 20 * textScale,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              categoryName != null && categoryName!.isNotEmpty
                  ? '(${categoryName!})'
                  : '(หมวดหมู่)',
              style: TextStyle(
                color: const Color(0xFF22577A),
                fontSize: 16 * textScale,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List<JobPost>>(
        future: _futurePosts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล\n${snapshot.error}'));
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return const Center(child: Text('ไม่พบโพสต์งาน'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final posterName = userIdToDisplayName[post.posterUid ?? ''] ?? post.posterUid ?? '-';
              return GestureDetector(
                onTap: () {
                  if (post.postType == 'worker') {
                    Navigator.pushNamed(context, '/postService', arguments: post.id);
                  } else {
                    Navigator.pushNamed(context, '/postJobLogo', arguments: post.id);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 16, height: 100),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          backgroundImage: post.imageUrl != null && post.imageUrl!.isNotEmpty
                              ? NetworkImage(post.imageUrl!)
                              : null,
                          child: post.imageUrl == null || post.imageUrl!.isEmpty
                              ? Text(
                                  'รูป',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 16 * textScale,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.title ?? '-',
                                style: TextStyle(
                                  color: const Color(0xFF22577A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16 * textScale,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                posterName,
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 14 * textScale,
                                ),
                              ),
                              Text(
                                post.budget != null ? 'งบประมาณ ${post.budget} บาท' : '',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 14 * textScale,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                post.timeAgo ?? '',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 13 * textScale,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF3A5A99),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
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
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }
}

class JobPost {
  final String? id;
  final String? title;
  final String? posterUid;
  final String? imageUrl;
  final num? budget;
  final String? timeAgo;
  final String? postType;
  final int? categoryId;
  final String? status;

  JobPost({
    this.id,
    this.title,
    this.posterUid,
    this.imageUrl,
    this.budget,
    this.timeAgo,
    this.postType,
    this.categoryId,
    this.status,
  });

  factory JobPost.fromJson(Map<String, dynamic> json) {
    return JobPost(
      id: (json['post_id'] ?? json['id'])?.toString(),
      title: json['post_name'] ?? json['title'] ?? '',
      posterUid: (json['user_id'] ?? '').toString(),
      imageUrl: json['image_post'] ?? json['image_url'] ?? '',
      budget: _parseNum(json['wage'] ?? json['budget']),
      timeAgo: json['created_at'] != null ? _timeAgo(json['created_at']) : '',
      postType: json['post_type']?.toString(),
      categoryId: json['post_category'] is int
          ? json['post_category']
          : int.tryParse('${json['post_category'] ?? ''}'),
      status: (json['status'] ?? json['post_status'] ?? json['state'])?.toString(),
    );
  }
}

// Helper: แปลง wage/budget เป็น num? รองรับ String/int/double/null
num? _parseNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

// Helper: แปลงวันที่เป็น "x ชั่วโมงที่แล้ว"
String _timeAgo(String createdAt) {
  try {
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays} วันที่แล้ว';
    if (diff.inHours > 0) return '${diff.inHours} ชั่วโมงที่แล้ว';
    if (diff.inMinutes > 0) return '${diff.inMinutes} นาทีที่แล้ว';
    return 'เมื่อสักครู่';
  } catch (_) {
    return '';
  }
}

// New helper: ตรวจสอบว่า status ถือเป็น "อนุมัติ" หรือไม่
bool _isApproved(String? status) {
  if (status == null) return false;
  final s = status.toString().toLowerCase().trim();
  return s == 'approve' || s == 'approved' || s == '1' || s == 'true';
}
