import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // เพิ่มบรรทัดนี้
import 'dart:io' show Platform;

class TopupFormPage extends StatefulWidget {
  const TopupFormPage({super.key});

  @override
  State<TopupFormPage> createState() => _TopupFormPageState();
}

class _TopupFormPageState extends State<TopupFormPage> {
  final TextEditingController amountController = TextEditingController();
  bool qrCreated = false;
  String? qrUrl;
  String? transactionId;
  String? chargeId;
  bool loading = false;
  // TODO: replace with actual logged-in user's id
  final int currentUserId = 1;
  double? _initialBalance;
  Timer? _pollTimer;

  Future<void> createQr() async {
    final amountText = amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกจำนวนเงินที่ถูกต้อง')),
      );
      return;
    }
    setState(() {
      loading = true;
      qrCreated = false;
      qrUrl = null;
    });
    try {
      // fetch initial balance (optional) so we can detect wallet update
      try {
        final profileResp = await http.get(Uri.parse('$backendBase/account/profile?user_id=$currentUserId'));
        if (profileResp.statusCode == 200) {
          final p = jsonDecode(profileResp.body);
          _initialBalance = (p['money'] is num) ? (p['money'] as num).toDouble() : double.tryParse('${p['money']}');
        }
      } catch (_) {}
      // Ensure amount is integer (satang)
      final int amountSatang = (amount * 100).round();
      final resp = await http.post(
        Uri.parse('$backendBase/qr-charge'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amountSatang, 'user_id': currentUserId}),
      );
      debugPrint('POST /qr-charge -> ${resp.statusCode} ${resp.body}');
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          qrCreated = true;
          qrUrl = data['authorizeUri'] as String? ?? data['authorize_uri'] as String?;
          // store transaction and charge ids (if provided)
          transactionId = data['transaction_id'] != null ? '${data['transaction_id']}' : null;
          chargeId = (data['chargeId'] ?? data['charge_id'] ?? data['id']) != null ? '${data['chargeId'] ?? data['charge_id'] ?? data['id']}' : null;
        });
        // start polling user's profile to detect credited wallet as a fallback
        _pollTimer?.cancel();
        int attempts = 0;
        // expected amount in THB (we sent satang)
        final double expectedTopupThb = amountSatang / 100.0;
        _pollTimer = Timer.periodic(const Duration(seconds: 5), (t) async {
          attempts += 1;
          try {
            final profileResp = await http.get(Uri.parse('$backendBase/account/profile?user_id=$currentUserId'));
            if (profileResp.statusCode == 200) {
              final p = jsonDecode(profileResp.body);
              final money = (p['money'] is num) ? (p['money'] as num).toDouble() : double.tryParse('${p['money']}');
              // If we know initial balance, check it increased by at least the requested amount
              if (money != null && _initialBalance != null && money >= (_initialBalance! + expectedTopupThb)) {
                // updated, show success and stop polling
                t.cancel();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เติมเงินสำเร็จแล้ว')));
              }
            }
          } catch (_) {}
          if (attempts >= 24) { // stop after ~2 minutes
            _pollTimer?.cancel();
          }
        });
      } else {
        String msg = 'เกิดข้อผิดพลาด';
        try {
          msg = jsonDecode(resp.body)['error'] ?? msg;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้')),
      );
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    amountController.dispose();
    super.dispose();
  }

  bool isImageUrl(String? url) {
    if (url == null) return false;
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.svg');
  }

  Future<void> openQrUrl() async {
    if (qrUrl == null) return;
    final uri = Uri.parse(qrUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri); // ไม่ต้องใส่ mode สำหรับ cross-platform
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเปิดลิงก์ QR ได้')),
      );
    }
  }

  String get backendBase {
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:4000';
    } catch (_) {}
    // default to localhost for iOS/simulator and desktop during dev
    return 'http://localhost:4000';
  }

  Future<void> manualCheckStatus() async {
    // Re-check profile and notify user if credited
    try {
      final profileResp = await http.get(Uri.parse('$backendBase/account/profile?user_id=$currentUserId'));
      if (profileResp.statusCode == 200) {
        final p = jsonDecode(profileResp.body);
        final money = (p['money'] is num) ? (p['money'] as num).toDouble() : double.tryParse('${p['money']}');
        if (money != null && _initialBalance != null) {
          final amountText = amountController.text.trim();
          final amount = double.tryParse(amountText) ?? 0.0;
          final expected = (_initialBalance ?? 0.0) + amount;
          if (money >= expected) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เติมเงินสำเร็จแล้ว')));
            _pollTimer?.cancel();
            return;
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ยังไม่ได้รับเงิน โปรดลองอีกครั้ง')));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้')));
    }
  }

  Future<void> immediateCredit() async {
    if (transactionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่มีหมายเลขรายการ')));
      return;
    }
    setState(() {
      loading = true;
    });
    try {
      final resp = await http.post(
        Uri.parse('$backendBase/transaction/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'transaction_id': int.tryParse(transactionId ?? '') ?? transactionId}),
      );
      debugPrint('POST /transaction/complete -> ${resp.statusCode} ${resp.body}');
      if (resp.statusCode == 200) {
        // stop polling and notify
        _pollTimer?.cancel();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เติมเงินสำเร็จแล้ว')));
      } else {
        String msg = 'เกิดข้อผิดพลาด';
        try {
          msg = jsonDecode(resp.body)['error'] ?? msg;
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้')));
    } finally {
      if (mounted) setState(() { loading = false; });
    }
  }
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    alignment: Alignment.center,
                    child: const Text('พร้อมเพย์', style: TextStyle(fontSize: 18, color: Color(0xFF3A5A99))),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('จำนวนเงิน', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3A5A99))),
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'ระบุจำนวนเงิน',
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: loading ? null : createQr,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(100, 40),
                  ),
                  child: loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('สร้าง', style: TextStyle(color: Color(0xFF3A5A99))),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    height: 220,
                    alignment: Alignment.center,
                    child: qrCreated && qrUrl != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('สแกน QR เพื่อชำระเงิน', style: TextStyle(color: Color(0xFF3A5A99))),
                              const SizedBox(height: 8),
                              if (isImageUrl(qrUrl))
                                Image.network(
                                  qrUrl!,
                                  width: 160,
                                  height: 160,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, size: 48, color: Color(0xFF3A5A99)),
                                )
                              else
                                Image.network(
                                  'https://api.qrserver.com/v1/create-qr-code/?size=240x240&data=${Uri.encodeComponent(qrUrl!)}',
                                  width: 160,
                                  height: 160,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, size: 48, color: Color(0xFF3A5A99)),
                                ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: openQrUrl,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF22577A),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 2,
                                  minimumSize: const Size(100, 36),
                                ),
                                child: const Text('เปิด QR', style: TextStyle(color: Colors.white)),
                              ),
                              const SizedBox(height: 8),
                              if (transactionId != null)
                                Text('หมายเลขรายการ: $transactionId', style: const TextStyle(fontSize: 12, color: Color(0xFF3A5A99))),
                              if (chargeId != null)
                                Text('charge: $chargeId', style: const TextStyle(fontSize: 12, color: Color(0xFF3A5A99))),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: qrUrl != null
                            ? () {
                                Clipboard.setData(ClipboardData(text: qrUrl!));
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('คัดลอกลิงก์สำเร็จ')),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.copy, color: Color(0xFF3A5A99)),
                        label: const Text('คัดลอกลิงก์', style: TextStyle(color: Color(0xFF3A5A99))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF3A5A99)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Immediately credit the transaction to the user's wallet
                            if (qrCreated && transactionId != null) {
                              immediateCredit();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('กรุณาสร้าง QR ก่อน')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22577A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 2,
                            minimumSize: const Size(100, 48),
                          ),
                          child: const Text('ยืนยัน', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: manualCheckStatus,
                        child: const Text('ตรวจสอบสถานะ'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
