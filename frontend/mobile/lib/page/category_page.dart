import 'package:flutter/material.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  // ฟังก์ชันตรวจสอบสถานะการล็อกอิน
  void _navigateToCategoryDetail(BuildContext context, String category) {
    _showCategoryDetail(context, category);
  }

  // ฟังก์ชันแสดงรายละเอียดหมวดหมู่ใน Dialog
  void _showCategoryDetail(BuildContext context, String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('รายละเอียด: $category'),
        content: Text('แสดงรายละเอียดของหมวดหมู่: $category'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("หมวดหมู่ทั้งหมด"),
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
          child: ListView(
            children: [
              // หมวดหมู่ เว็บไซต์
              ListTile(
                title: const Text("เว็บไซต์"),
                leading: const Icon(Icons.web),
                onTap: () {
                  _navigateToCategoryDetail(context, "เว็บไซต์");
                },
              ),
              
              // หมวดหมู่ ออกแบบกราฟิก
              ListTile(
                title: const Text("ออกแบบกราฟิก"),
                leading: const Icon(Icons.design_services),
                onTap: () {
                  _navigateToCategoryDetail(context, "ออกแบบกราฟิก");
                },
              ),
              
              // หมวดหมู่ ตัดต่อวิดีโอ
              ListTile(
                title: const Text("ตัดต่อวิดีโอ"),
                leading: const Icon(Icons.video_library),
                onTap: () {
                  _navigateToCategoryDetail(context, "ตัดต่อวิดีโอ");
                },
              ),
              
              // หมวดหมู่ ดูดวง
              ListTile(
                title: const Text("ดูดวง"),
                leading: const Icon(Icons.brightness_5),
                onTap: () {
                  _navigateToCategoryDetail(context, "ดูดวง");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
         
            