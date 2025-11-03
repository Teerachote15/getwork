import 'package:flutter/material.dart';

class ReportIssuePage extends StatefulWidget {
  final String? userid;
  final String? username;
  const ReportIssuePage({super.key, this.userid, this.username});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  bool _systemProblem = false;
  bool _userProblem = false;
  final TextEditingController _controller = TextEditingController();

  void _submitReport() {
    final text = _controller.text.trim();
    if (!_systemProblem && !_userProblem && text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาระบุประเภทปัญหาหรือรายละเอียด')));
      return;
    }

    // TODO: send report to backend including widget.userid / widget.username
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ส่งรายงานเรียบร้อย')));
  if (!mounted) return;
  Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
  // ignore: deprecated_member_use
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;
    return Scaffold(
      appBar: AppBar(
        title: Text('รายงานปัญหา', style: TextStyle(fontSize: 18 * textScale)),
        backgroundColor: const Color(0xFF3A5A99),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          children: [
            CheckboxListTile(
              value: _systemProblem,
              onChanged: (v) => setState(() => _systemProblem = v ?? false),
              title: const Text('ปัญหาระบบ', style: TextStyle(fontSize: 16)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _userProblem,
              onChanged: (v) => setState(() => _userProblem = v ?? false),
              title: const Text('ปัญหาผู้ใช้', style: TextStyle(fontSize: 16)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'กรอกข้อมูลปัญหา',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF255E78), // dark-teal background
                  foregroundColor: Colors.white, // white text
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2, // slight elevation to match image
                ),
                child: const Text('รายงาน', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
