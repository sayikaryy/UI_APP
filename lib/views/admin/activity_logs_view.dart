import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/admin_provider.dart';

class AdminActivityLogsView extends StatefulWidget {
  const AdminActivityLogsView({super.key});

  @override
  State<AdminActivityLogsView> createState() => _AdminActivityLogsViewState();
}

class _AdminActivityLogsViewState extends State<AdminActivityLogsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchActivityLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Security & Activity Audit'),
      ),
      body: RefreshIndicator(
        onRefresh: () => adminProv.fetchActivityLogs(),
        child: adminProv.isLoading && adminProv.activityLogs.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : adminProv.activityLogs.isEmpty
                ? const Center(child: Text('No audit logs recorded'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: adminProv.activityLogs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final log = adminProv.activityLogs[index];

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    log.module.toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppTheme.primary),
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatDate(log.createdAt),
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              log.description,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Action: ${log.action} • IP: ${log.ipAddress ?? "127.0.0.1"}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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
