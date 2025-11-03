import 'package:flutter/material.dart';

class JobDetailsPage extends StatefulWidget {
  const JobDetailsPage({super.key});

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  String? submittedDescription;
  String? submittedContact;

  void submitJobDetails() {
    setState(() {
      submittedDescription = descriptionController.text;
      submittedContact = contactController.text;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ส่งงานสำเร็จ!')),
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
        title: Text('ระบุรายละเอียดงานเพื่อส่งให้ฟรีแลนซ์',
            style: TextStyle(fontSize: 18 * textScale, color: Colors.white)),
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'ระบุรายละเอียดงานเพื่อส่งให้ฟรีแลนซ์',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFE5E5E5),
                    contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.02, horizontal: screenWidth * 0.04),
                  ),
                  style: TextStyle(fontSize: 15 * textScale),
                ),
                SizedBox(height: screenHeight * 0.02),
                TextField(
                  controller: contactController,
                  decoration: InputDecoration(
                    hintText: 'วิธีการติดต่อ / ช่องทางติดต่อ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFE5E5E5),
                    contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.02, horizontal: screenWidth * 0.04),
                  ),
                  style: TextStyle(fontSize: 15 * textScale),
                ),
                SizedBox(height: screenHeight * 0.02),
                ElevatedButton.icon(
                  onPressed: submitJobDetails,
                  icon: Icon(Icons.send, color: Colors.white, size: screenWidth * 0.06),
                  label: Text('ส่งงาน', style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22577A),
                    minimumSize: Size(screenWidth * 0.5, screenHeight * 0.06),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                ),
                if (submittedDescription != null && submittedContact != null) ...[
                  SizedBox(height: screenHeight * 0.02),
                  Card(
                    color: const Color(0xFFF5F5F5),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('รายละเอียดที่ส่ง:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15 * textScale)),
                          const SizedBox(height: 4),
                          Text(submittedDescription ?? '', style: TextStyle(fontSize: 14 * textScale)),
                          const SizedBox(height: 8),
                          Text('ช่องทางติดต่อ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15 * textScale)),
                          const SizedBox(height: 4),
                          Text(submittedContact ?? '', style: TextStyle(fontSize: 14 * textScale)),
                        ],
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
