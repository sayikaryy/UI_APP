import '../core/utils/currency_formatter.dart';
import 'book_model.dart';

class CartItemModel {
  final int id;
  final int userId;
  final int bookId;
  int quantity;
  final BookModel? book;

  CartItemModel({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.quantity,
    this.book,
  });

  double get subtotal => (book?.price ?? 0.0) * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: CurrencyFormatter.parseInt(json['id']),
      userId: CurrencyFormatter.parseInt(json['user_id']),
      bookId: CurrencyFormatter.parseInt(json['book_id']),
      quantity: CurrencyFormatter.parseInt(json['quantity'], 1),
      book: json['book'] != null ? BookModel.fromJson(json['book']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'quantity': quantity,
      if (book != null) 'book': book!.toJson(),
    };
  }
}

class CartSummaryModel {
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final int itemsCount;

  CartSummaryModel({
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.itemsCount,
  });

  factory CartSummaryModel.fromJson(Map<String, dynamic> json) {
    return CartSummaryModel(
      subtotal: CurrencyFormatter.parseDouble(json['subtotal']),
      deliveryFee: CurrencyFormatter.parseDouble(json['delivery_fee']),
      totalAmount: CurrencyFormatter.parseDouble(json['total_amount']),
      itemsCount: CurrencyFormatter.parseInt(json['items_count']),
    );
  }
}
