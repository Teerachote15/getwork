import 'package:flutter/material.dart';

class JobStatusShowPage extends StatelessWidget {
  const JobStatusShowPage({super.key});

  Widget _buildStepBar(List<String> steps, int activeIndex) {
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i <= activeIndex;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.black : Colors.grey[400],
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
              const SizedBox(height: 4),
              Text(
                steps[i],
                style: const TextStyle(fontSize: 10, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF22577A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'แสดงสถานะ',
          style: TextStyle(
            color: const Color(0xFF22577A),
            fontWeight: FontWeight.bold,
            fontSize: 22 * textScale,
          ),
        ),
        centerTitle: false,
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
                  1,
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
                  2,
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
                  'ส่งงาน',
                  style: TextStyle(
                    color: const Color(0xFF22577A),
                    fontWeight: FontWeight.bold,
                    fontSize: 18 * textScale,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SendButton(label: 'Attach', icon: Icons.attach_file, onPressed: () {}),
                    const SizedBox(width: 8),
                    _SendButton(label: 'Link', icon: Icons.link, onPressed: () {}),
                    const SizedBox(width: 8),
                    _SendButton(label: 'Upload', icon: Icons.cloud_upload, onPressed: () {}),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22577A),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'ส่ง',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16 * textScale,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: Container()),
          Container(
            width: double.infinity,
            color: Colors.grey[200],
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 18),
            child: RichText(
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
                        'ฟรีแลนซ์จะได้ค่าจ้างก็ต่อเมื่อผู้ว่าจ้างยืนยันการจบงานเรียบร้อยแล้ว สามารถสังเกตได้จากสถานะด้านบน',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 15 * textScale,
                    ),
                  ),
                ],
              ),
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

class _SendButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  const _SendButton({required this.label, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[500],
        minimumSize: const Size(80, 36),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
    );
  }
}
