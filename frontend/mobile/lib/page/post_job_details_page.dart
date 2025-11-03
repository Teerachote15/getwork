import 'package:flutter/material.dart';

class PostJobDetailsPage extends StatelessWidget {
  const PostJobDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
          'รายละเอียดที่ส่งมา',
          style: TextStyle(
            color: const Color(0xFF22577A),
            fontSize: 22 * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    'รูป',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16 * textScale,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ชื่อผู้โพสต์',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15 * textScale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'เบอร์: 000-000-0000',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13 * textScale,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'ทักแชท',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16 * textScale,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'ช่องทางการติดต่อ',
              style: TextStyle(
                color: const Color(0xFF22577A),
                fontWeight: FontWeight.bold,
                fontSize: 17 * textScale,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: screenHeight * 0.18,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Text(
                'email.......com\n000-000-0000',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16 * textScale,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: screenWidth * 0.08,
          right: screenWidth * 0.08,
          bottom: screenHeight * 0.04,
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/jobStatusFinish');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  elevation: 3,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'ตกลงเริ่มงาน',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * textScale,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  elevation: 3,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'ปฏิเสธงาน',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * textScale,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
