import 'package:flutter/material.dart';

class ReviewProfilePage extends StatelessWidget {
  const ReviewProfilePage({super.key});

  Widget _reviewCard(BuildContext context, String name, String date, double rating) {
  // ignore: deprecated_member_use
  final textScale = MediaQuery.of(context).textScaleFactor;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // small avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFdff4fb),
              child: Text('รูป', style: TextStyle(color: const Color(0xFF2E628A), fontSize: 11 * textScale)),
            ),
            const SizedBox(width: 12),
            // name + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 14 * textScale, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(date, style: TextStyle(fontSize: 12 * textScale, color: Colors.black45)),
                ],
              ),
            ),
            // rating
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: 13 * textScale, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2E628A);
    final screenWidth = MediaQuery.of(context).size.width;
    final textScale = MediaQuery.of(context).textScaleFactor;

    // ตัวอย่างข้อมูลรีวิว (เปลี่ยนเป็นข้อมูลจริงตามต้องการ)
    final reviews = [
      {'name': 'ชื่อผู้ว่าจ้าง', 'date': 'ง/ค/ป', 'rating': 5.0},
      {'name': 'ชื่อผู้ว่าจ้าง', 'date': 'ง/ค/ป', 'rating': 5.0},
    ];

    return DefaultTabController(
      length: 3,
      initialIndex: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          child: Column(
            children: [
              // header: back, avatar, username
              Container(
                color: blue,
                height: 110,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Text('รูป', style: TextStyle(color: blue, fontSize: 12 * textScale)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ชื่อผู้ใช้',
                        style: TextStyle(color: Colors.white, fontSize: 20 * textScale, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
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

              // TabBarView
              Expanded(
                child: TabBarView(
                  children: [
                    // รายละเอียด (placeholder)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
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

                    // สิ่งที่โพส (placeholder)
                    const Center(child: Text('สิ่งที่โพส', style: TextStyle(color: Colors.black54))),

                    // รีวิว
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                          child: Text('รีวิวจากผู้ว่าจ้าง (${reviews.length})', style: const TextStyle(fontWeight: FontWeight.w600, color: blue)),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: reviews.length,
                            itemBuilder: (context, index) {
                              final r = reviews[index];
                              return _reviewCard(context, r['name'] as String, r['date'] as String, r['rating'] as double);
                            },
                          ),
                        ),
                      ],
                    ),
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
