import 'package:flutter/material.dart';

class NotificationDetailPage extends StatelessWidget {
  final String jobDetail;
  final String dueDate;
  final String fileLabel;
  final String contact;

  const NotificationDetailPage({
    super.key,
    this.jobDetail = 'รูปแบบงาน ประเภท ระบบ ที่ต้องการของผู้จ้างแบบละเอียด',
    this.dueDate = 'ว/ด/ป',
    this.fileLabel = 'ไฟล์',
    this.contact = 'email.......com\n000-000-0000',
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF22577A)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'รายละเอียดงานที่ส่งมา',
          style: TextStyle(
            color: const Color(0xFF22577A),
            fontWeight: FontWeight.bold,
            fontSize: 20 * textScale,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, thickness: 1, color: Color(0xFFBDBDBD)),
            const SizedBox(height: 18),
            Text(
              'รูปแบบงานที่ต้องการ',
              style: TextStyle(
                color: const Color(0xFF22577A),
                fontWeight: FontWeight.bold,
                fontSize: 16 * textScale,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                jobDetail,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 15 * textScale,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'ระยะเวลาที่ต้องเสร็จ(ว/ด/ป)',
              style: TextStyle(
                color: const Color(0xFF22577A),
                fontWeight: FontWeight.bold,
                fontSize: 16 * textScale,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Text(
                dueDate,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 15 * textScale,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'รูปแบบตัวอย่างงาน',
              style: TextStyle(
                color: const Color(0xFF22577A),
                fontWeight: FontWeight.bold,
                fontSize: 16 * textScale,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBDBDBD),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                fileLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * textScale,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'ช่องทางการติดต่อ',
              style: TextStyle(
                color: const Color(0xFF22577A),
                fontWeight: FontWeight.bold,
                fontSize: 16 * textScale,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                contact,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 15 * textScale,
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: screenWidth * 0.38,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/'); // เด้งไปหน้า main.dart (Home)
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009B4C),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'ตกลงเริ่มงาน',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: screenWidth * 0.38,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: ปฏิเสธงาน
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'ปฏิเสธงาน',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
