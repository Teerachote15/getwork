import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  // recipient id is provided server-side (DEFAULT_OMISE_RECIPIENT) so remove client input
  final TextEditingController _amountController = TextEditingController();

  final double balance = 5000; // สมมติยอดเงินในบัญชี
  bool _loading = false;
  String? _transactionId;
  // TODO: use real authenticated user id
  final int currentUserId = 1;

  String get backendBase {
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:4000';
    } catch (_) {}
    return 'http://localhost:4000';
  }

  // ฟังก์ชันแสดง dialog แจ้งเตือนยอดเงินไม่พอ
  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.grey[400], size: 40),
              const SizedBox(height: 12),
              const Text('ขออภัย', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              const Text(
                'ยอดเงินของคุณไม่เพียงพอ\nกรุณาเติมเงินในบัญชีของคุณ\nระบบจะแสดงปุ่มไปยังหน้าเติมเงิน',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ตกลง', style: TextStyle(color: Color(0xFF22577A))),
                  ),
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    backgroundColor: Colors.green,
                    radius: 16,
                    child: Icon(Icons.check, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createAndProcessWithdraw() async {
    final bank = _bankController.text.trim();
    final number = _numberController.text.trim();
    final amtText = _amountController.text.trim();
    final amount = double.tryParse(amtText) ?? 0.0;
    if (bank.isEmpty || number.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')));
      return;
    }
    setState(() { _loading = true; });
    try {
      // create withdraw request
      final resp = await http.post(
        Uri.parse('$backendBase/withdraw'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': currentUserId, 'amount': amount, 'via': bank}),
      );
      if (resp.statusCode != 200) {
        String msg = 'เกิดข้อผิดพลาด';
        try { msg = jsonDecode(resp.body)['error'] ?? msg; } catch(_){}
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }
      final data = jsonDecode(resp.body);
      final txId = data['transaction_id']?.toString();
      _transactionId = txId;

      // Immediately attempt to complete the withdraw (dev flow)
      if (txId != null) {
        // Server will use DEFAULT_OMISE_RECIPIENT when recipient_id is not supplied
        final comp = await http.post(Uri.parse('$backendBase/withdraw/$txId/complete'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({}));
        if (comp.statusCode == 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ถอนเงินเรียบร้อย')));
        } else {
          String msg = 'ไม่สามารถดำเนินการถอนเงินได้';
          try { msg = jsonDecode(comp.body)['error'] ?? msg; } catch(_){}
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้')));
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    final textScale = MediaQuery.of(context).textScaleFactor;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF22577A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ถอนเงิน',
          style: TextStyle(
            color: const Color(0xFF22577A),
            fontWeight: FontWeight.bold,
            fontSize: 20 * textScale,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: screenHeight * 0.04),
          child: Column(
            children: [
              // Bank icon/image
              Container(
                margin: EdgeInsets.only(bottom: screenHeight * 0.03),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Image.asset(
                      'assets/images/bank.png',
                      width: screenWidth * 0.35,
                      height: screenWidth * 0.22,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.account_balance, size: screenWidth * 0.22, color: const Color(0xFF22577A)),
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              // Input fields
              Container(
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
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.02),
                child: Column(
                  children: [
                    TextField(
                      controller: _bankController,
                      decoration: InputDecoration(
                        labelText: 'Bank',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextField(
                      controller: _numberController,
                      decoration: InputDecoration(
                        labelText: 'หมายเลข',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    // recipient is provided server-side via DEFAULT_OMISE_RECIPIENT; no client input needed
                    TextField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'จำนวนเงิน',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3797D6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(120, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _loading
                      ? null
                      : () {
                          final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
                          if (amt > balance) {
                            _showInsufficientFundsDialog();
                            return;
                          }
                          _createAndProcessWithdraw();
                        },
                  child: _loading
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('ยืนยัน', style: TextStyle(fontSize: 20 * textScale)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
