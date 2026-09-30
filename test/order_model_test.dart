import 'package:flutter_test/flutter_test.dart';
import 'package:bookverse_project/models/order_model.dart';
import 'package:bookverse_project/models/payment_model.dart';
import 'package:bookverse_project/models/cart_model.dart';
import 'package:bookverse_project/core/utils/currency_formatter.dart';

void main() {
  group('Laravel JSON Decimal String Deserialization Tests', () {
    test('OrderModel parses decimal string attributes from Laravel', () {
      final json = {
        'id': 42,
        'user_id': 3,
        'order_number': 'ORD-20260929-ABCD',
        'subtotal': '24.00',
        'delivery_fee': '1.50',
        'discount': '0.00',
        'total_amount': '25.50',
        'status': 'pending',
        'shipping_address': 'Building 12, Street 310, Phnom Penh',
        'delivery_method': 'Standard Courier (1-2 days)',
        'phone': '012345678',
        'created_at': '2026-09-29T08:00:00.000000Z',
        'items': [
          {
            'id': 101,
            'order_id': 42,
            'book_id': 5,
            'quantity': 2,
            'price': '12.00',
            'subtotal': '24.00',
            'book': {
              'id': 5,
              'category_id': 1,
              'title': 'Flutter Apprentice',
              'author': 'Ray Wenderlich Team',
              'price': '12.00',
              'stock': 15,
              'cover_image_url': 'https://example.com/cover.jpg',
            },
          }
        ],
        'payment': {
          'id': 88,
          'order_id': 42,
          'transaction_id': 'TXN-ABA-123456',
          'payment_method': 'ABA_KHQR',
          'bank_provider': 'ABA',
          'amount': '25.50',
          'currency': 'USD',
          'status': 'pending',
          'qr_string': '00020101021229370016bakong@abaa00010108abaa_usd52045999',
        },
      };

      final order = OrderModel.fromJson(json);

      expect(order.id, 42);
      expect(order.userId, 3);
      expect(order.orderNumber, 'ORD-20260929-ABCD');
      expect(order.subtotal, 24.0);
      expect(order.deliveryFee, 1.5);
      expect(order.discount, 0.0);
      expect(order.totalAmount, 25.5);
      expect(order.status, 'pending');
      expect(order.items.length, 1);
      expect(order.items.first.price, 12.0);
      expect(order.items.first.subtotal, 24.0);
      expect(order.items.first.quantity, 2);
      expect(order.payment, isNotNull);
      expect(order.payment!.amount, 25.5);
      expect(order.payment!.bankProvider, 'ABA');
    });

    test('KhqrDataModel parses string amount correctly', () {
      final json = {
        'order_id': '42',
        'order_number': 'ORD-20260929-ABCD',
        'amount': '25.50',
        'currency': 'USD',
        'bank_provider': 'ABA',
        'merchant_name': 'BookVerse Cambodia',
        'qr_string': '00020101021229370016bakong@abaa00010108abaa_usd',
        'transaction_id': 'TXN-ABA-123',
      };

      final khqr = KhqrDataModel.fromJson(json);
      expect(khqr.orderId, 42);
      expect(khqr.amount, 25.5);
      expect(khqr.bankProvider, 'ABA');
    });

    test('CartSummaryModel parses string decimals correctly', () {
      final json = {
        'subtotal': '45.00',
        'delivery_fee': '1.50',
        'total_amount': '46.50',
        'items_count': '3',
      };

      final summary = CartSummaryModel.fromJson(json);
      expect(summary.subtotal, 45.0);
      expect(summary.deliveryFee, 1.5);
      expect(summary.totalAmount, 46.5);
      expect(summary.itemsCount, 3);
    });

    test('CurrencyFormatter parses doubles and ints reliably', () {
      expect(CurrencyFormatter.parseDouble('25.50'), 25.5);
      expect(CurrencyFormatter.parseDouble(25.5), 25.5);
      expect(CurrencyFormatter.parseDouble(null), 0.0);
      expect(CurrencyFormatter.parseDouble('invalid'), 0.0);

      expect(CurrencyFormatter.parseInt('42'), 42);
      expect(CurrencyFormatter.parseInt(42), 42);
      expect(CurrencyFormatter.parseInt(null, 1), 1);
    });
  });
}
