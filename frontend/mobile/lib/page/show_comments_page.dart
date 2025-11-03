import 'package:flutter/material.dart';

class ShowCommentsPage extends StatefulWidget {
  const ShowCommentsPage({super.key});

  @override
  State<ShowCommentsPage> createState() => _ShowCommentsPageState();
}

class _ShowCommentsPageState extends State<ShowCommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  final List<String> _comments = [];

  void _sendComment() {
    final comment = _commentController.text;
    if (comment.isNotEmpty) {
      setState(() {
        _comments.add(comment);
      });
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      appBar: AppBar(
        title: Text('แสดงความคิดเห็น', style: TextStyle(fontSize: 18 * textScale, color: Colors.white)),
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
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF3A5A99),
                          child: Text('U${index + 1}', style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text('ชื่อผู้โพสต์ $index', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15 * textScale)),
                        subtitle: Text(_comments[index], style: TextStyle(fontSize: 14 * textScale)),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'ส่งข้อความ...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: const Icon(Icons.send, color: Color(0xFF3A5A99)),
                  filled: true,
                  fillColor: const Color(0xFFE5E5E5),
                  contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.02, horizontal: screenWidth * 0.04),
                ),
                style: TextStyle(fontSize: 15 * textScale),
                onSubmitted: (_) => _sendComment(),
              ),
              SizedBox(height: screenHeight * 0.01),
              ElevatedButton.icon(
                onPressed: _sendComment,
                icon: Icon(Icons.send, color: Colors.white, size: screenWidth * 0.05),
                label: Text('ส่งความคิดเห็น', style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22577A),
                  minimumSize: Size(screenWidth * 0.5, screenHeight * 0.06),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
