import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/order_provider.dart';
import 'customer_main_nav.dart';

class DigitalReceiptView extends StatefulWidget {
  final int orderId;

  const DigitalReceiptView({super.key, required this.orderId});

  @override
  State<DigitalReceiptView> createState() => _DigitalReceiptViewState();
}

class _DigitalReceiptViewState extends State<DigitalReceiptView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchReceipt(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = Provider.of<OrderProvider>(context);
    final receipt = orderProv.currentReceipt;
    final paymentMap = receipt?.payment ?? {};
    final paymentMethod = paymentMap['payment_method']?.toString() ?? '';
    final isCod = paymentMethod.toUpperCase().contains('CASH') || paymentMethod.toUpperCase().contains('COD');
    final isPaid = paymentMap['payment_status']?.toString().toLowerCase() == 'paid';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Digital Receipt'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CustomerMainNav()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: orderProv.isLoading || receipt == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Success Badge
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (isCod ? Colors.blue : const Color(0xFF10B981)).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCod ? Icons.local_shipping_rounded : Icons.check_circle_rounded,
                              color: isCod ? Colors.blue.shade700 : const Color(0xFF10B981),
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isCod ? 'Order Placed Successfully!' : 'Payment Confirmed!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCod
                              ? 'Thank you! Please prepare cash upon delivery.'
                              : 'Thank you for shopping with BookVerse',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: AppTheme.border),
                        const SizedBox(height: 12),

                        // Store & Invoice Metadata
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  receipt.storeInfo['name'] ?? 'BookVerse Cambodia',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  receipt.storeInfo['address'] ?? 'Phnom Penh, Cambodia',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  receipt.invoiceNumber,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  receipt.orderDate,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Customer & Shipping Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recipient: ${receipt.customer['name']}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Phone: ${receipt.customer['phone']}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Address: ${receipt.customer['shipping_address']}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Items Breakdown
                        const Text(
                          'Purchased Items',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        ...receipt.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item['quantity']}x',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] ?? 'Book',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                      if (item['author'] != null)
                                        Text(
                                          item['author'],
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.usd(item['subtotal']),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(color: AppTheme.border, height: 24),

                        // Financial Totals
                        _buildTotalRow('Subtotal', CurrencyFormatter.usd(receipt.financials['subtotal'])),
                        const SizedBox(height: 4),
                        _buildTotalRow('Delivery Fee', CurrencyFormatter.usd(receipt.financials['delivery_fee'])),
                        if (CurrencyFormatter.parseDouble(receipt.financials['discount']) != 0.0) ...[
                          const SizedBox(height: 4),
                          _buildTotalRow('Discount', '- ${CurrencyFormatter.usd(receipt.financials['discount'])}'),
                        ],
                        const Divider(color: AppTheme.border, height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.usd(receipt.financials['total_amount']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.khr(receipt.financials['total_amount']),
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Payment Verification Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCod
                                ? Colors.blue.shade50
                                : const Color(0xFFF0FDF4), // Emerald 50
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCod
                                  ? Colors.blue.shade200
                                  : const Color(0xFFBBF7D0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Method: ${isCod ? "Cash on Delivery (COD)" : (paymentMethod == "BAKONG_KHQR" ? "Bakong KHQR" : paymentMethod)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Txn ID: ${receipt.payment['transaction_id'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isCod ? Colors.blue.shade700 : const Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPaid
                                      ? const Color(0xFF10B981)
                                      : (isCod ? Colors.blue.shade600 : const Color(0xFFF59E0B)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPaid ? 'PAID' : (isCod ? 'PAY ON ARRIVAL' : 'PENDING'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Back to Catalog Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const CustomerMainNav()),
                              (route) => false,
                            );
                          },
                          child: const Text('Back to Home'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
