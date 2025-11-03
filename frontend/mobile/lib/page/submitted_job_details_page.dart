import 'package:flutter/material.dart';

class SubmittedJobDetailsPage extends StatefulWidget {
  const SubmittedJobDetailsPage({super.key});

  @override
  State<SubmittedJobDetailsPage> createState() => _SubmittedJobDetailsPageState();
}

class _SubmittedJobDetailsPageState extends State<SubmittedJobDetailsPage> {
  Map<String, dynamic> jobDetails = {
    'description': 'งานออกแบบโลโก้บริษัท',
    'status': 'กำลังดำเนินการ',
    'id': '123',
  };

  bool isLoading = false;

  void updateJobStatus(String status) {
    setState(() {
      jobDetails['status'] = status;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('สถานะงานอัปเดตเป็น "${status}"')),
    );
  }

  void fetchJobDetails() async {
    setState(() {
      isLoading = true;
    });
    // จำลองโหลดข้อมูล
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchJobDetails();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
  // ignore: deprecated_member_use
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดงานที่ส่งมา', style: TextStyle(fontSize: 18 * textScale, color: Colors.white)),
        backgroundColor: const Color(0xFF3A5A99),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: screenWidth * 0.06),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'รายละเอียดงาน: ${jobDetails['description']}',
                style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'สถานะ: ${jobDetails['status']}',
                style: TextStyle(fontSize: 16 * textScale, color: const Color(0xFF22577A)),
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => updateJobStatus('เสร็จสิ้น'),
                      icon: Icon(Icons.check_circle, color: Colors.white, size: screenWidth * 0.05),
                      label: Text('อัปเดตสถานะเป็นเสร็จสิ้น', style: TextStyle(fontSize: 15 * textScale)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: Size(screenWidth * 0.4, screenHeight * 0.06),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => updateJobStatus('กำลังดำเนินการ'),
                      icon: Icon(Icons.autorenew, color: Colors.white, size: screenWidth * 0.05),
                      label: Text('อัปเดตสถานะเป็นกำลังดำเนินการ', style: TextStyle(fontSize: 15 * textScale)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: Size(screenWidth * 0.4, screenHeight * 0.06),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
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

