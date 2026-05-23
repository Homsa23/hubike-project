import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool _isScanning = true;
  bool _isProcessing = false;
  MobileScannerController controller = MobileScannerController();

  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'default',
      );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_isScanning || _isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? participationId = barcodes.first.rawValue;
    if (participationId == null || participationId.isEmpty) return;

    // Stop scanning immediately to prevent duplicate reads
    setState(() {
      _isProcessing = true;
    });
    await controller.stop();

    // Process the participation ID
    await _validateTicket(participationId);
  }

  Future<void> _validateTicket(String participationId) async {
    try {
      // Query the participation collection
      final docSnapshot = await _firestore
          .collection('participation')
          .doc(participationId)
          .get();

      if (!docSnapshot.exists) {
        _showResult(
          success: false,
          title: 'Invalid Ticket',
          message: 'This ticket does not exist in our system.',
        );
        return;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      final bool isPresent = data['ispresent'] as bool? ?? false;

      if (isPresent) {
        // Already validated
        _showResult(
          success: false,
          title: 'Already Validated',
          message: 'This ticket has already been scanned and validated.',
        );
        return;
      }

      // Extract data from participation document
      final participationData = docSnapshot.data() as Map<String, dynamic>;
      final String userId = participationData['userId'] as String? ?? '';
      final String eventId = participationData['eventId'] as String? ?? '';

      // Fetch event data and check if it's ongoing
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        _showResult(
          success: false,
          title: 'Event Not Found',
          message: 'The event for this ticket no longer exists.',
        );
        return;
      }

      final eventDataMap = eventDoc.data() as Map<String, dynamic>;
      final eventDate = (eventDataMap['date'] as Timestamp).toDate();
      final isOngoing = DateTime.now().isAfter(eventDate) || DateTime.now().isAtSameMomentAs(eventDate);

      if (!isOngoing) {
        _showResult(
          success: false,
          title: 'Not Allowed',
          message: 'You can only scan tickets and assign coins while the event is ongoing.',
        );
        return;
      }

      final int rewardAmount = eventDataMap['coinsToEarn'] as int? ?? 0;

      // Create a WriteBatch for atomic operations
      final batch = _firestore.batch();

      // Update participation document (the receipt)
      batch.update(_firestore.collection('participation').doc(participationId), {
        'ispresent': true,
        'status': 'Completed',
        'validated_at': FieldValue.serverTimestamp(),
        'winnedCoins': rewardAmount,
      });

      // Update user document (the wallet)
      batch.update(_firestore.collection('user').doc(userId), {
        'coins': FieldValue.increment(rewardAmount),
      });

      // Commit all changes atomically
      await batch.commit();

      _showResult(
        success: true,
        title: 'Ticket Validated!',
        message: '$rewardAmount coins unlocked for this rider.',
      );
    } on FirebaseException catch (e) {
      _showResult(
        success: false,
        title: 'Database Error',
        message: 'Failed to validate ticket: ${e.message}',
      );
    } catch (e) {
      _showResult(
        success: false,
        title: 'Error',
        message: 'An unexpected error occurred: $e',
      );
    }
  }

  void _showResult({
    required bool success,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: success ? const Color(0xFF39FF14) : Colors.red,
            width: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: success
                    ? const Color(0xFF39FF14).withOpacity(0.15)
                    : Colors.red.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                size: 64,
                color: success ? const Color(0xFF39FF14) : Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                color: success ? const Color(0xFF39FF14) : Colors.red,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _resetScanner();
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Another Ticket'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39FF14),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Return to Dashboard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _isProcessing = false;
    });
    controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Scan Rider Ticket',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
            fit: BoxFit.cover,
          ),

          // Dark overlay with scanning frame
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: ScannerOverlay(),
          ),

          // Scanning instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF39FF14).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF39FF14).withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.center_focus_strong,
                        color: Color(0xFF39FF14),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Position QR code within frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF39FF14),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Validating ticket...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom painter for the scanning overlay
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.75;
    final scanAreaLeft = (size.width - scanAreaSize) / 2;
    final scanAreaTop = (size.height - scanAreaSize) / 2 - 50;

    // Draw dark overlay with cutout
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(Rect.fromLTWH(
        scanAreaLeft,
        scanAreaTop,
        scanAreaSize,
        scanAreaSize,
      ));
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Draw corner markers
    final cornerPaint = Paint()
      ..color = const Color(0xFF39FF14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerLength = scanAreaSize * 0.15;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanAreaLeft, scanAreaTop + cornerLength)
        ..lineTo(scanAreaLeft, scanAreaTop)
        ..lineTo(scanAreaLeft + cornerLength, scanAreaTop),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanAreaLeft + scanAreaSize - cornerLength, scanAreaTop)
        ..lineTo(scanAreaLeft + scanAreaSize, scanAreaTop)
        ..lineTo(scanAreaLeft + scanAreaSize, scanAreaTop + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanAreaLeft, scanAreaTop + scanAreaSize - cornerLength)
        ..lineTo(scanAreaLeft, scanAreaTop + scanAreaSize)
        ..lineTo(scanAreaLeft + cornerLength, scanAreaTop + scanAreaSize),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(
            scanAreaLeft + scanAreaSize - cornerLength, scanAreaTop + scanAreaSize)
        ..lineTo(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize)
        ..lineTo(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize - cornerLength),
      cornerPaint,
    );

    // Draw scanning line (animated effect)
    final scanLinePaint = Paint()
      ..color = const Color(0xFF39FF14).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final scanLineY = scanAreaTop + (scanAreaSize * 0.5);
    canvas.drawLine(
      Offset(scanAreaLeft + 10, scanLineY),
      Offset(scanAreaLeft + scanAreaSize - 10, scanLineY),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
