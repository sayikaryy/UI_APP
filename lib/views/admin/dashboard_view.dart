import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../customer/digital_receipt_view.dart';
import '../auth/login_view.dart';

class AdminDashboardView extends StatefulWidget {
  final Function(int) onNavigateTab;

  const AdminDashboardView({super.key, required this.onNavigateTab});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = Provider.of<AdminProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final kpis = adminProv.kpis;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.dashboard_rounded, color: AppTheme.accent),
            SizedBox(width: 8),
            Text('Admin Portal', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: AppTheme.error),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginView()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => adminProv.fetchDashboard(),
        child: adminProv.isLoading && kpis == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.accent,
                            radius: 24,
                            child: Text(
                              auth.currentUser?.name.isNotEmpty == true ? auth.currentUser!.name[0] : 'A',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${auth.currentUser?.name ?? "Administrator"}',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Store Operations & Business Intelligence',
                                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 1. KPI Cards Grid
                    const Text('Executive Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Total Revenue',
                            value: CurrencyFormatter.usd(kpis?.totalRevenue ?? 0),
                            subtitle: CurrencyFormatter.khr(kpis?.totalRevenue ?? 0),
                            icon: Icons.payments_rounded,
                            iconColor: const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Total Orders',
                            value: '${kpis?.totalOrders ?? 0}',
                            subtitle: 'Customer orders',
                            icon: Icons.shopping_cart_checkout_rounded,
                            iconColor: const Color(0xFF3B82F6),
                            onTap: () => widget.onNavigateTab(3), // Navigate to Orders
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Total Books',
                            value: '${kpis?.totalBooks ?? 0}',
                            subtitle: 'Active titles',
                            icon: Icons.library_books_rounded,
                            iconColor: AppTheme.primary,
                            onTap: () => widget.onNavigateTab(1), // Navigate to Books
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Low Stock Alert',
                            value: '${kpis?.lowStockCount ?? 0}',
                            subtitle: (kpis?.lowStockCount ?? 0) > 0 ? 'Needs restock' : 'Healthy inventory',
                            icon: Icons.warning_amber_rounded,
                            iconColor: (kpis?.lowStockCount ?? 0) > 0 ? AppTheme.error : const Color(0xFF10B981),
                            onTap: () => widget.onNavigateTab(2), // Navigate to Inventory
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 2. Low-Stock Alert Warning Box
                    if (adminProv.lowStockBooks.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Low Stock Alerts ⚠️', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () => widget.onNavigateTab(2),
                            child: const Text('Manage Stock', style: TextStyle(fontSize: 12, color: AppTheme.accent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...adminProv.lowStockBooks.take(3).map((b) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  b.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Only ${b.stock} units',
                                  style: const TextStyle(color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                    ],

                    // 3. Recent Customer Orders
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => widget.onNavigateTab(3),
                          child: const Text('View All', style: TextStyle(fontSize: 12, color: AppTheme.accent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (adminProv.recentOrders.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No orders yet')))
                    else
                      ...adminProv.recentOrders.map((order) {
                        final statusColor = CurrencyFormatter.statusColor(order.status);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(
                              '${order.user?.name ?? "Customer"} • ${CurrencyFormatter.usd(order.totalAmount)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                order.status.toUpperCase(),
                                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => DigitalReceiptView(orderId: order.id)),
                              );
                            },
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                Icon(icon, color: iconColor, size: 22),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
