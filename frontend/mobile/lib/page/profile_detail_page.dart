import 'package:flutter/material.dart';

class ProfileDetailPage extends StatelessWidget {
  const ProfileDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
  // ignore: deprecated_member_use
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียด', style: TextStyle(fontSize: 18 * textScale)),
        backgroundColor: const Color(0xFF3A5A99),
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.all(screenWidth * 0.06),
            child: Text('รายละเอียดภายใน', style: TextStyle(fontSize: 16 * textScale)),
          ),
        ),
      ),
    );
  }
}

