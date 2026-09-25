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
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      orderId: json['order_id'] is int ? json['order_id'] : int.tryParse(json['order_id'].toString()) ?? 0,
      transactionId: json['transaction_id']?.toString(),
      paymentMethod: json['payment_method'] ?? 'CASH_ON_DELIVERY',
      bankProvider: json['bank_provider']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'pending',
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
      orderId: json['order_id'] is int ? json['order_id'] : int.tryParse(json['order_id'].toString()) ?? 0,
      orderNumber: json['order_number'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      bankProvider: json['bank_provider'] ?? 'ABA',
      merchantName: json['merchant_name'] ?? 'BookVerse Cambodia',
      qrString: json['qr_string'] ?? '',
      transactionId: json['transaction_id'] ?? '',
    );
  }
}
