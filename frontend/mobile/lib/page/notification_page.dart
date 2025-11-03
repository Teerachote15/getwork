import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

// (removed accidental duplicate class) 

String _detectApiBase() {
  const env = String.fromEnvironment('API_BASE', defaultValue: '');
  if (env.isNotEmpty) return env;
  if (kIsWeb) return 'http://localhost:4000';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      // Android emulator: host machine is 10.0.2.2
      return 'http://10.0.2.2:4000';
    case TargetPlatform.iOS:
      return 'http://localhost:4000';
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
      return 'http://localhost:4000';
    default:
      return 'http://localhost:4000';
  }
}

class _NotificationPageState extends State<NotificationPage> {
  // runtime-resolved API base (platform-aware)
  final String _apiBase = _detectApiBase();

  int? _userId;
  Future<List<Map<String, dynamic>>>? _futureNotifications;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // read optional route args: { 'userid': 123, 'username': '...' }
    if (_futureNotifications == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final possible = args['userid'] ?? args['userId'] ?? args['user_id'];
        if (possible != null) {
          _userId = int.tryParse(possible.toString());
        }
      }
      _futureNotifications = _fetchNotifications();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    final uid = _userId ?? 1; // fallback to user 1 if not provided
    final url = Uri.parse('$_apiBase/notifications?user_id=$uid');
    http.Response resp;
    try {
      resp = await http.get(url).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw Exception('Timeout connecting to server at $_apiBase. Is the backend running?');
    } catch (e) {
      throw Exception('Failed to connect to server: ${e.toString()}');
    }
    if (resp.statusCode != 200) {
      // try to include server message when available
      try {
        final err = json.decode(resp.body);
        throw Exception('Failed to load notifications: ${err['message'] ?? resp.statusCode}');
      } catch (_) {
        throw Exception('Failed to load notifications: ${resp.statusCode}');
      }
    }
    final body = json.decode(resp.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];
    return data.map((e) => (e as Map<String, dynamic>)).toList();
  }

  // Mark a notification as read on the server. Returns true when success.
  Future<bool> _markAsRead(int notificationId) async {
    final url = Uri.parse('$_apiBase/notifications/$notificationId/read');
    try {
      final resp = await http.post(url, headers: {'Content-Type': 'application/json'}).timeout(const Duration(seconds: 6));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Simple created_at formatter. Falls back to raw string on parse error.
  String _formatCreatedAt(String? s) {
    if (s == null || s.isEmpty) return '';
    try {
      final dt = DateTime.parse(s);
      final dd = dt.day.toString().padLeft(2, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      final yyyy = dt.year;
      final hh = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$dd/$mm/$yyyy $hh:$min';
    } catch (_) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แจ้งเตือน'),
        backgroundColor: const Color(0xFF3A5A99),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _futureNotifications,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                final err = snapshot.error;
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'เกิดข้อผิดพลาด:\n${err.toString()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _futureNotifications = _fetchNotifications();
                          });
                        },
                        child: const Text('ลองอีกครั้ง'),
                      ),
                    ],
                  ),
                );
              }
              final notifications = snapshot.data ?? <Map<String, dynamic>>[];
              if (notifications.isEmpty) return const Center(child: Text('ไม่มีการแจ้งเตือน'));

              return RefreshIndicator(
                onRefresh: () async {
                  final f = _fetchNotifications();
                  setState(() {
                    _futureNotifications = f;
                  });
                  await f;
                },
                child: ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    final message = (n['message'] ?? '').toString();
                    final isRead = (n['is_read'] ?? 0) == 1 || (n['is_read'] == true);
                    final bgColor = isRead ? const Color(0xFFBDBDBD) : const Color(0xFF6CA6C1);

                    final deadlineRaw = n['deadline']?.toString() ?? '';
                    final imageRaw = n['image']?.toString() ?? '';
                    // normalize image url: if it's a relative path like '/uploads/..' prefix with api base
                    String? imageUrl;
                    if (imageRaw.isNotEmpty) {
                      if (imageRaw.startsWith('http://') || imageRaw.startsWith('https://')) {
                        imageUrl = imageRaw;
                      } else if (imageRaw.startsWith('/')) {
                        imageUrl = '$_apiBase$imageRaw';
                      } else {
                        imageUrl = imageRaw;
                      }
                    }

                    final hasJob = n.containsKey('job_id') && (n['job_id'] != null);

                    return GestureDetector(
                      onTap: () {
                        // If this notification originates from notifications table (no job_id), mark as read.
                        final nid = n['notification_id'];
                        if (!hasJob && nid is int && !isRead) {
                          _markAsRead(nid).then((ok) {
                            if (!mounted) return;
                            if (ok) {
                              setState(() {
                                n['is_read'] = 1;
                              });
                            }
                          });
                        }

                        // Navigate to detail page with the full notification object (includes job fields if present)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationDetailPage(notification: n),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    deadlineRaw.isNotEmpty ? 'กำหนด: $deadlineRaw' : _formatCreatedAt(n['created_at']?.toString()),
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            if (imageUrl != null) ...[
                              const SizedBox(width: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: Colors.black12, width: 56, height: 56),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF3A5A99),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
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

class NotificationDetailPage extends StatefulWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailPage({super.key, required this.notification});

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  bool _isProcessing = false;

  String get _apiBase => _detectApiBase();

  Future<void> _respondToJob(String action) async {
    // action: 'accept' | 'reject'
    final jobId = widget.notification['job_id'] ?? widget.notification['jobId'] ?? widget.notification['job_id'];
    if (jobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลงานที่จะตอบรับ')));
      return;
    }

    setState(() => _isProcessing = true);
    final url = Uri.parse('$_apiBase/job/details/$jobId/$action');
    try {
      final resp = await http.post(url).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(action == 'accept' ? 'เริ่มงานเรียบร้อย' : 'ปฏิเสธงานเรียบร้อย')));
        // Close detail and signal parent to refresh
        Navigator.pop(context, {'action': action, 'job_id': jobId});
      } else {
        final body = tryDecodeJson(resp.body);
        final msg = body?['error'] ?? body?['message'] ?? 'HTTP ${resp.statusCode}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ข้อผิดพลาด: $msg')));
      }
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เชื่อมต่อเซิร์ฟเวอร์ timeout')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Map<String, dynamic>? tryDecodeJson(String s) {
    try {
      final v = json.decode(s);
      if (v is Map<String, dynamic>) return v;
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final screenWidth = MediaQuery.of(context).size.width;
    // ignore: deprecated_member_use
    final textScale = MediaQuery.of(context).textScaleFactor;

    final detailText = (n['detail'] ?? n['message'] ?? '-').toString();
    final deadline = (n['deadline'] ?? n['due_date'] ?? '').toString();
    final contact = (n['contact'] ?? n['phone'] ?? n['contact_info'] ?? '').toString();
    final imageUrl = (n['image'] ?? n['image_url'] ?? n['file'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF22577A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'รายละเอียดงานที่ส่งมา',
          style: TextStyle(
            color: const Color(0xFF22577A),
            fontWeight: FontWeight.bold,
            fontSize: 20 * textScale,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('รูปแบบงานที่ต้องการ', style: TextStyle(color: const Color(0xFF22577A), fontWeight: FontWeight.bold, fontSize: 14 * textScale)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 120),
              decoration: BoxDecoration(color: const Color(0xFFEFEFEF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF3A89D1))),
              padding: const EdgeInsets.all(12),
              child: Text(detailText, style: TextStyle(color: Colors.grey[900], fontSize: 14 * textScale)),
            ),

            const SizedBox(height: 16),
            Text('ระยะเวลาที่ต้องเสร็จ (ว/ด/ป)', style: TextStyle(color: const Color(0xFF22577A), fontWeight: FontWeight.bold, fontSize: 14 * textScale)),
            const SizedBox(height: 8),
            Container(
              width: 140,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(8)),
              child: Text(deadline.isEmpty ? '-' : deadline, style: TextStyle(color: Colors.grey[800])),
            ),

            const SizedBox(height: 16),
            Text('รูปแบบตัวอย่างงาน', style: TextStyle(color: const Color(0xFF22577A), fontWeight: FontWeight.bold, fontSize: 14 * textScale)),
            const SizedBox(height: 8),
            if (imageUrl.isNotEmpty)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey[200]),
                child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Text('ไม่สามารถโหลดรูปภาพ'))),
              )
            else
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(8)),
                child: const Text('ไฟล์', style: TextStyle(color: Colors.black54)),
              ),

            const SizedBox(height: 16),
            Text('ช่องทางการติดต่อ', style: TextStyle(color: const Color(0xFF22577A), fontWeight: FontWeight.bold, fontSize: 14 * textScale)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(12),
              child: Text(contact.isEmpty ? '-' : contact, style: TextStyle(color: Colors.grey[800], fontSize: 14 * textScale)),
            ),

            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : () => _respondToJob('accept'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isProcessing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('ตกลงเริ่มงาน', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : () => _respondToJob('reject'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('ปฏิเสธงาน', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
