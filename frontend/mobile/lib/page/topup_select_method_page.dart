import 'package:flutter/material.dart';

class TopupSelectMethodPage extends StatefulWidget {
  const TopupSelectMethodPage({super.key});

  @override
  State<TopupSelectMethodPage> createState() => _TopupSelectMethodPageState();
}

class _TopupSelectMethodPageState extends State<TopupSelectMethodPage> {
  int selected = 1; // 1 = Payment, 2 = พร้อมเพย์

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เติมเงิน', style: TextStyle(color: Color(0xFF3A5A99))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3A5A99)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          margin: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () => setState(() => selected = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    alignment: Alignment.center,
                    child: const Text('Payment', style: TextStyle(fontSize: 18, color: Color(0xFF3A5A99))),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () => setState(() => selected = 2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: const Text('พร้อมเพย์', style: TextStyle(fontSize: 16, color: Color(0xFF3A5A99))),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24, right: 12),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/topupForm');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22577A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                      minimumSize: const Size(100, 40),
                    ),
                    child: const Text('ถัดไป', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
