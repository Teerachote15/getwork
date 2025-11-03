import 'package:flutter/material.dart';

class JobCompletionPage extends StatelessWidget {
  const JobCompletionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
  // ignore: deprecated_member_use
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      appBar: AppBar(
        title: Text('ยืนยันการจบงาน', style: TextStyle(fontSize: 18 * textScale)),
        backgroundColor: const Color(0xFF3A5A99),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.95),
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenHeight * 0.015),
          child: Column(
            children: [
              Text(
                'สถานะของงาน',
                style: TextStyle(fontSize: 18 * textScale, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('กำลังทำงาน', style: TextStyle(fontSize: 15 * textScale)),
                  const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'ยืนยันการจบงาน',
                style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: screenHeight * 0.02),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('งานได้รับการยืนยันแล้ว!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(screenWidth * 0.7, screenHeight * 0.06),
                ),
                child: Text('ยืนยันการจบงาน', style: TextStyle(fontSize: 15 * textScale)),
              ),
              SizedBox(height: screenHeight * 0.02),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('คุณปฏิเสธงานนี้!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: Size(screenWidth * 0.7, screenHeight * 0.06),
                ),
                child: Text('ปฏิเสธงาน', style: TextStyle(fontSize: 15 * textScale)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
