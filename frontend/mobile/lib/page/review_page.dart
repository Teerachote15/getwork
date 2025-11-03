import 'package:flutter/material.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({Key? key}) : super(key: key);

  Widget _buildReviewCard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar / small icon
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFdff0ff),
              child: Text('รูป', style: TextStyle(color: Colors.black54)),
            ),
            const SizedBox(width: 10),
            // Left image preview
            Container(
              width: screenWidth * 0.33,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),
            // Middle: title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ชื่อเจ้าของงาน',
                    style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'รายละเอียดงานย่อๆ แสดงข้อความสั้น ๆ เพื่อให้ผู้ใช้เห็นข้อมูลคร่าว ๆ ของโพสต์',
                    style: TextStyle(fontSize: 13 * textScale, color: Colors.black54),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Right column: price and delete icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.black54),
                  onPressed: () {
                    // เพิ่ม action ลบตามต้องการ
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('ลบโพสต์'),
                        content: const Text('คุณต้องการลบโพสต์นี้หรือไม่?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('ยกเลิก')),
                          TextButton(onPressed: () {
                            Navigator.of(ctx).pop();
                            // ลบ action เพิ่มที่นี่
                          }, child: const Text('ลบ')),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text('ราคา', style: TextStyle(fontSize: 12 * textScale, color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaleFactor;
    return Scaffold(
      appBar: AppBar(
        title: Text('รีวิว', style: TextStyle(fontSize: 18 * textScale)),
        backgroundColor: const Color(0xFF2E628A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 16),
          children: [
            // ตัวอย่างหัวข้อ/แถบแบ่ง
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('รีวิวจากผู้ใช้', style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.w600)),
            ),
            // ตัวอย่างการ์ดหลายรายการ
            ...List.generate(6, (_) => _buildReviewCard(context)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
