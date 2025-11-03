import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:getwork_app/service/auth_service.dart';
import 'package:getwork_app/main.dart' as app_main;

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController educationHistoryController = TextEditingController();

  String? selectedEducationLevel;
  final List<String> educationLevels = [
    'มัธยมศึกษาต้น',
    'มัธยมศึกษาปลาย',
    'ปริญญาตรี',
    'ปริญญาโท',
    'ปริญญาเอก',
  ];

  File? _profileImage;
  // IMPORTANT: this should point to the main backend API (server.ts), not the
  // AI model service. The model runs on port 5000 in the AI folder; the main
  // backend listens on port 4000 by default. Adjust if your servers are on
  // different hosts.
  final String baseUrl = 'http://192.168.100.11:4000'; // backend API base URL
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    // Capture route arguments synchronously in the post-frame callback, then
    // call the async loader with the resolved userId. This avoids calling
    // ModalRoute.of(context) from inside an async method (which the analyzer
    // flags as using BuildContext across async gaps).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
      var userId = args['userid'] ?? args['userId'];
      // prefer in-memory AuthService if route arg is not provided
      userId ??= AuthService.userId.value;
      _loadInitialProfile(userId);
    });
    // react to global auth changes so logout clears this page immediately
    AuthService.userId.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    try {
      AuthService.userId.removeListener(_onAuthChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onAuthChanged() {
    final uid = AuthService.userId.value;
    if (uid == null) {
      // clear UI when logged out
      if (mounted) {
        setState(() {
          nameController.text = '';
          aboutController.text = '';
          experienceController.text = '';
          educationHistoryController.text = '';
          selectedEducationLevel = null;
          _profileImage = null;
          _currentImageUrl = null;
        });
      }
    } else {
      // when logged in, reload profile
      final id = int.tryParse(uid) ?? 0;
      if (id > 0) _loadInitialProfile();
    }
  }

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

  Future<void> _loadInitialProfile([dynamic userId]) async {
    // _loadInitialProfile may be called with a userId captured synchronously
    // from the route (see initState). If none was provided, fall back to the
    // authoritative in-memory AuthService value.
    if (userId == null) {
      userId = AuthService.userId.value;
    }
    // if no userId -> clear UI (avoid showing previous user)
    if (userId == null || userId.toString().isEmpty) {
      if (mounted) {
        setState(() {
          nameController.text = '';
          aboutController.text = '';
          experienceController.text = '';
          educationHistoryController.text = '';
          selectedEducationLevel = null;
          _profileImage = null;
          _currentImageUrl = null;
        });
      }
      return;
    }

    try {
    final res = await http.get(Uri.parse('$baseUrl/account/profile?user_id=$userId'));
    if (res.statusCode == 200) {
        final parsed = _tryParseJson(res.body) as Map<String, dynamic>?;
        if (parsed != null) {
          final data = parsed;
          // populate controllers
          nameController.text = (data['displayname'] ?? data['username'] ?? '').toString();
          aboutController.text = (data['about_me'] ?? '').toString();
          experienceController.text = (data['work_experience'] ?? '').toString();
          educationHistoryController.text = (data['education_history'] ?? '').toString();
          final lvl = data['education_level'];
          if (lvl != null && educationLevels.contains(lvl)) {
            if (mounted) {
              setState(() {
                selectedEducationLevel = lvl.toString();
              });
            }
          }
          // normalize and persist image URL
          String? img = data['image']?.toString();
          if (img != null && img.startsWith('/')) img = '$baseUrl$img';
          if (mounted) {
            setState(() {
              _currentImageUrl = img;
            });
          }
          final prefs = await SharedPreferences.getInstance();
          if (img != null) {
            await prefs.setString('profileImage', img);
            AuthService.profileImage.value = img;
          }
        }
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    // รับ userId จาก arguments หรือ AuthService (authoritative). Do NOT read
    // SharedPreferences for userid here so logout state is respected.
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    var userId = args['userid'] ?? args['userId'];
    userId ??= AuthService.userId.value;
    if (userId == null || userId.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบ userId')),
      );
      return;
    }
  final idStr = userId.toString();

    String? imageUrl;
    if (_profileImage != null) {
      // Upload directly to the main backend. Server will run model verification
      // (server-side) and reject the upload if the image is inappropriate.
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/account/profile/image?user_id=$idStr'),
        );
        request.files.add(await http.MultipartFile.fromPath('image', _profileImage!.path));
        var res = await request.send();
        if (res.statusCode == 200) {
          var responseData = await res.stream.bytesToString();
          var data = _tryParseJson(responseData);
          // server currently returns updated profile object; extract image field if present
          imageUrl = (data is Map && (data['image'] != null))
              ? data['image']
              : (data is Map && data['url'] != null ? data['url'] : null);

          // IMPORTANT: normalize returned image URL to a relative path before
          // sending it to the backend for DB storage. The backend stores
          // relative paths like `/uploads/<filename>`. If the model/backend
          // returned an absolute URL (http://host/...), strip the host so
          // we only send the path portion.
          if (imageUrl != null && imageUrl is String) {
            try {
              // If server returned absolute URL that begins with our baseUrl,
              // remove that prefix.
              if (imageUrl.startsWith(baseUrl)) {
                imageUrl = imageUrl.substring(baseUrl.length);
              } else {
                // If it's another absolute URL (starts with http), parse and keep only path+query
                final parsed = Uri.parse(imageUrl);
                if (parsed.hasScheme && parsed.host.isNotEmpty) {
                  var pathAndQuery = parsed.path;
                  if (parsed.hasQuery && parsed.query.isNotEmpty) pathAndQuery += '?${parsed.query}';
                  imageUrl = pathAndQuery;
                }
              }
            } catch (_) {
              // If parsing fails, leave imageUrl as-is; backend can also accept
              // absolute URLs but our goal is to prefer relative paths.
            }
          }
        } else {
          if (!mounted) return;
          var body = await res.stream.bytesToString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('อัปโหลดรูปภาพไม่สำเร็จ: ${res.statusCode} ${body}')),
          );
          return;
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดขณะอัปโหลดรูปภาพ: $e')),
        );
        return;
      }
    }

    // อัพเดทข้อมูลโปรไฟล์
    final response = await http.put(
      Uri.parse('$baseUrl/account/profile?user_id=$idStr'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'displayname': nameController.text,
        'about_me': aboutController.text,
        'education_level': selectedEducationLevel,
        'education_history': educationHistoryController.text,
        'work_experience': experienceController.text,
        if (imageUrl != null)
          // send path or absolute URL; server accepts either. send absolute to be safe.
          'image': imageUrl,
      }),
    );

  if (response.statusCode == 200) {
      // parse updated profile from server and persist final image URL
      final updated = _tryParseJson(response.body) as Map<String, dynamic>?;
      if (updated != null) {
        var updatedImage = updated['image'] as String?;
        if (updatedImage != null && updatedImage.startsWith('/')) updatedImage = '$baseUrl$updatedImage';
        if (updatedImage != null) { 
            if (mounted) {
              setState(() { _currentImageUrl = updatedImage; });
            }
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('profileImage', updatedImage);
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      // Navigate to payment page after saving profile. Pass userid and
      // username so PaymentPage can immediately load the profile and show
      // the user's image.
      // Prefer using the global navigatorKey (works even if local context
      // navigation stack is different). Fall back to local Navigator and
      // finally to pushNamedAndRemoveUntil. Surface an error to the user if
      // navigation fails so debugging is easier.
      final navArgs = {
        'userid': idStr,
        'username': nameController.text.isNotEmpty ? nameController.text : null,
      };
      try {
        final navigatorState = app_main.navigatorKey.currentState;
        if (navigatorState != null) {
          await navigatorState.pushReplacementNamed('/paymentPage', arguments: navArgs);
        } else {
          await Navigator.pushReplacementNamed(context, '/paymentPage', arguments: navArgs);
        }
      } catch (e) {
        // last-resort: replace whole stack with payment page
          try {
          await Navigator.pushNamedAndRemoveUntil(context, '/paymentPage', (route) => false, arguments: navArgs);
        } catch (e2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ไม่สามารถไปยังหน้า Payment ได้: $e2')),
            );
          }
        }
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกข้อมูลไม่สำเร็จ: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // เปลี่ยนจาก Color(0xFF7B668C) เป็นสีขาว
      appBar: AppBar(
        title: ValueListenableBuilder<String?>(
          valueListenable: AuthService.userId,
          builder: (context, uid, _) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
            final forceLogout = args['forceLogout'] == true;
            final idText = forceLogout ? '' : (uid ?? '');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ตั้งค่าบัญชี', style: TextStyle(color: Color(0xFF3A5A99))),
                if (idText.isNotEmpty)
                  Text('User ID: $idText', style: const TextStyle(color: Color(0xFF3A5A99), fontSize: 12)),
              ],
            );
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3A5A99)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3A5A99)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/profile');
            }
          },
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          margin: const EdgeInsets.symmetric(vertical: 32),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // หัวข้อ
                  const Text('รูปภาพโปรไฟล์', style: TextStyle(color: Color(0xFF3A5A99), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 160,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: _profileImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(_profileImage!, fit: BoxFit.cover, width: 160, height: 100),
                              )
                            : (_currentImageUrl != null
                                ? Image.network(
                                    _currentImageUrl!,
                                    fit: BoxFit.cover,
                                    width: 160,
                                    height: 100,
                                  )
                                : const Center(
                                    child: Text('อัปโหลดรูป', style: TextStyle(color: Color(0xFF3A5A99), fontSize: 16)),
                                  )),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('ชื่อ', style: TextStyle(color: Color(0xFF3A5A99), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'ระบุชื่อ....',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('ประวัติการศึกษา', style: TextStyle(color: Color(0xFF3A5A99), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: educationHistoryController,
                    decoration: InputDecoration(
                      hintText: 'เช่น มหาวิทยาลัย/โรงเรียน',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('เกี่ยวกับบัญชี', style: TextStyle(color: Color(0xFF3A5A99), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: aboutController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'อธิบายรายละเอียด...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('ระดับการศึกษา', style: TextStyle(color: Color(0xFF3A5A99), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedEducationLevel,
                    items: educationLevels
                        .map((level) => DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedEducationLevel = value;
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('ประสบการณ์การทำงาน', style: TextStyle(color: Color(0xFF3A5A99), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: experienceController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/forgotNewPassword');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22577A),
                          minimumSize: const Size(120, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('เปลี่ยนรหัสผ่าน', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22577A),
                          minimumSize: const Size(120, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('บันทึก', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}





