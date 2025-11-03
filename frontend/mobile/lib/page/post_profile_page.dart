import 'package:flutter/material.dart';

class PostProfilePage extends StatelessWidget {
  const PostProfilePage({super.key});

  Widget _buildPostCard(BuildContext context, int index, double textScale, double screenWidth, Color blue) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // header row of card: icon, title, delete
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue[50],
                  child: Text('รูป', style: TextStyle(fontSize: 11 * textScale, color: blue)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ชื่อเจ้าของร้าน',
                    style: TextStyle(fontSize: 14 * textScale, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    // delete action placeholder
                  },
                ),
              ],
            ),

            const SizedBox(height: 8),

            // content row: image placeholder + details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: screenWidth * 0.28,
                  height: screenWidth * 0.18,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('รายละเอียดงาน', style: TextStyle(fontSize: 13 * textScale, color: Colors.black87)),
                      const SizedBox(height: 6),
                      Text(
                        'รายละเอียดสั้นๆ ของงานตัวอย่างที่แสดงในการ์ด',
                        style: TextStyle(fontSize: 12 * textScale, color: Colors.black54),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text('ราคา', style: TextStyle(fontSize: 13 * textScale, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
  // ignore: deprecated_member_use
  // ignore: deprecated_member_use
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;
    const blue = Color(0xFF2E628A);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              // Header: back icon, avatar (clickable), title centered
              Container(
                color: blue,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                height: 110,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/profileEducation');
                      },
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        child: Text('รูป', style: TextStyle(color: blue, fontSize: 12 * textScale)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ชื่อผู้ใช้',
                        textAlign: TextAlign.left,
                        style: TextStyle(color: Colors.white, fontSize: 18 * textScale, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              // TabBar
              const Material(
                color: Colors.white,
                elevation: 2,
                child: TabBar(
                  labelColor: blue,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: blue,
                  tabs: [
                    Tab(text: 'รายละเอียด'),
                    Tab(text: 'สิ่งที่โพส'),
                    Tab(text: 'รีวิว'),
                  ],
                ),
              ),

              // Tab views
              Expanded(
                child: TabBarView(
                  children: [
                    // รายละเอียด (placeholder)
                    SingleChildScrollView(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ข้อมูลโปรไฟล์', style: TextStyle(fontSize: 16 * textScale, fontWeight: FontWeight.w600, color: blue)),
                          const SizedBox(height: 10),
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('รายละเอียดโปรไฟล์และข้อมูลเพิ่มเติม...'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // สิ่งที่โพส (list of cards)
                    const PostListContent(),

                    // รีวิว (placeholder)
                    const Center(child: Text('รีวิว', style: TextStyle(color: Colors.black54))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// เพิ่ม widget แบบฝังที่แสดงรายการ "สิ่งที่โพส" (ใช้ได้ทั้งเป็นหน้าแยกหรือฝังใน Tab)
class PostListContent extends StatelessWidget {
  const PostListContent({super.key});

  Widget _buildPostCard(BuildContext context, int index, double textScale, double screenWidth, Color blue) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue[50],
                  child: Text('รูป', style: TextStyle(fontSize: 11 * textScale, color: blue)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ชื่อเจ้าของร้าน',
                    style: TextStyle(fontSize: 14 * textScale, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    // delete action placeholder
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: screenWidth * 0.28,
                  height: screenWidth * 0.18,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('รายละเอียดงาน', style: TextStyle(fontSize: 13 * textScale, color: Colors.black87)),
                      const SizedBox(height: 6),
                      Text(
                        'รายละเอียดสั้นๆ ของงานตัวอย่างที่แสดงในการ์ด',
                        style: TextStyle(fontSize: 12 * textScale, color: Colors.black54),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text('ราคา', style: TextStyle(fontSize: 13 * textScale, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;
    const blue = Color(0xFF2E628A);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: 6,
      itemBuilder: (context, index) => _buildPostCard(context, index, textScale, screenWidth, blue),
    );
  }
}
