import 'package:flutter/material.dart';
import 'utility_style.dart';  // สมมุติว่า UtilityStyle อยู่ในไฟล์ utility_style.dart

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // ignore: deprecated_member_use
    final textScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      appBar: AppBar(title: Text('หน้าหลัก', style: TextStyle(fontSize: 18 * textScale))),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            TextField(
              decoration: UtilityStyle.searchInputDecoration(),
              style: TextStyle(fontSize: 14 * textScale),
            ),
            SizedBox(height: screenHeight * 0.02),
            ElevatedButton(
              style: UtilityStyle.primaryButton(),
              onPressed: () {
                // ฟังก์ชันการกดปุ่ม
              },
              child: Text('ค้นหาบริการ', style: TextStyle(fontSize: 15 * textScale)),
            ),
          ],
        ),
      ),
    );
  }
}
