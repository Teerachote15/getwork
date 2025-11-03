import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class SendDetailsFreelancePage extends StatefulWidget {
  final int postId;
  final int employerId;

  const SendDetailsFreelancePage({
    super.key,
    required this.postId,
    required this.employerId,
  });

  @override
  State<SendDetailsFreelancePage> createState() => _SendDetailsFreelancePageState();
}

class _SendDetailsFreelancePageState extends State<SendDetailsFreelancePage> {
  final _formKey = GlobalKey<FormState>();
  final _workDescController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _contactController = TextEditingController();

  DateTime? _selectedDeadline; // added to store picked date

  File? _pickedImage;
  bool _loading = false;

  // Resolve backend base similar to other pages. Can be overridden with
  // --dart-define=API_BASE=http://... when running.
  static String _detectApiBase() {
    const env = String.fromEnvironment('API_BASE', defaultValue: '');
    if (env.isNotEmpty) return env;
    if (kIsWeb) return 'http://localhost:4000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:4000';
      default:
        return 'http://localhost:4000';
    }
  }
  // amount is defined on the post/service page; do not collect it here.

  Future<void> _pickImage() async {
    try {
      final p = ImagePicker();
      final XFile? f = await p.pickImage(source: ImageSource.gallery, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
      if (f != null) {
        setState(() => _pickedImage = File(f.path));
      }
    } catch (e) {
      // ignore errors, show snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ไม่สามารถเลือกภาพได้: $e')));
    }
  }

  // helper to format date as dd/MM/yyyy
  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      // locale and other params can be added if needed
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
        _deadlineController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
  final backendBase = _detectApiBase();
  final uri = Uri.parse('$backendBase/job/send_details');
  final request = http.MultipartRequest('POST', uri);

      // required fields
      // Validate IDs are present. If not, show clear error to developer/user.
      if (widget.postId <= 0 || widget.employerId <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ข้อมูลโพสต์หรือผู้ว่าจ้างไม่ถูกต้อง (postId/employerId)')));
        setState(() => _loading = false);
        return;
      }

      // Always send both snake_case and camelCase to be tolerant with backend variants
      request.fields['post_id'] = widget.postId.toString();
      request.fields['postId'] = widget.postId.toString();
      request.fields['employer_id'] = widget.employerId.toString();
      request.fields['employerId'] = widget.employerId.toString();
      request.fields['detail'] = _workDescController.text.trim();
      request.fields['description'] = _workDescController.text.trim();

      // Normalize deadline: prefer ISO YYYY-MM-DD so backend Date parsing works reliably
      String deadlineToSend = '';
      if (_selectedDeadline != null) {
        final d = _selectedDeadline!;
        deadlineToSend = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      } else if (_deadlineController.text.trim().isNotEmpty) {
        // try parse dd/MM/yyyy (common in UI) into ISO
        final raw = _deadlineController.text.trim();
        final parts = raw.split('/');
        if (parts.length == 3) {
          final dd = int.tryParse(parts[0]);
          final mm = int.tryParse(parts[1]);
          final yyyy = int.tryParse(parts[2]);
          if (dd != null && mm != null && yyyy != null) {
            deadlineToSend = '${yyyy.toString().padLeft(4, '0')}-${mm.toString().padLeft(2, '0')}-${dd.toString().padLeft(2, '0')}';
          } else {
            // fallback to raw string
            deadlineToSend = raw;
          }
        } else {
          deadlineToSend = raw;
        }
      }

      if (deadlineToSend.isNotEmpty) {
        request.fields['deadline'] = deadlineToSend;
        request.fields['deadline_iso'] = deadlineToSend;
      }

      request.fields['contact'] = _contactController.text.trim();
      request.fields['contact_info'] = _contactController.text.trim();

      // Amount is taken from the post/service and not collected on this page.

      // Attach image if picked
      if (_pickedImage != null && await _pickedImage!.exists()) {
        final fileName = _pickedImage!.path.split(Platform.pathSeparator).last;
        request.files.add(await http.MultipartFile.fromPath('image', _pickedImage!.path, filename: fileName));
      }

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      final code = resp.statusCode;
      final body = resp.body.isNotEmpty ? resp.body : '{}';
      dynamic json;
      try { json = jsonDecode(body); } catch (_) { json = {'raw': body}; }

      if (code >= 200 && code < 300) {
        // success
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ส่งรายละเอียดเรียบร้อย')));
        // optionally navigate back or to a confirmation page
        Navigator.pop(context, {'ok': true, 'response': json});
      } else {
        final msg = (json is Map && (json['error'] ?? json['message']) != null) ? (json['error'] ?? json['message']) : 'Server error';
        if (code == 402 || (msg is String && msg.toString().toLowerCase().contains('insufficient'))) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ยอดเงินไม่เพียงพอ กรุณาตรวจสอบยอดคงเหลือ')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $msg (code $code)')));
        }
      }
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $err')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
  // ignore: deprecated_member_use
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
          'ระบุรายละเอียดงานเพื่อส่งให้ฟรีแลนซ์',
          style: TextStyle(
            color: const Color(0xFF22577A),
            fontSize: 20 * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'รูปแบบงานที่คุณต้องการ',
                  style: TextStyle(
                    color: const Color(0xFF22577A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * textScale,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _workDescController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'เขียนบรีฟให้ฟรีแลนซ์เข้าใจ เช่น งานเกี่ยวกับอะไร,\nอยากให้หน้าตาเป็นแบบไหน, มีตัวอย่างไหม, ต้องการอะไรพิเศษบ้าง?',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  ),
                  style: TextStyle(fontSize: 15 * textScale),
                  validator: (value) => value!.isEmpty ? 'กรุณากรอกรายละเอียดงาน' : null,
                ),
                const SizedBox(height: 24),
                Text(
                  'ระยะเวลาที่ต้องการให้เสร็จ (ว/ด/ป)',
                  style: TextStyle(
                    color: const Color(0xFF22577A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * textScale,
                  ),
                ),
                const SizedBox(height: 8),
                // deadline field -> open calendar picker
                TextFormField(
                  controller: _deadlineController,
                  readOnly: true,
                  onTap: _pickDeadline,
                  decoration: InputDecoration(
                    hintText: 'แตะเพื่อเลือกวันที่ (ว/ด/ป)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF22577A)),
                  ),
                  style: TextStyle(fontSize: 15 * textScale),
                  validator: (value) => value!.isEmpty ? 'กรุณาระบุวันเวลา' : null,
                ),
                const SizedBox(height: 24),
                Text(
                  'ตัวอย่างงาน (ถ้ามี)',
                  style: TextStyle(
                    color: const Color(0xFF22577A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * textScale,
                  ),
                ),
                const SizedBox(height: 8),
                // Updated upload button -> pick image and preview
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _pickedImage == null ? 'อัพโหลดรูป' : 'เปลี่ยนรูป',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16 * textScale,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_pickedImage != null)
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[100]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_pickedImage!, fit: BoxFit.cover),
                        ),
                      ),
                  ],
                ),
                // Amount removed: price is defined on the post/service page
                Text(
                  'วิธีการสื่อสาร / ช่องทางติดต่อ',
                  style: TextStyle(
                    color: const Color(0xFF22577A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * textScale,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contactController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'บอกช่องทางการติดต่อเพื่อให้ฟรีแลนซ์ (จะเป็น email หรือเบอร์)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  ),
                  style: TextStyle(fontSize: 15 * textScale),
                  validator: (value) => value!.isEmpty ? 'กรุณาระบุช่องทางติดต่อ' : null,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue[300],
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            'ส่งรายละเอียดและชำระเงิน',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18 * textScale,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'หากฟรีแลนซ์ได้รับรายละเอียดงานและปฏิเสธ เงินที่ท่านชำระระบบจะส่งเงินคืนให้',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13 * textScale,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
