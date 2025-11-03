import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PostJobLogoPage extends StatefulWidget {
  const PostJobLogoPage({super.key});

  @override
  State<PostJobLogoPage> createState() => _PostJobLogoPageState();
}

class _PostJobLogoPageState extends State<PostJobLogoPage> {
  late Future<JobPost?> _futurePost;
  String? postId;
  String? posterDisplayName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    postId = args is String ? args : (args is int ? args.toString() : null);
    if (postId != null) {
      _futurePost = fetchJobPost(postId!);
    }
  }

  Future<JobPost?> fetchJobPost(String id) async {
    final url = 'http://localhost:4000/job/posts/$id';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonMap = json.decode(response.body);
      final post = JobPost.fromJson(jsonMap);
      // fetch displayname
      if (post.posterUid != null) {
        try {
          final res = await http.get(Uri.parse('http://localhost:4000/account/profile?user_id=${post.posterUid}'));
          if (res.statusCode == 200) {
            final user = json.decode(res.body);
            final displayname = (user['displayname'] ?? '').toString();
            final username = (user['username'] ?? '').toString();
            setState(() {
              posterDisplayName = displayname.isNotEmpty ? displayname : username;
            });
          }
        } catch (_) {}
      }
      return post;
    }
    return null;
  }

  String getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) return imageUrl;
    return 'http://localhost:4000${imageUrl.startsWith('/') ? imageUrl : '/$imageUrl'}';
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaleFactor;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF22577A), size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'กลับ',
          style: TextStyle(
            color: const Color(0xFF22577A),
            fontSize: 20 * textScale,
          ),
        ),
      ),
      body: postId == null
          ? const Center(child: Text('ไม่พบโพสต์'))
          : FutureBuilder<JobPost?>(
              future: _futurePost,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return const Center(child: Text('ไม่พบข้อมูลโพสต์นี้'));
                }
                final post = snapshot.data!;
                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          post.title ?? '-',
                          style: TextStyle(
                            color: const Color(0xFF22577A),
                            fontWeight: FontWeight.bold,
                            fontSize: 26 * textScale,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                'รูป',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 16 * textScale,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ผู้โพสต์: ${posterDisplayName ?? "-"}',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15 * textScale,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                // เพิ่มเบอร์โทรศัพท์ถ้ามีใน post
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          '• รายละเอียดงาน',
                          style: TextStyle(
                            color: const Color(0xFF22577A),
                            fontSize: 16 * textScale,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post.description ?? '-',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15 * textScale,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'ระยะเวลา',
                          style: TextStyle(
                            color: const Color(0xFF22577A),
                            fontWeight: FontWeight.bold,
                            fontSize: 17 * textScale,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'ภายใน........', // หากมี field deadline ให้แสดงตรงนี้
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 15 * textScale,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'ตัวอย่างงาน',
                          style: TextStyle(
                            color: const Color(0xFF22577A),
                            fontWeight: FontWeight.bold,
                            fontSize: 17 * textScale,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: post.imageUrl != null && post.imageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    getFullImageUrl(post.imageUrl),
                                    width: double.infinity,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Text(
                                        'โหลดรูปภาพไม่สำเร็จ',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 16 * textScale,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    'ไม่มีตัวอย่างงาน',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 16 * textScale,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          post.budget != null ? 'เรทราคาอยู่ที่ ${post.budget} บาท' : 'ไม่ระบุราคา',
                          style: TextStyle(
                            color: const Color(0xFF22577A),
                            fontSize: 20 * textScale,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/postJobDetails');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3793C5),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'สนใจรับงาน',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18 * textScale,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
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
  final String? description;

  JobPost({
    this.id,
    this.title,
    this.posterUid,
    this.imageUrl,
    this.budget,
    this.description,
  });

  factory JobPost.fromJson(Map<String, dynamic> json) {
    return JobPost(
      id: (json['post_id'] ?? json['id'])?.toString(),
      title: json['post_name'] ?? json['title'] ?? '',
      posterUid: (json['user_id'] ?? '').toString(),
      imageUrl: json['image_post'] ?? json['image_url'] ?? '',
      budget: _parseNum(json['wage'] ?? json['budget']),
      description: json['description'] ?? '',
    );
  }
}

num? _parseNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}
