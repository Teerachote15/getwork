import 'package:flutter/material.dart';

class ProfileExperiencePage extends StatelessWidget {
  const ProfileExperiencePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
  // ignore: deprecated_member_use
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      appBar: AppBar(
        title: Text('ประสบการณ์การทำงาน', style: TextStyle(fontSize: 18 * textScale)),
        backgroundColor: const Color(0xFF3A5A99),
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.all(screenWidth * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('หัวข้อ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16 * textScale)),
                Text('หัวข้อย่อย', style: TextStyle(fontSize: 15 * textScale)),
                const SizedBox(height: 8),
                Text('หัวข้อ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16 * textScale)),
                Text('หัวข้อย่อย', style: TextStyle(fontSize: 15 * textScale)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
