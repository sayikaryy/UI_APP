import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import 'digital_receipt_view.dart';

enum KhqrPaymentStatus {
  pending,
  checking,
  success,
  expired,
  failed,
}

/// Bakong KHQR payment sheet: shows the QR and polls the backend for confirmation
class KhqrPaymentModal extends StatefulWidget {
  final OrderModel order;

  const KhqrPaymentModal({
    super.key,
    required this.order,
  });

  @override
  State<KhqrPaymentModal> createState() => _KhqrPaymentModalState();
}

class _KhqrPaymentModalState extends State<KhqrPaymentModal> {
  bool _isProcessing = false;
  KhqrPaymentStatus _paymentStatus = KhqrPaymentStatus.pending;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 15 * 60; // 15-minute standard QR lifetime
  int _pollCount = 0;
  static const int _maxPollCycles = 60; // Up to 15 minutes polling

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQrCodeAndStartPolling();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _formattedTimeRemaining {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    final lifetimeMin = orderProv.khqrData?.lifetimeMinutes ?? 15;
    _secondsRemaining = lifetimeMin * 60;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _pollTimer?.cancel();
        setState(() {
          _secondsRemaining = 0;
          _paymentStatus = KhqrPaymentStatus.expired;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _loadQrCodeAndStartPolling() async {
    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    final ok = await orderProv.generateKhqr(widget.order.id);
    if (ok && mounted) {
      _startCountdown();
      _startStatusPolling();
    }
  }

  void _startStatusPolling() {
    _pollTimer?.cancel();
    _pollCount = 0;
    // Poll the backend every 6 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (timer) async {
      if (!mounted || _paymentStatus == KhqrPaymentStatus.success || _paymentStatus == KhqrPaymentStatus.expired || _isProcessing) {
        return;
      }

      if (_pollCount >= _maxPollCycles) {
        timer.cancel();
        return;
      }

      setState(() => _pollCount++);
      final orderProv = Provider.of<OrderProvider>(context, listen: false);
      final isPaid = await orderProv.checkPaymentStatus(widget.order.id);

      if (isPaid && mounted) {
        timer.cancel();
        _countdownTimer?.cancel();
        _onPaymentConfirmed(isAutoDetected: true);
      }
    });
  }

  Future<void> _checkPaymentStatusManually() async {
    if (_isProcessing || _paymentStatus == KhqrPaymentStatus.success || _paymentStatus == KhqrPaymentStatus.expired) return;

    setState(() {
      _isProcessing = true;
    });

    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    final isPaid = await orderProv.checkPaymentStatus(widget.order.id);

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    if (isPaid) {
      _countdownTimer?.cancel();
      _onPaymentConfirmed(isAutoDetected: true);
    } else {
      final msg = orderProv.errorMessage ?? 'Payment not detected yet. Please ensure you finished the payment in your banking app.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showZoomedQr(String qrString, String recipientName, String amount, {Uint8List? imageBytes}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                recipientName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Amount: $amount',
                style: const TextStyle(fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: imageBytes != null
                    ? Image.memory(
                        imageBytes,
                        width: 260.0,
                        height: 260.0,
                        fit: BoxFit.contain,
                      )
                    : QrImageView(
                        data: qrString,
                        version: QrVersions.auto,
                        size: 260.0,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF000000),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF000000),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onPaymentConfirmed({bool isAutoDetected = false}) async {
    _pollTimer?.cancel();

    setState(() {
      _isProcessing = false;
      _paymentStatus = KhqrPaymentStatus.success;
    });

    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    final msg = orderProv.paymentSuccessMessage ??
        (isAutoDetected
            ? 'Payment verified by Bakong Open API!'
            : 'Payment successfully simulated and confirmed!');

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

    // Brief delay so customer sees successful state in modal
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DigitalReceiptView(orderId: widget.order.id),
      ),
    );
  }

  Future<void> _simulatePaymentApproval() async {
    if (_isProcessing || _paymentStatus == KhqrPaymentStatus.success) return;

    setState(() {
      _isProcessing = true;
      _paymentStatus = KhqrPaymentStatus.checking;
    });

    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    final success = await orderProv.simulatePaymentSuccess(widget.order.id);

    if (!mounted) return;

    if (success) {
      _onPaymentConfirmed(isAutoDetected: false);
    } else {
      setState(() {
        _isProcessing = false;
        _paymentStatus = KhqrPaymentStatus.failed;
      });

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

  Future<void> _openBakongApp(String deeplink) async {
    try {
      final uri = Uri.parse(deeplink);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Bakong app. Please scan the QR code manually.'),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching app: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildBakongLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bakongRed,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_2_rounded, size: 16, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'BAKONG',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = Provider.of<OrderProvider>(context);
    final khqr = orderProv.khqrData;
    const bankColor = AppTheme.bakongRed;
    final canSimulate = khqr?.canSimulate ?? false;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: SingleChildScrollView(
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
            const SizedBox(height: 14),

            // Header with Bank Name & Logo
            Row(
              children: [
                _buildBakongLogo(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bakong KHQR Gateway',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        khqr?.bakongAccountId != null
                            ? 'Bakong ID: ${khqr!.bakongAccountId}'
                            : 'NBC Standard KHQR (EMVCo)',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Auto-checking badge indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _paymentStatus == KhqrPaymentStatus.success
                        ? const Color(0xFF10B981).withOpacity(0.12)
                        : Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _paymentStatus == KhqrPaymentStatus.success
                              ? const Color(0xFF10B981)
                              : Colors.amber.shade800,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _paymentStatus == KhqrPaymentStatus.success
                            ? 'PAID'
                            : 'Listening...',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _paymentStatus == KhqrPaymentStatus.success
                              ? const Color(0xFF10B981)
                              : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                      : bankColor.withOpacity(0.35),
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
                  // Recipient Account Name (verified KYC name)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 5),
                      Text(
                        khqr?.merchantName ?? 'BookVerse',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Order #${widget.order.orderNumber}${khqr?.bakongAccountId != null ? ' • ${khqr!.bakongAccountId}' : ''}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),

                  // 15-Minute Real-Time Countdown Timer Banner
                  if (_paymentStatus != KhqrPaymentStatus.success) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _paymentStatus == KhqrPaymentStatus.expired || _secondsRemaining < 120
                            ? const Color(0xFFFEE2E2)
                            : bankColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _paymentStatus == KhqrPaymentStatus.expired || _secondsRemaining < 120
                              ? AppTheme.error.withOpacity(0.4)
                              : bankColor.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _paymentStatus == KhqrPaymentStatus.expired ? Icons.timer_off_rounded : Icons.timer_outlined,
                            size: 15,
                            color: _paymentStatus == KhqrPaymentStatus.expired || _secondsRemaining < 120
                                ? AppTheme.error
                                : bankColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _paymentStatus == KhqrPaymentStatus.expired
                                ? 'QR Code Expired'
                                : 'QR expires in: $_formattedTimeRemaining',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _paymentStatus == KhqrPaymentStatus.expired || _secondsRemaining < 120
                                  ? AppTheme.error
                                  : bankColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // QR Code Content
                  if (orderProv.isLoading && khqr == null)
                    SizedBox(
                      height: 220,
                      width: 220,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            const Text(
                              'Generating Bakong KHQR...',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (khqr != null)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => _showZoomedQr(
                            khqr.qrString,
                            khqr.merchantName,
                            CurrencyFormatter.usd(widget.order.totalAmount),
                            imageBytes: khqr.decodedQrImageBytes,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: khqr.decodedQrImageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      khqr.decodedQrImageBytes!,
                                      width: 210.0,
                                      height: 210.0,
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : QrImageView(
                                    data: khqr.qrString,
                                    version: QrVersions.auto,
                                    size: 210.0,
                                    backgroundColor: Colors.white,
                                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Color(0xFF000000), // Solid Raven Dark Black finder patterns
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Color(0xFF000000), // Solid black modules for maximum scan contrast
                                    ),
                                  ),
                          ),
                        ),
                        if (_paymentStatus == KhqrPaymentStatus.success)
                          Container(
                            width: 226,
                            height: 226,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 54, color: Color(0xFF10B981)),
                                SizedBox(height: 8),
                                Text(
                                  'Payment Received!',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF10B981)),
                                ),
                              ],
                            ),
                          ),
                        if (_paymentStatus == KhqrPaymentStatus.expired)
                          Container(
                            width: 226,
                            height: 226,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.96),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.timer_off_rounded, size: 48, color: AppTheme.error),
                                const SizedBox(height: 8),
                                const Text(
                                  'QR Code Expired',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.error),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${khqr.lifetimeMinutes}-minute validity window ended.',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _loadQrCodeAndStartPolling,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: bankColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Regenerate QR', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    )
                  else
                    SizedBox(
                      height: 210,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 36, color: AppTheme.error),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                orderProv.errorMessage ?? 'Unable to generate QR code.',
                                style: const TextStyle(fontSize: 12, color: AppTheme.error),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _loadQrCodeAndStartPolling,
                              icon: const Icon(Icons.refresh_rounded, size: 14),
                              label: const Text('Retry', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (khqr != null && _paymentStatus != KhqrPaymentStatus.success && _paymentStatus != KhqrPaymentStatus.expired) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.zoom_in_rounded, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Tap QR to enlarge',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),

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

                  // Deeplink Action Button if present
                  if (khqr?.deeplink != null && khqr!.deeplink!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bankColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text(
                          'Open in Bakong App',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _openBakongApp(khqr.deeplink!),
                      ),
                    ),
                  ],

                  // Copy buttons
                  if (khqr != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => _copyToClipboard(khqr.qrString, 'KHQR String'),
                          icon: const Icon(Icons.copy_rounded, size: 14),
                          label: const Text('Copy KHQR', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
                        ),
                        if (khqr.deeplink != null && khqr.deeplink!.isNotEmpty) ...[
                          const Text('•', style: TextStyle(color: Colors.grey)),
                          TextButton.icon(
                            onPressed: () => _copyToClipboard(khqr.deeplink!, 'Deep Link'),
                            icon: const Icon(Icons.link_rounded, size: 14),
                            label: const Text('Copy Link', style: TextStyle(fontSize: 11)),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Instructional text
            const Text(
              'Scan with Bakong App or ANY Cambodian Banking App\n(ACLEDA, Wing, Canadia, Sathapana, etc.)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),

            // Secondary action: Check Status manually
            if (canSimulate && _paymentStatus != KhqrPaymentStatus.success) ...[
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isProcessing ? null : _checkPaymentStatusManually,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('I Have Paid (Check Status Now)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Action Buttons: Cancel & Simulate Payment Button
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
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
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
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
                          ? 'Checking Status...'
                          : (_paymentStatus == KhqrPaymentStatus.success
                              ? 'Confirmed!'
                              : (canSimulate ? 'Simulate Approval' : 'I Have Paid')),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: _isProcessing || _paymentStatus == KhqrPaymentStatus.success || khqr == null
                        ? null
                        : (canSimulate ? _simulatePaymentApproval : _checkPaymentStatusManually),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
