import 'package:flutter/material.dart';

// Minimal utility style fallback used by utility.dart and safe for analysis.
class UtilityStyle {
  static InputDecoration searchInputDecoration() {
    return InputDecoration(
      hintText: 'ค้นหา...',
      prefixIcon: const Icon(Icons.search),
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  static ButtonStyle primaryButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF3A5A99),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
