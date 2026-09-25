import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/book_model.dart';
import '../../providers/admin_provider.dart';

class AdminInventoryView extends StatefulWidget {
  const AdminInventoryView({super.key});

  @override
  State<AdminInventoryView> createState() => _AdminInventoryViewState();
}

class _AdminInventoryViewState extends State<AdminInventoryView> {
  bool _lowStockOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      admin.fetchInventory();
      admin.fetchSuppliers();
    });
  }

  void _showAdjustStockDialog(BookModel book) {
    final qtyController = TextEditingController(text: '10');
    final notesController = TextEditingController();
    String type = 'stock_in';
    int? selectedSupplierId;

    final adminProv = Provider.of<AdminProvider>(context, listen: false);
    if (adminProv.suppliers.isNotEmpty) {
      selectedSupplierId = adminProv.suppliers.first.id;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Adjust Stock: ${book.title}', style: const TextStyle(fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Inventory: ${book.stock} units', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),

                // Operation Type
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Adjustment Operation'),
                  items: const [
                    DropdownMenuItem(value: 'stock_in', child: Text('Stock Intake (+ Units)')),
                    DropdownMenuItem(value: 'stock_out', child: Text('Stock Reduction (- Units)')),
                    DropdownMenuItem(value: 'adjustment', child: Text('Set Exact Total Stock')),
                  ],
                  onChanged: (val) => setDialogState(() => type = val!),
                ),
                const SizedBox(height: 12),

                // Quantity
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity Units', hintText: 'e.g. 20'),
                ),
                const SizedBox(height: 12),

                // Supplier Selector
                if (adminProv.suppliers.isNotEmpty && type == 'stock_in') ...[
                  DropdownButtonFormField<int>(
                    value: selectedSupplierId,
                    decoration: const InputDecoration(labelText: 'Supplier / Distributor'),
                    items: adminProv.suppliers.map((s) {
                      return DropdownMenuItem<int>(value: s.id, child: Text(s.name, maxLines: 1));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedSupplierId = val),
                  ),
                  const SizedBox(height: 12),
                ],

                // Notes
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Reason / PO Number', hintText: 'e.g. Received shipment PO-9912'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(qtyController.text.trim()) ?? 0;
                if (qty <= 0 && type != 'adjustment') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid positive quantity')),
                  );
                  return;
                }

                final success = await adminProv.adjustStock(
                  bookId: book.id,
                  type: type,
                  quantity: qty,
                  supplierId: selectedSupplierId,
                  notes: notesController.text.trim(),
                );

                if (context.mounted && success) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inventory log recorded and stock updated!'), backgroundColor: Color(0xFF10B981)),
                  );
                }
              },
              child: const Text('Save Adjustment'),
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
        title: const Text('Inventory & Stock'),
      ),
      body: Column(
        children: [
          // Filter Switch Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Stock'),
                  selected: !_lowStockOnly,
                  onSelected: (val) {
                    setState(() => _lowStockOnly = false);
                    adminProv.fetchInventory(lowStockOnly: false);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Low Stock Alerts ⚠️'),
                  selected: _lowStockOnly,
                  selectedColor: Colors.red.shade100,
                  onSelected: (val) {
                    setState(() => _lowStockOnly = true);
                    adminProv.fetchInventory(lowStockOnly: true);
                  },
                ),
              ],
            ),
          ),

          // Inventory List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => adminProv.fetchInventory(lowStockOnly: _lowStockOnly),
              child: adminProv.isLoading && adminProv.adminBooks.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : adminProv.adminBooks.isEmpty
                      ? const Center(child: Text('No inventory records found'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: adminProv.adminBooks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final book = adminProv.adminBooks[index];

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: book.isLowStock ? Colors.red.shade300 : AppTheme.border,
                                  width: book.isLowStock ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          book.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Category: ${book.category?.name ?? "General"} • Price: ${CurrencyFormatter.usd(book.price)}',
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              'Current Stock: ${book.stock}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 13,
                                                color: book.isLowStock ? AppTheme.error : AppTheme.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '(Threshold: ${book.lowStockThreshold})',
                                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: book.isLowStock ? AppTheme.error : AppTheme.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    icon: const Icon(Icons.tune, size: 14),
                                    label: const Text('Adjust'),
                                    onPressed: () => _showAdjustStockDialog(book),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
