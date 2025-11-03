import 'package:flutter/material.dart';
import 'login.dart';
import 'posts_page.dart';
import 'user_account_page.dart';
import 'payment.dart';
import 'report_page.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

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
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const UserAccountPage()),
                          );
                        },
                        child: _HeaderMenuItem('บัญชีผู้ใช้'),
                      ),
                      const SizedBox(width: 32),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PaymentPage(origin: 'report')),
                          );
                        },
                        child: _HeaderMenuItem('ระบบการเงิน'),
                      ),
                      const SizedBox(width: 32),
                      GestureDetector(
                        onTap: () {},
                        child: _HeaderMenuItem('รายงานปัญหา'),
                      ),
                    ],
                  ),
                ),
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
          // Table
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                        color: Color(0xFFBFC8CF),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          _TableHeaderCell('รายชื่อผู้ใช้งาน', flex: 2),
                          _TableHeaderCell('รายงานระบบ', flex: 2),
                          _TableHeaderCell('', flex: 1),
                        ],
                      ),
                    ),
                    // Table rows
                    Expanded(
                      child: ListView.builder(
                        itemCount: 10,
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
                                // รายงานระบบ/รายงานผู้ใช้งาน
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      index % 2 == 0 ? 'รายงานระบบ' : 'รายงานผู้ใช้งาน',
                                      style: TextStyle(
                                        color: Color(0xFF22577A),
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                // ตรวจสอบข้อมูล button
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFFFFD600),
                                          foregroundColor: Color(0xFF22577A),
                                          elevation: 0,
                                          shape: StadiumBorder(),
                                          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                        ),
                                        onPressed: () {},
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
  const _HeaderMenuItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
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
