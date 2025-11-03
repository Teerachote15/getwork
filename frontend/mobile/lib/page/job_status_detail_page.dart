import 'package:flutter/material.dart';

class JobStatusDetailPage extends StatelessWidget {
  const JobStatusDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดสถานะงาน', style: TextStyle(fontSize: 18 * textScale)),
        backgroundColor: const Color(0xFF3A5A99),
      ),
      body: Center(
        child: Text(
          'รายละเอียดสถานะงาน',
          style: TextStyle(fontSize: 20 * textScale, color: Colors.black),
        ),
      ),
    );
  }
}
