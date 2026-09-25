import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _usdFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _khrFormat = NumberFormat.currency(
    symbol: '៛',
    decimalDigits: 0,
    customPattern: '#,##0 ¤',
  );

  static String usd(dynamic amount) {
    if (amount == null) return '\$0.00';
    double value = 0.0;
    if (amount is num) {
      value = amount.toDouble();
    } else if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    }
    return _usdFormat.format(value);
  }

  static String khr(dynamic usdAmount, [double rate = 4100.0]) {
    if (usdAmount == null) return '0 ៛';
    double value = 0.0;
    if (usdAmount is num) {
      value = usdAmount.toDouble();
    } else if (usdAmount is String) {
      value = double.tryParse(usdAmount) ?? 0.0;
    }
    return _khrFormat.format(value * rate);
  }

  static Color statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
      case 'delivered':
      case 'completed':
      case 'active':
        return const Color(0xFF10B981); // Emerald
      case 'processing':
      case 'shipped':
        return const Color(0xFF3B82F6); // Blue
      case 'pending':
        return const Color(0xFFF59E0B); // Amber
      case 'cancelled':
      case 'failed':
      case 'inactive':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  static String formatDate(dynamic date) {
    if (date == null) return 'N/A';
    DateTime? dt;
    if (date is DateTime) {
      dt = date;
    } else if (date is String) {
      dt = DateTime.tryParse(date);
    }
    if (dt == null) return date.toString();
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dt.toLocal());
  }
}
