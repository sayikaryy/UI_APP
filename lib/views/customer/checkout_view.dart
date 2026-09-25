import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/book_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import 'khqr_payment_modal.dart';
import 'digital_receipt_view.dart';
import 'addresses_view.dart';

class CheckoutView extends StatefulWidget {
  final Map<String, dynamic>? directItem;

  const CheckoutView({super.key, this.directItem});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  String _selectedPaymentMethod = 'ABA_KHQR';
  String _deliveryMethod = 'Standard Courier (1-2 days)';
  double _deliveryFee = 1.50;
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

  void _onDeliveryMethodChanged(String method, double fee) {
    setState(() {
      _deliveryMethod = method;
      _deliveryFee = fee;
    });
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

      // Check if Cambodian QR payment was selected
      if (_selectedPaymentMethod.contains('KHQR') || _selectedPaymentMethod.contains('BAKONG')) {
        String bank = 'ABA';
        if (_selectedPaymentMethod.contains('ACLEDA')) bank = 'ACLEDA';
        if (_selectedPaymentMethod.contains('BAKONG')) bank = 'BAKONG';

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => KhqrPaymentModal(order: placedOrder, bank: bank),
        );
      } else {
        // Direct simulation / COD
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
        title: const Text('Checkout'),
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

            // 2. Delivery Method Selection
            const Text('Delivery Speed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'Standard Courier (1-2 days)',
                    groupValue: _deliveryMethod,
                    activeColor: AppTheme.primary,
                    title: const Text('Standard Courier (1-2 business days)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Phnom Penh and metropolitan areas', style: TextStyle(fontSize: 12)),
                    secondary: const Text('\$1.50', style: TextStyle(fontWeight: FontWeight.bold)),
                    onChanged: (val) => _onDeliveryMethodChanged(val!, 1.50),
                  ),
                  const Divider(height: 1, color: AppTheme.border),
                  RadioListTile<String>(
                    value: 'Express Delivery (Same Day)',
                    groupValue: _deliveryMethod,
                    activeColor: AppTheme.primary,
                    title: const Text('Express Delivery (Same-day speed)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Delivered within 3-5 hours in Phnom Penh', style: TextStyle(fontSize: 12)),
                    secondary: const Text('\$3.00', style: TextStyle(fontWeight: FontWeight.bold)),
                    onChanged: (val) => _onDeliveryMethodChanged(val!, 3.00),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Cambodian Payment Method Selection
            const Text('Payment Gateway (Cambodia)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  // ABA KHQR
                  RadioListTile<String>(
                    value: 'ABA_KHQR',
                    groupValue: _selectedPaymentMethod,
                    activeColor: AppTheme.abaBlue,
                    title: const Text('ABA PayWay KHQR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Instant QR scan via ABA Mobile App', style: TextStyle(fontSize: 12)),
                    secondary: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.abaBlue, borderRadius: BorderRadius.circular(6)),
                      child: const Text('ABA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                  ),
                  const Divider(height: 1, color: AppTheme.border),

                  // ACLEDA KHQR
                  RadioListTile<String>(
                    value: 'ACLEDA_KHQR',
                    groupValue: _selectedPaymentMethod,
                    activeColor: AppTheme.acledaBlue,
                    title: const Text('ACLEDA KHQR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Instant QR scan via ACLEDA Mobile', style: TextStyle(fontSize: 12)),
                    secondary: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.acledaBlue, borderRadius: BorderRadius.circular(6)),
                      child: const Text('ACLEDA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                  ),
                  const Divider(height: 1, color: AppTheme.border),

                  // Bakong KHQR
                  RadioListTile<String>(
                    value: 'BAKONG_KHQR',
                    groupValue: _selectedPaymentMethod,
                    activeColor: AppTheme.bakongRed,
                    title: const Text('Bakong KHQR (National Standard)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Supports all Cambodian member banks', style: TextStyle(fontSize: 12)),
                    secondary: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.bakongRed, borderRadius: BorderRadius.circular(6)),
                      child: const Text('KHQR', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                  ),
                  const Divider(height: 1, color: AppTheme.border),

                  // Credit Card
                  RadioListTile<String>(
                    value: 'CARD',
                    groupValue: _selectedPaymentMethod,
                    activeColor: AppTheme.primary,
                    title: const Text('Visa / MasterCard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('International credit or debit card', style: TextStyle(fontSize: 12)),
                    secondary: const Icon(Icons.credit_card_rounded, color: AppTheme.primary),
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                  ),
                  const Divider(height: 1, color: AppTheme.border),

                  // Cash on Delivery
                  RadioListTile<String>(
                    value: 'CASH_ON_DELIVERY',
                    groupValue: _selectedPaymentMethod,
                    activeColor: AppTheme.primary,
                    title: const Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Pay cash upon book package arrival', style: TextStyle(fontSize: 12)),
                    secondary: const Icon(Icons.money_rounded, color: Colors.green),
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                  ),
                ],
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
                backgroundColor: AppTheme.accent,
              ),
              onPressed: orderProv.isLoading ? null : _handlePlaceOrder,
              child: orderProv.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _selectedPaymentMethod.contains('KHQR')
                          ? 'Generate KHQR & Pay (${CurrencyFormatter.usd(grandTotal)})'
                          : 'Confirm & Place Order (${CurrencyFormatter.usd(grandTotal)})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
