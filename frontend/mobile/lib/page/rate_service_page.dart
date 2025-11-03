import 'package:flutter/material.dart';

class RateServicePage extends StatefulWidget {
  const RateServicePage({super.key});

  @override
  State<RateServicePage> createState() => _RateServicePageState();
}

class _RateServicePageState extends State<RateServicePage> {
  double rating = 3.0;
  final TextEditingController _feedbackController = TextEditingController();

  void _submitRating() {
    String feedback = _feedbackController.text;

    if (rating == 0.0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกคะแนนก่อนส่ง')),
      );
      return;
    }

    if (feedback.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกความคิดเห็นก่อนส่ง')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('คะแนน: $rating\nความคิดเห็น: $feedback')),
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
      appBar: AppBar(
        title: Text('ให้คะแนนการบริการ', style: TextStyle(fontSize: 18 * textScale, color: Colors.white)),
        backgroundColor: const Color(0xFF3A5A99),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: screenWidth * 0.06),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 2,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.95),
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.02),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'คุณพอใจกับการบริการแอปนี้หรือไม่',
                style: TextStyle(fontSize: 18 * textScale, fontWeight: FontWeight.bold, color: const Color(0xFF22577A)),
              ),
              SizedBox(height: screenHeight * 0.02),
              Slider(
                value: rating,
                min: 0,
                max: 5,
                divisions: 5,
                label: rating.toStringAsFixed(1),
                activeColor: Colors.amber,
                inactiveColor: Colors.grey[300],
                onChanged: (newRating) {
                  setState(() {
                    rating = newRating;
                  });
                },
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'กรุณาแสดงความคิดเห็น',
                style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold, color: const Color(0xFF22577A)),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextField(
                controller: _feedbackController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'รายงานปัญหา... (ถ้ามี)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFFE5E5E5),
                  contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.02, horizontal: screenWidth * 0.04),
                ),
                style: TextStyle(fontSize: 15 * textScale),
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close, color: Colors.white, size: screenWidth * 0.05),
                    label: Text('ปิด', style: TextStyle(fontSize: 15 * textScale)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      minimumSize: Size(screenWidth * 0.3, screenHeight * 0.06),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _submitRating,
                    icon: Icon(Icons.send, color: Colors.white, size: screenWidth * 0.05),
                    label: Text('ส่ง', style: TextStyle(fontSize: 15 * textScale, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: Size(screenWidth * 0.3, screenHeight * 0.06),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
