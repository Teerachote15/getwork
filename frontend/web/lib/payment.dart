import 'package:flutter/material.dart';
import 'login.dart';
import 'posts_page.dart';
import 'user_account_page.dart';
import 'examine_data_page.dart';
import 'report_page.dart';

class PaymentPage extends StatelessWidget {
  final String origin; // 'login', 'posts', 'user_account', 'examine'
  const PaymentPage({super.key, required this.origin});

  @override
  Widget build(BuildContext context) {
    // ตัวอย่างข้อมูล
    final List<Map<String, dynamic>> payments = [
      {'type': 'ฝาก', 'amount': 500},
      {'type': 'ถอน', 'amount': 500},
      {'type': 'ฝาก', 'amount': 500},
      {'type': 'ถอน', 'amount': 500},
      {'type': 'ฝาก', 'amount': 500},
      {'type': 'ฝาก', 'amount': 500},
      {'type': 'ถอน', 'amount': 500},
      {'type': 'ฝาก', 'amount': 500},
      {'type': 'ถอน', 'amount': 500},
    ];

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
                            MaterialPageRoute(builder: (_) => const PaymentPage(origin: 'payment')),
                          );
                        },
                        child: _HeaderMenuItem('ระบบการเงิน', selected: true),
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
                // Back button
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
            'ระบบการเงิน',
            style: TextStyle(
              color: Color(0xFF22577A),
              fontSize: 32,
              fontWeight: FontWeight.bold,
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
                          _TableHeaderCell('ฝาก/ถอน', flex: 2),
                          _TableHeaderCell('จำนวนเงิน', flex: 2),
                        ],
                      ),
                    ),
                    // Table rows
                    Expanded(
                      child: ListView.builder(
                        itemCount: payments.length,
                        itemBuilder: (context, index) {
                          final payment = payments[index];
                          final isDeposit = payment['type'] == 'ฝาก';
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
                                // ฝาก/ถอน
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      payment['type'],
                                      style: TextStyle(
                                        color: isDeposit ? Colors.green : Colors.red,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                // จำนวนเงิน
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Text(
                                      payment['amount'].toString(),
                                      style: TextStyle(
                                        color: isDeposit ? Colors.green : Colors.red,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
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
