import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<dynamic> _users = [];
  bool _loading = true;

  String get backendBase {
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:4000';
    } catch (_) {}
    return 'http://localhost:4000';
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() { _loading = true; });
    try {
      final resp = await http.get(Uri.parse('$backendBase/chat/users'));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        // Expect either an array or { data: [...] }
        final list = body is List ? body : (body['data'] is List ? body['data'] : []);
        setState(() { _users = list; });
      } else {
        // fallback: keep empty list
        setState(() { _users = []; });
      }
    } catch (e) {
      // network error - keep fallback sample list
      setState(() {
        _users = [
          {'uid': '2', 'name': 'Somchai', 'avatar': null, 'lastMessage': 'สวัสดี', 'time': '10:12'},
          {'uid': '3', 'name': 'Suda', 'avatar': null, 'lastMessage': 'ตกลงครับ', 'time': '09:01'},
        ];
      });
    } finally {
      setState(() { _loading = false; });
    }
  }

  void _openChat(dynamic user) {
    final uid = user['uid']?.toString() ?? '';
    final name = user['name'] ?? '';
    if (uid.isEmpty) return;
    Navigator.pushNamed(context, '/chat', arguments: {'uid': uid, 'name': name});
  }

  @override
  Widget build(BuildContext context) {
    const Color appBarColor = Color(0xFF3B6A81);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white,
              child: Text(
                'รูป',
                style: TextStyle(
                  color: Color(0xFF3B6A81),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'แชท',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchUsers,
              child: _users.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 48),
                        Center(child: Text('ไม่มีผู้ใช้งานสำหรับแชท')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final u = _users[index];
                        final name = u['name'] ?? 'ผู้ใช้';
                        final last = u['lastMessage'] ?? '';
                        final time = u['time'] ?? '';
                        final avatar = u['avatar'];
                        return ListTile(
                          onTap: () => _openChat(u),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey[200],
                            child: avatar == null
                                ? Text(name.toString().isNotEmpty ? name.toString()[0] : '?', style: const TextStyle(color: Colors.black54))
                                : null,
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(last, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Text(time, style: const TextStyle(fontSize: 12, color: Colors.black45)),
                        );
                      },
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


