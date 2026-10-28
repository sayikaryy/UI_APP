import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/book_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import 'digital_receipt_view.dart';
import 'addresses_view.dart';
import 'khqr_payment_modal.dart';

class CheckoutView extends StatefulWidget {
  final Map<String, dynamic>? directItem;

  const CheckoutView({super.key, this.directItem});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  String _selectedPaymentMethod = 'BAKONG_KHQR';
  final String _deliveryMethod = 'Standard Courier (1-2 days)';
  final double _deliveryFee = 1.50;
  final _phoneController = TextEditingController();
  final _customAddressController = TextEditingController();
  final _noteController = TextEditingController();
  int? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProv = Provider.of<OrderProvider>(context, listen: false);
      orderProv.fetchAddresses().then((_) {
        if (orderProv.defaultAddress != null) {
          setState(() {
            _selectedAddressId = orderProv.defaultAddress!.id;
            _phoneController.text = orderProv.defaultAddress!.phone;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _customAddressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);

    String shippingAddress = '';
    if (_selectedAddressId != null) {
      final addr = orderProv.addresses.firstWhere((a) => a.id == _selectedAddressId);
      shippingAddress = '${addr.recipientName}, ${addr.addressLine}, ${addr.city}';
    } else {
      shippingAddress = _customAddressController.text.trim();
    }

    if (shippingAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a shipping address'), backgroundColor: AppTheme.error),
      );
      return;
    }

    List<Map<String, dynamic>> orderItems = [];

    if (widget.directItem != null) {
      final BookModel book = widget.directItem!['book'];
      orderItems.add({
        'book_id': book.id,
        'quantity': widget.directItem!['quantity'],
      });
    } else {
      for (var item in cart.items) {
        orderItems.add({
          'book_id': item.bookId,
          'quantity': item.quantity,
        });
      }
    }

    if (orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to purchase'), backgroundColor: AppTheme.error),
      );
      return;
    }

    final placedOrder = await orderProv.placeOrder(
      shippingAddress: shippingAddress,
      paymentMethod: _selectedPaymentMethod,
      deliveryMethod: _deliveryMethod,
      phone: _phoneController.text.trim(),
      note: _noteController.text.trim(),
      items: orderItems,
    );

    if (!mounted) return;

    if (placedOrder != null) {
      if (widget.directItem == null) {
        cart.clearCart();
      }

      // Check payment selection flow
      if (_selectedPaymentMethod == 'BAKONG_KHQR') {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black54,
          builder: (_) => KhqrPaymentModal(order: placedOrder),
        );
      } else {
        // Cash on delivery / other
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DigitalReceiptView(orderId: placedOrder.id),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProv.errorMessage ?? 'Order submission failed'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final orderProv = Provider.of<OrderProvider>(context);

    double subtotal = 0.0;
    int itemsCount = 0;

    if (widget.directItem != null) {
      subtotal = widget.directItem!['subtotal'];
      itemsCount = widget.directItem!['quantity'];
    } else {
      subtotal = cart.subtotal;
      itemsCount = cart.itemCount;
    }

    final grandTotal = subtotal + _deliveryFee;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Color(0xFF34D399),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'Shopping',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Shipping Address Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_location_alt, size: 16, color: AppTheme.accent),
                  label: const Text('Manage', style: TextStyle(color: AppTheme.accent, fontSize: 13)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddressesView()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (orderProv.addresses.isNotEmpty) ...[
              ...orderProv.addresses.map((addr) {
                final isSelected = _selectedAddressId == addr.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: RadioListTile<int>(
                    value: addr.id,
                    groupValue: _selectedAddressId,
                    activeColor: AppTheme.primary,
                    title: Row(
                      children: [
                        Text(addr.recipientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(addr.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${addr.addressLine}, ${addr.city} • ${addr.phone}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _selectedAddressId = val;
                        _phoneController.text = addr.phone;
                      });
                    },
                  ),
                );
              }),
            ] else ...[
              // Custom Address fallback
              TextField(
                controller: _customAddressController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Address',
                  hintText: 'Building, Street name, Sangkat, Phnom Penh',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone',
                  hintText: '+855 12 345 678',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // 2. Choose way to pay (Matching Screen 1)
            const Text(
              'Choose way to pay',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),

            // Bakong KHQR Card (Official NBC Gateway)
            InkWell(
              onTap: () => setState(() => _selectedPaymentMethod = 'BAKONG_KHQR'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedPaymentMethod == 'BAKONG_KHQR' ? AppTheme.bakongRed : AppTheme.border,
                    width: _selectedPaymentMethod == 'BAKONG_KHQR' ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedPaymentMethod == 'BAKONG_KHQR'
                          ? AppTheme.bakongRed.withOpacity(0.08)
                          : Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Bakong Logo Badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.bakongRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.qr_code_2_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Bakong KHQR',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                              ),
                              SizedBox(width: 6),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.all(Radius.circular(6)),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Text(
                                    'OFFICIAL',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.bakongRed,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Scan with Bakong or any KHQR banking app',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: _selectedPaymentMethod == 'BAKONG_KHQR' ? AppTheme.bakongRed : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),

            // Cash on Delivery Card
            InkWell(
              onTap: () => setState(() => _selectedPaymentMethod = 'CASH_ON_DELIVERY'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedPaymentMethod == 'CASH_ON_DELIVERY' ? const Color(0xFF10B981) : AppTheme.border,
                    width: _selectedPaymentMethod == 'CASH_ON_DELIVERY' ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Cash Icon Badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.payments_outlined,
                          color: Color(0xFF10B981),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cash on Delivery',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pay cash upon book package arrival',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: _selectedPaymentMethod == 'CASH_ON_DELIVERY' ? const Color(0xFF10B981) : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Order Note
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Delivery Notes (Optional)',
                hintText: 'e.g. Leave with security guard at reception',
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // Order Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal ($itemsCount books)', style: const TextStyle(color: AppTheme.textSecondary)),
                      Text(CurrencyFormatter.usd(subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Shipping Fee', style: TextStyle(color: AppTheme.textSecondary)),
                      Text(CurrencyFormatter.usd(_deliveryFee), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 20, color: AppTheme.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grand Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.usd(grandTotal),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primary),
                          ),
                          Text(
                            CurrencyFormatter.khr(grandTotal),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: _selectedPaymentMethod == 'BAKONG_KHQR' ? AppTheme.bakongRed : AppTheme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: orderProv.isLoading ? null : _handlePlaceOrder,
              child: orderProv.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _selectedPaymentMethod == 'BAKONG_KHQR'
                          ? 'Pay with Bakong KHQR (${CurrencyFormatter.usd(grandTotal)})'
                          : 'Place Order with Cash on Delivery (${CurrencyFormatter.usd(grandTotal)})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
