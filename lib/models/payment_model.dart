import 'dart:convert';
import 'dart:typed_data';
import '../core/utils/currency_formatter.dart';

class PaymentModel {
  final int id;
  final int orderId;
  final String? transactionId;
  final String paymentMethod;
  final String? bankProvider; // 'BAKONG', 'CASH'
  final double amount;
  final String currency;
  final String status; // 'pending', 'paid', 'failed'
  final String? qrString;
  final DateTime? paidAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    this.transactionId,
    required this.paymentMethod,
    this.bankProvider,
    required this.amount,
    this.currency = 'USD',
    required this.status,
    this.qrString,
    this.paidAt,
  });

  bool get isPaid => status.toLowerCase() == 'paid';

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: CurrencyFormatter.parseInt(json['id']),
      orderId: CurrencyFormatter.parseInt(json['order_id']),
      transactionId: json['transaction_id']?.toString(),
      paymentMethod: json['payment_method']?.toString() ?? 'CASH_ON_DELIVERY',
      bankProvider: json['bank_provider']?.toString(),
      amount: CurrencyFormatter.parseDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'USD',
      status: json['status']?.toString() ?? 'pending',
      qrString: json['qr_string']?.toString(),
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'transaction_id': transactionId,
      'payment_method': paymentMethod,
      'bank_provider': bankProvider,
      'amount': amount,
      'currency': currency,
      'status': status,
      'qr_string': qrString,
      'paid_at': paidAt?.toIso8601String(),
    };
  }
}

class KhqrDataModel {
  final int orderId;
  final String orderNumber;
  final double amount;
  final String currency;
  final String bankProvider;
  final String merchantName;
  final String? bakongAccountId;
  final String qrString;
  final String? qrImage;
  final String? md5;
  final String? deeplink;
  final String transactionId;
  final int? paymentId;
  final int lifetimeMinutes;
  final DateTime? expiredAt;
  final bool canSimulate;

  KhqrDataModel({
    required this.orderId,
    required this.orderNumber,
    required this.amount,
    required this.currency,
    required this.bankProvider,
    required this.merchantName,
    this.bakongAccountId,
    required this.qrString,
    this.qrImage,
    this.md5,
    this.deeplink,
    required this.transactionId,
    this.paymentId,
    this.lifetimeMinutes = 15,
    this.expiredAt,
    this.canSimulate = false,
  });

  /// Safely extracts and decodes Base64 data URL (e.g. data:image/png;base64,iVBOR...)
  Uint8List? get decodedQrImageBytes {
    if (qrImage == null || qrImage!.isEmpty) return null;
    try {
      String cleanBase64 = qrImage!;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
      return base64Decode(cleanBase64);
    } catch (_) {
      return null;
    }
  }

  factory KhqrDataModel.fromJson(Map<String, dynamic> json) {
    return KhqrDataModel(
      orderId: CurrencyFormatter.parseInt(json['order_id']),
      orderNumber: json['order_number']?.toString() ?? '',
      amount: CurrencyFormatter.parseDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'USD',
      bankProvider: json['bank_provider']?.toString() ?? 'BAKONG',
      merchantName: json['merchant_name']?.toString() ?? 'BookVerse',
      bakongAccountId: json['bakong_account_id']?.toString(),
      qrString: json['qr_string']?.toString() ?? json['qrString']?.toString() ?? '',
      qrImage: json['qr_image']?.toString() ?? json['qrImage']?.toString(),
      md5: json['md5']?.toString(),
      deeplink: json['deeplink']?.toString(),
      transactionId: json['transaction_id']?.toString() ?? json['tran_id']?.toString() ?? '',
      paymentId: json['payment_id'] != null ? CurrencyFormatter.parseInt(json['payment_id']) : null,
      lifetimeMinutes: json['lifetime_minutes'] != null ? CurrencyFormatter.parseInt(json['lifetime_minutes']) : 15,
      expiredAt: json['expired_at'] != null ? DateTime.tryParse(json['expired_at'].toString()) : null,
      canSimulate: json['can_simulate'] == true,
    );
  }
}
