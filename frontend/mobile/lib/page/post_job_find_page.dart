import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:getwork_app/service/auth_service.dart';

class PostJobFindPage extends StatefulWidget {
  const PostJobFindPage({super.key});

  @override
  State<PostJobFindPage> createState() => _PostJobFindPageState();
}

class _PostJobFindPageState extends State<PostJobFindPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _budget = '';
  File? _sampleImage;
  bool _isPosting = false;
  final String baseUrl = 'http://192.168.100.11:4000';
  List<Map<String, String>> _categories = [];
  String? _selectedCategoryId; // เปลี่ยนจากค่าคงที่เป็น nullable

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
  // ignore: deprecated_member_use
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'โพสต์หางาน',
          style: TextStyle(
            color: const Color(0xFF22577A),
            fontSize: 20 * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF22577A)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // อัปโหลดตัวอย่างงาน
                Text(
                  'อัปโหลดตัวอย่างงาน',
                  style: TextStyle(
                    color: const Color(0xFF22577A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * textScale,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: GestureDetector(
                    onTap: _pickSampleImage,
                    child: Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: _sampleImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(_sampleImage!, fit: BoxFit.cover, width: double.infinity, height: 100),
                            )
                          : const Center(
                              child: Text('อัปโหลดรูป', style: TextStyle(color: Color(0xFF3A5A99), fontSize: 16)),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // ชื่องาน/ประเภทงาน + หมวดหมู่ (Dropdown)
                Row(
                  children: [
                    Text(
                      'ชื่องาน/ประเภทงาน',
                      style: TextStyle(
                        color: const Color(0xFF22577A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16 * textScale,
                      ),
                    ),
                    const Spacer(),
                    // Dropdown หมวดหมู่
                    Container(
                      width: 180,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        isExpanded: true,
                        decoration: const InputDecoration.collapsed(hintText: ''),
                        hint: const Text('เลือกหมวดหมู่'),
                        items: _categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat['category_id'],
                            child: Text(cat['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategoryId = val;
                          });
                        },
                        validator: (val) => val == null || val.isEmpty ? 'กรุณาเลือกหมวดหมู่' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'ระบุชื่องานและประเภทงานที่คุณต้องการโพสต์',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  ),
                  style: TextStyle(fontSize: 15 * textScale),
                  validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่องาน' : null,
                  onChanged: (val) => _title = val,
                ),
                const SizedBox(height: 24),
                // เกี่ยวกับฟรีแลนซ์
                Text(
                  'เกี่ยวกับฟรีแลนซ์',
                  style: TextStyle(
                    color: const Color(0xFF22577A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * textScale,
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'อธิบายจุดแข็งของคุณโดยสังเขปเพื่อใช้ในการประกอบการพิจารณา',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  ),
                  style: TextStyle(fontSize: 15 * textScale),
                  validator: (value) => value!.isEmpty ? 'กรุณากรอกรายละเอียด' : null,
                  onChanged: (val) => _description = val,
                ),
                const SizedBox(height: 24),
                // งบประมาณ/ค่าแรง
                Text(
                  'งบประมาณ/ค่าแรง (บาท)',
                  style: TextStyle(
                    color: const Color(0xFF22577A),
                    fontWeight: FontWeight.bold,
                    fontSize: 15 * textScale,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  ),
                  style: TextStyle(fontSize: 15 * textScale),
                  validator: (value) => value!.isEmpty ? 'กรุณาระบุงบประมาณ' : null,
                  onChanged: (val) => _budget = val,
                ),
                SizedBox(height: screenHeight * 0.06),
                // ปุ่มโพสต์
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      await _submitPost();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22577A),
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isPosting ? 'กำลังโพสต์...' : 'โพสต์',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20 * textScale,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickSampleImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _sampleImage = File(picked.path);
      });
    }
  }

  Future<void> _submitPost() async {
    if (_isPosting) return;
    setState(() => _isPosting = true);

    // determine user id (prefer route args then AuthService)
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    var userId = args['userid'] ?? args['userId'];
    userId ??= AuthService.userId.value;
    if (userId == null || userId.toString().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนโพสต์')));
      }
      setState(() => _isPosting = false);
      return;
    }
    final idStr = userId.toString();

    // ตรวจสอบว่ามีการเลือกหมวดหมู่หรือไม่
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกหมวดหมู่')));
      }
      setState(() => _isPosting = false);
      return;
    }

    try {
      if (_sampleImage != null) {
        var uri = Uri.parse('$baseUrl/job/posts');
        var request = http.MultipartRequest('POST', uri);
        request.fields['user_id'] = idStr;
        request.fields['post_name'] = _title;
        request.fields['description'] = _description;
        request.fields['wage'] = _budget;
        request.fields['post_category_id'] = _selectedCategoryId!;
        request.fields['post_type'] = 'worker'; // เพิ่ม post_type
        if (_sampleImage != null) {
          request.files.add(await http.MultipartFile.fromPath('image', _sampleImage!.path));
        }
        var streamed = await request.send();
        final respStr = await streamed.stream.bytesToString();
        if (streamed.statusCode == 200 || streamed.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('โพสต์หางานสำเร็จ')));
            // --- เรียก API /job/posts หลังโพสต์สำเร็จ ---
            try {
              final postsRes = await http.get(Uri.parse('$baseUrl/job/posts'));
              if (postsRes.statusCode == 200) {
                // สามารถนำไปใช้ setState หรือแสดงผลได้
                print('Job posts: ${postsRes.body}');
              }
            } catch (_) {}
            Navigator.pushReplacementNamed(context, '/'); // กลับหน้า home
          }
        } else {
          // If server returns the specific SQL error about 'status' column, try a JSON fallback (without image)
          if (respStr.contains("Unknown column 'status'")) {
            // attempt fallback: send JSON body (no image) to same endpoint
            try {
              final jsonBody = {
                'user_id': idStr,
                'post_name': _title,
                'description': _description,
                'wage': _budget,
                // 'post_category_id': POST_CATEGORY_FIND
                'post_category_id': _selectedCategoryId! // ใช้ค่าที่เลือก
              };
              final jsonRes = await http.post(
                Uri.parse('$baseUrl/job/posts'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(jsonBody),
              );
              if (jsonRes.statusCode == 200 || jsonRes.statusCode == 201) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('โพสต์หางานสำเร็จ (fallback JSON)')));
                  Navigator.pushReplacementNamed(context, '/'); // กลับหน้า home
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('โพสต์ไม่สำเร็จ (fallback): ${jsonRes.body}')));
                }
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการส่ง fallback: $e')));
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('โพสต์ไม่สำเร็จ: $respStr')));
            }
          }
        }
      } else {
        final uri = Uri.parse('$baseUrl/job/posts');
        final body = {
          'user_id': idStr,
          'post_name': _title,
          'description': _description,
          'wage': _budget,
          'post_category_id': _selectedCategoryId!,
          'post_type': 'worker', // เพิ่ม post_type
        };
        final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
        if (res.statusCode == 200 || res.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('โพสต์หางานสำเร็จ (no image)')));
            // --- เรียก API /job/posts หลังโพสต์สำเร็จ ---
            try {
              final postsRes = await http.get(Uri.parse('$baseUrl/job/posts'));
              if (postsRes.statusCode == 200) {
                print('Job posts: ${postsRes.body}');
              }
            } catch (_) {}
            Navigator.pushReplacementNamed(context, '/'); // กลับหน้า home
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('โพสต์ไม่สำเร็จ (no image): ${res.body}')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/job/categories'));
      if (res.statusCode == 200) {
        final parsed = jsonDecode(res.body);
        List items = [];
        if (parsed is List) items = parsed;
        else if (parsed is Map && parsed['data'] is List) items = parsed['data'];
        final cats = items.map<Map<String, String>>((e) {
          if (e is Map) {
            final id = (e['category_id'] ?? e['id'] ?? e['value'])?.toString() ?? '';
            final name = (e['name'] ?? e['title'] ?? e['category_name'])?.toString() ?? id;
            return {'category_id': id, 'name': name};
          }
          final s = e.toString();
          return {'category_id': s, 'name': s};
        }).toList();
        if (mounted) setState(() => _categories = cats);
      }
    } catch (_) {
      // ignore errors silently; UI will show empty dropdown
    }
  }
}
