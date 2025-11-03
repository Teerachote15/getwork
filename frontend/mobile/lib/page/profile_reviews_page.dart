import 'package:flutter/material.dart';

class ProfileReviewsPage extends StatelessWidget {
  const ProfileReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      appBar: AppBar(
        title: Text('รีวิว', style: TextStyle(fontSize: 18 * textScale)),
        backgroundColor: const Color(0xFF3A5A99),
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: ListView(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Row(
                  children: [
                    Container(
                      width: screenWidth * 0.13,
                      height: screenWidth * 0.13,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Text('รูป')),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ชื่อผู้ว่าจ้าง', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15 * textScale)),
                          const SizedBox(height: 4),
                          Text('วันที่/ปี', style: TextStyle(fontSize: 14 * textScale)),
                        ],
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20 * textScale),
                        const SizedBox(width: 2),
                        Text('5.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 * textScale)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Row(
                  children: [
                    Container(
                      width: screenWidth * 0.13,
                      height: screenWidth * 0.13,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(child: Text('รูป')),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ชื่อผู้ว่าจ้าง', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15 * textScale)),
                          const SizedBox(height: 4),
                          Text('วันที่/ปี', style: TextStyle(fontSize: 14 * textScale)),
                        ],
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20 * textScale),
                        const SizedBox(width: 2),
                        Text('5.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14 * textScale)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
