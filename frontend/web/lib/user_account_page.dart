import 'package:flutter/material.dart';
import 'posts_page.dart';
import 'login.dart';
import 'payment.dart';
import 'report_page.dart';
import 'examine_profile_page.dart'; // เพิ่มการ import

class UserAccountPage extends StatelessWidget {
  const UserAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header bar
          Container(
            color: Color(0xFF22577A),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logogetwork.png',
                  width: 60,
                  height: 60,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PostsPage()),
                          );
                        },
                        child: _HeaderMenuItem('โพสรออนุมัติ'),
                      ),
                      const SizedBox(width: 32),
                      GestureDetector(
                        onTap: () {},
                        child: _HeaderMenuItem('บัญชีผู้ใช้', selected: true),
                      ),
                      const SizedBox(width: 32),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PaymentPage(origin: 'user_account')),
                          );
                        },
                        child: _HeaderMenuItem('ระบบการเงิน'),
                      ),
                      const SizedBox(width: 32),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ReportPage()),
                          );
                        },
                        child: _HeaderMenuItem('รายงานปัญหา'),
                      ),
                    ],
                  ),
                ),
                // Back to login button
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    'เข้าสู่ระบบ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            'บัญชีผู้ใช้',
            style: TextStyle(
              color: Color(0xFF22577A),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหารายชื่อ',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Color(0xFF22577A)),
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Table header
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          _TableHeaderCell('รายชื่อผู้ใช้งาน', flex: 2),
                          _TableHeaderCell('ข้อมูลบัญชี', flex: 2),
                          _TableHeaderCell('ระงับบัญชี', flex: 2),
                        ],
                      ),
                    ),
                    // Table rows
                    Expanded(
                      child: ListView.builder(
                        itemCount: 8,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Row(
                              children: [
                                // User profile
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: Colors.grey[300],
                                          child: Icon(Icons.person, color: Colors.grey[500], size: 32),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'ชื่อผู้ใช้งาน',
                                          style: TextStyle(
                                            color: Color(0xFF3A5A99),
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // ข้อมูลบัญชี (เฉพาะปุ่ม ตรวจสอบข้อมูล ตรงกลาง)
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFFFD600),
                                        foregroundColor: Color(0xFF22577A),
                                        elevation: 0,
                                        shape: StadiumBorder(),
                                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => const ExamineDataPage()),
                                        );
                                      },
                                      child: Text(
                                        'ตรวจสอบข้อมูล',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // ระงับบัญชี (เฉพาะปุ่ม ระงับบัญชี ตรงกลาง)
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: StadiumBorder(),
                                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                      ),
                                      onPressed: () {},
                                      child: Text(
                                        'ระงับบัญชี',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMenuItem extends StatelessWidget {
  final String text;
  final bool selected;
  const _HeaderMenuItem(this.text, {this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (selected)
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 4,
            width: 60,
            color: Colors.white,
          ),
      ],
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _TableHeaderCell(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text(
          text,
          style: TextStyle(
            color: Color(0xFF3A5A99),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
