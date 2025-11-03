import 'package:flutter/material.dart';

class PostJobPage extends StatelessWidget {
  const PostJobPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
  // ignore: deprecated_member_use
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF22577A), size: 36),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: screenWidth * 0.9,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/postJobHire');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  elevation: 3,
                  shadowColor: Colors.black26,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  'โพสต์จ้างงาน',
                  style: TextStyle(
                    color: const Color(0xFF22577A),
                    fontSize: 20 * textScale,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'or',
              style: TextStyle(
                color: const Color(0xFF22577A),
                fontSize: 18 * textScale,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: screenWidth * 0.9,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/postJobFind');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  elevation: 3,
                  shadowColor: Colors.black26,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  'โพสต์หางาน',
                  style: TextStyle(
                    color: const Color(0xFF22577A),
                    fontSize: 20 * textScale,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
