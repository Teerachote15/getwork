import 'package:flutter/material.dart';

class JobStatusFinishPage extends StatelessWidget {
  const JobStatusFinishPage({super.key});

  Widget _buildStepBar(List<String> steps, int activeIndex) {
    return Row(
      children: List.generate(steps.length, (i) {
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: i <= activeIndex ? Colors.black : Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (i < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 4,
                        color: Colors.grey[400],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                steps[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
  // ignore: deprecated_member_use
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
          'แสดงสถานะ',
          style: TextStyle(
            color: const Color(0xFF22577A),
            fontSize: 22 * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.grey[200],
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สถานะของงาน',
                  style: TextStyle(
                    color: const Color(0xFF22577A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * textScale,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStepBar(
                  [
                    'ได้รับรายละเอียดงาน',
                    'กำลังดำเนินงาน',
                    'ฟรีแลนซ์ส่งงานแล้ว',
                    'รอผู้ว่าจ้างตรวจสอบงานและยืนยัน',
                    'งานเสร็จสิ้น',
                  ],
                  1, // active index (กำลังดำเนินงาน)
                ),
                const SizedBox(height: 18),
                Text(
                  'การชำระเงิน',
                  style: TextStyle(
                    color: const Color(0xFF22577A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * textScale,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStepBar(
                  [
                    'ผู้ว่าจ้างชำระเงิน',
                    'ระบบตรวจสอบ',
                    'ค่าใช้จ่ายถูกส่งไปที่ช่องกำลังดำเนินงาน',
                    'รอผู้ว่าจ้างตรวจสอบงานและยืนยัน',
                    'เงินโอนให้ฟรีแลนซ์',
                  ],
                  2, // active index (ค่าใช้จ่ายถูกส่งไปที่ช่องกำลังดำเนินงาน)
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            color: Colors.grey[200],
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ตรวจงาน',
                  style: TextStyle(
                    color: const Color(0xFF22577A),
                    fontWeight: FontWeight.bold,
                    fontSize: 18 * textScale,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 16),
                      Icon(Icons.attach_file, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: Container()),
          Container(
            width: double.infinity,
            color: Colors.grey[200],
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ยืนยันการส่งงาน',
                  style: TextStyle(
                    color: const Color(0xFF22577A),
                    fontWeight: FontWeight.bold,
                    fontSize: 17 * textScale,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'โปรดอ่าน ',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 15 * textScale,
                        ),
                      ),
                      TextSpan(
                        text:
                            'ก่อนที่ฟรีแลนซ์และผู้ว่าจ้างจะกดยืนยันต้องรอให้ผู้ว่าจ้างได้ตรวจงานให้เสร็จเรียบร้อยก่อนกดยืนยัน เพราะหลังจากกดยืนยันจะไม่สามารถแก้ไขได้แล้ว',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 15 * textScale,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/review');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22577A),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'ยืนยันการจบงาน',
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
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF3A5A99),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
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
      ),
    );
  }
}
