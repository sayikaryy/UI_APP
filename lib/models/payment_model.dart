import '../core/utils/currency_formatter.dart';

class PaymentModel {
  final int id;
  final int orderId;
  final String? transactionId;
  final String paymentMethod;
  final String? bankProvider; // 'ABA', 'ACLEDA', 'BAKONG', 'CARD', 'CASH'
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
  final String qrString;
  final String transactionId;

  KhqrDataModel({
    required this.orderId,
    required this.orderNumber,
    required this.amount,
    required this.currency,
    required this.bankProvider,
    required this.merchantName,
    required this.qrString,
    required this.transactionId,
  });

  factory KhqrDataModel.fromJson(Map<String, dynamic> json) {
    return KhqrDataModel(
      orderId: CurrencyFormatter.parseInt(json['order_id']),
      orderNumber: json['order_number']?.toString() ?? '',
      amount: CurrencyFormatter.parseDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'USD',
      bankProvider: json['bank_provider']?.toString() ?? 'ABA',
      merchantName: json['merchant_name']?.toString() ?? 'BookVerse Cambodia',
      qrString: json['qr_string']?.toString() ?? '',
      transactionId: json['transaction_id']?.toString() ?? '',
    );
  }
}
