import 'package:flutter/material.dart';

class JobSubmissionPage extends StatefulWidget {
  const JobSubmissionPage({super.key});

  @override
  State<JobSubmissionPage> createState() => _JobSubmissionPageState();
}

class _JobSubmissionPageState extends State<JobSubmissionPage> {
  // ตัวแปรสำหรับ Slider
  double progress = 0.5;

  // ตัวแปรสำหรับการกรอกข้อมูล
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  // ฟังก์ชันสำหรับส่งงาน
  void _submitJob() {
    // ไม่มีการเปลี่ยนแปลงเพิ่มเติม
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ส่งงานสำเร็จ!')),
    );
  }

  // ฟังก์ชันสำหรับยกเลิก
  void _cancelJob() {
    // สามารถใช้คำสั่งนี้เพื่อยกเลิกการส่งงานหรือกลับไปหน้าก่อนหน้า
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดงาน'),
        backgroundColor: const Color(0xFF3A5A99),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Column(
            children: [
              // Text Field สำหรับกรอกรายละเอียด
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'ระบุรายละเอียดงานเพื่อส่งให้ฟรีแลนซ์',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Text Field สำหรับระบุช่องทางติดต่อ
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  hintText: 'วิธีการติดต่อ / ช่องทางติดต่อ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // แสดงสถานะการทำงาน
              const Text(
                'แสดงสถานะ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: progress,
                min: 0,
                max: 1,
                divisions: 10,
                onChanged: (value) {
                  setState(() {
                    progress = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // ตัวเลือกสำหรับการส่งงาน
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('สถานะของงาน'),
                  // เลือกปุ่มสถานะ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('กำลังทำงาน'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ช่องสำหรับแนบไฟล์หรือเพิ่มลิงก์
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {
                      // Handle attach file (เช่น การเลือกไฟล์จากเครื่อง)
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.link),
                    onPressed: () {
                      // Handle attach link (เชื่อมต่อกับลิงก์)
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cloud_upload),
                    onPressed: () {
                      // Handle upload (ฟังก์ชันการอัปโหลดไฟล์)
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ช่องแสดงความเห็น
              const TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'ความคิดเห็นเพิ่มเติม',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // ปุ่มส่งงาน
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _submitJob,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green), // ส่งงาน
                    child: const Text('ส่งงาน'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _cancelJob,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // ยกเลิก
                    child: const Text('ยกเลิก'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
