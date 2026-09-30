import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import 'digital_receipt_view.dart';

enum KhqrPaymentStatus {
  pending,
  processing,
  success,
  failed,
}

class KhqrPaymentModal extends StatefulWidget {
  final OrderModel order;
  final String bank; // 'ABA', 'ACLEDA', 'BAKONG'

  const KhqrPaymentModal({
    super.key,
    required this.order,
    required this.bank,
  });

  @override
  State<KhqrPaymentModal> createState() => _KhqrPaymentModalState();
}

class _KhqrPaymentModalState extends State<KhqrPaymentModal> {
  int _secondsRemaining = 180; // 3-minute QR validity
  Timer? _timer;
  bool _isProcessing = false;
  KhqrPaymentStatus _paymentStatus = KhqrPaymentStatus.pending;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQrCode();
    });
  }

  void _loadQrCode() {
    Provider.of<OrderProvider>(context, listen: false)
        .generateKhqr(widget.order.id, bank: widget.bank);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        if (_paymentStatus == KhqrPaymentStatus.pending) {
          setState(() => _paymentStatus = KhqrPaymentStatus.failed);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _getBankColor() {
    switch (widget.bank.toUpperCase()) {
      case 'ABA':
        return AppTheme.abaBlue;
      case 'ACLEDA':
        return AppTheme.acledaBlue;
      case 'BAKONG':
      default:
        return AppTheme.bakongRed;
    }
  }

  String _getBankDisplayName() {
    switch (widget.bank.toUpperCase()) {
      case 'ABA':
        return 'ABA PayWay KHQR';
      case 'ACLEDA':
        return 'ACLEDA Mobile KHQR';
      case 'BAKONG':
      default:
        return 'Bakong KHQR';
    }
  }

  Widget _buildBankLogo(Color bankColor) {
    final bankKey = widget.bank.toUpperCase();
    if (bankKey == 'ABA') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bankColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ABA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 4),
            Text(
              'PayWay',
              style: TextStyle(
                color: Color(0xFF38BDF8), // sky blue
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    } else if (bankKey == 'ACLEDA') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bankColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_rounded, size: 14, color: Color(0xFFFBBF24)),
            SizedBox(width: 4),
            Text(
              'ACLEDA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bankColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'KHQR',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
  }

  String _formatTimer() {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildStatusBadge() {
    switch (_paymentStatus) {
      case KhqrPaymentStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade400),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pending_actions_rounded, size: 14, color: Colors.amber.shade900),
              const SizedBox(width: 5),
              Text(
                'Status: PENDING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.amber.shade900,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 12,
                color: Colors.amber.shade300,
              ),
              const SizedBox(width: 8),
              Icon(Icons.timer_outlined, size: 13, color: Colors.amber.shade900),
              const SizedBox(width: 3),
              Text(
                _formatTimer(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
        );
      case KhqrPaymentStatus.processing:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade300),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
              ),
              SizedBox(width: 6),
              Text(
                'Status: VERIFYING...',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ],
          ),
        );
      case KhqrPaymentStatus.success:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF6EE7B7)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
              SizedBox(width: 5),
              Text(
                'Status: PAYMENT SUCCESSFUL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF047857),
                ),
              ),
            ],
          ),
        );
      case KhqrPaymentStatus.failed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel_rounded, size: 14, color: Colors.red.shade800),
              const SizedBox(width: 5),
              Text(
                _secondsRemaining == 0 ? 'Status: QR EXPIRED' : 'Status: PAYMENT FAILED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
        );
    }
  }

  Future<void> _simulatePaymentApproval() async {
    // Prevent duplicate payment submissions
    if (_isProcessing || _paymentStatus == KhqrPaymentStatus.success) return;

    setState(() {
      _isProcessing = true;
      _paymentStatus = KhqrPaymentStatus.processing;
    });

    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    final success = await orderProv.simulatePaymentSuccess(widget.order.id);

    if (!mounted) return;

    if (success) {
      _timer?.cancel();
      setState(() {
        _isProcessing = false;
        _paymentStatus = KhqrPaymentStatus.success;
      });

      // Display success message based on backend response
      final msg = orderProv.paymentSuccessMessage ?? 'Payment successfully simulated and confirmed!';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
        ),
      );

      // Brief transition delay so customer sees successful state in modal
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;

      // Close modal and navigate to Digital Receipt
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DigitalReceiptView(orderId: widget.order.id),
        ),
      );
    } else {
      setState(() {
        _isProcessing = false;
        _paymentStatus = KhqrPaymentStatus.failed;
      });

      // Display failure message based on actual API response
      final err = orderProv.errorMessage ?? 'Payment simulation failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(err)),
            ],
          ),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = Provider.of<OrderProvider>(context);
    final khqr = orderProv.khqrData;
    final bankColor = _getBankColor();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header with Bank Name, Logo & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildBankLogo(bankColor),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getBankDisplayName(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Text(
                        'Bakong KHQR Standard',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 18),

          // QR Code Display Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _paymentStatus == KhqrPaymentStatus.success
                    ? const Color(0xFF10B981)
                    : bankColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: bankColor.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  khqr?.merchantName ?? 'BookVerse Cambodia',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order Number: ${widget.order.orderNumber}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),

                // QR Code Content
                if (orderProv.isLoading && khqr == null)
                  const SizedBox(
                    height: 190,
                    width: 190,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Generating KHQR Code...', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  )
                else if (khqr != null)
                  QrImageView(
                    data: khqr.qrString,
                    version: QrVersions.auto,
                    size: 190.0,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: bankColor,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF0F172A),
                    ),
                  )
                else
                  SizedBox(
                    height: 190,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 36, color: AppTheme.error),
                          const SizedBox(height: 8),
                          Text(
                            orderProv.errorMessage ?? 'Unable to generate QR',
                            style: const TextStyle(fontSize: 12, color: AppTheme.error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: _loadQrCode,
                            child: const Text('Retry', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 14),

                // Order Total Payment Amount
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Total: ',
                        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        CurrencyFormatter.usd(widget.order.totalAmount),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  ${CurrencyFormatter.khr(widget.order.totalAmount)}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Simulate payment with test accounts to complete order without real bank transfer',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 18),

          // Action Buttons: Cancel & Confirm / Simulate Payment
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppTheme.textSecondary,
                  ),
                  onPressed: _isProcessing || _paymentStatus == KhqrPaymentStatus.success
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), // Emerald
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    _isProcessing
                        ? 'Verifying...'
                        : (_paymentStatus == KhqrPaymentStatus.success
                            ? 'Confirmed!'
                            : 'Simulate Successful Payment'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: _isProcessing || _paymentStatus == KhqrPaymentStatus.success
                      ? null
                      : _simulatePaymentApproval,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
