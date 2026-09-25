import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';
import '../../providers/admin_provider.dart';
import '../customer/digital_receipt_view.dart';

class AdminOrderManagementView extends StatefulWidget {
  const AdminOrderManagementView({super.key});

  @override
  State<AdminOrderManagementView> createState() => _AdminOrderManagementViewState();
}

class _AdminOrderManagementViewState extends State<AdminOrderManagementView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _statuses = ['all', 'pending', 'processing', 'shipped', 'delivered', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final st = _statuses[_tabController.index];
        Provider.of<AdminProvider>(context, listen: false).fetchAdminOrders(status: st);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchAdminOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showStatusDialog(OrderModel order) {
    String selectedStatus = order.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Fulfill Order: ${order.orderNumber}', style: const TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${order.user?.name ?? "Customer"}'),
              const SizedBox(height: 6),
              Text('Amount: ${CurrencyFormatter.usd(order.totalAmount)} (${order.payment?.paymentMethod ?? "N/A"})'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'Order Lifecycle Status'),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending (Awaiting payment)')),
                  DropdownMenuItem(value: 'processing', child: Text('Processing (Preparing shipment)')),
                  DropdownMenuItem(value: 'shipped', child: Text('Shipped (Out for delivery)')),
                  DropdownMenuItem(value: 'delivered', child: Text('Delivered (Completed)')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled (Auto-restocks books)')),
                ],
                onChanged: (val) => setDialogState(() => selectedStatus = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final success = await Provider.of<AdminProvider>(context, listen: false)
                    .updateOrderStatus(order.id, selectedStatus);

                if (context.mounted && success) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Order status changed to ${selectedStatus.toUpperCase()}'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              },
              child: const Text('Update Status'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Order Fulfillment'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.accent,
          tabs: _statuses.map((s) => Tab(text: s.toUpperCase())).toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => adminProv.fetchAdminOrders(status: _statuses[_tabController.index]),
        child: adminProv.isLoading && adminProv.adminOrders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : adminProv.adminOrders.isEmpty
                ? const Center(child: Text('No orders matching this status'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: adminProv.adminOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = adminProv.adminOrders[index];
                      final statusColor = CurrencyFormatter.statusColor(order.status);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    order.status.toUpperCase(),
                                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Customer: ${order.user?.name ?? "Customer"} • ${order.phone ?? ""}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            Text(
                              'Address: ${order.shippingAddress}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            const Divider(height: 16, color: AppTheme.border),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      CurrencyFormatter.usd(order.totalAmount),
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                    ),
                                    Text(
                                      'Method: ${order.payment?.paymentMethod ?? "COD"}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        textStyle: const TextStyle(fontSize: 11),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => DigitalReceiptView(orderId: order.id)),
                                        );
                                      },
                                      child: const Text('Invoice'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        textStyle: const TextStyle(fontSize: 11),
                                      ),
                                      onPressed: () => _showStatusDialog(order),
                                      child: const Text('Update Status'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
