import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/Models/booking_model.dart' hide PaymentStatus;
import '../database/Models/room_model.dart';
import '../database/Models/payment_model.dart';
import '../database/Models/user_model.dart';
import '../services/email_service.dart';
import 'home_screen.dart';

class PaymentScreen extends StatefulWidget {
  final BookingModel booking;
  final RoomModel room;

  const PaymentScreen({super.key, required this.booking, required this.room});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  bool _isProcessing = false;

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final paymentRef = FirebaseFirestore.instance
          .collection('payments')
          .doc();

      // Create payment record
      final payment = PaymentModel(
        id: paymentRef.id,
        bookingId: widget.booking.id,
        userId: userId,
        amount: widget.booking.totalPrice,
        method: _selectedMethod,
        status: PaymentStatus.completed,
        transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
      );

      await paymentRef.set(payment.toFirestore());

      // Update booking status
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.booking.id)
          .update({
            'status': BookingStatus.confirmed.name,
            'paymentStatus': PaymentStatus.completed.name,
            'updatedAt': Timestamp.now(),
          });

      // Lấy thông tin user để gửi email
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final user = UserModel.fromFirestore(userDoc);
        // Gửi email xác nhận thanh toán (không chờ để không làm chậm UI)
        EmailService.sendPaymentConfirmationEmail(
          recipientEmail: user.email,
          fullName: user.fullName,
          roomName: widget.room.name,
          totalPrice: widget.booking.totalPrice.toStringAsFixed(0),
          transactionId: payment.transactionId ?? 'N/A',
        ).catchError((e) {
          print('Lỗi gửi email: $e');
        });
      }

      if (mounted) {
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Thành công!'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thanh toán thành công!'),
                SizedBox(height: 8),
                Text(
                  'Đặt phòng của bạn đã được xác nhận.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to home and clear stack
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Booking Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tóm tắt đặt phòng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        if (widget.room.images.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.room.images.first,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.hotel),
                              ),
                            ),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.room.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: 'Nhận phòng',
                                value:
                                    '${widget.booking.checkInDate.day}/${widget.booking.checkInDate.month}/${widget.booking.checkInDate.year}',
                              ),
                              const SizedBox(height: 4),
                              _InfoRow(
                                label: 'Trả phòng',
                                value:
                                    '${widget.booking.checkOutDate.day}/${widget.booking.checkOutDate.month}/${widget.booking.checkOutDate.year}',
                              ),
                              const SizedBox(height: 4),
                              _InfoRow(
                                label: 'Số khách',
                                value: '${widget.booking.numberOfGuests}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Payment Method Selection
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...PaymentMethod.values.map((method) {
              return _PaymentMethodTile(
                method: method,
                isSelected: _selectedMethod == method,
                onTap: () {
                  setState(() => _selectedMethod = method);
                },
              );
            }),
            const SizedBox(height: 24),
            // Price Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.room.pricePerNight.toStringAsFixed(0)} VNĐ x ${widget.booking.numberOfNights} đêm',
                      ),
                      Text(
                        '${widget.booking.totalPrice.toStringAsFixed(0)} VNĐ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng thanh toán',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.booking.totalPrice.toStringAsFixed(0)} VNĐ',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Payment Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Xác nhận thanh toán',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // Security Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Thông tin thanh toán của bạn được bảo mật',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Colors.blue[50] : null,
      ),
      child: ListTile(
        leading: Icon(
          _getMethodIcon(method),
          color: isSelected ? Colors.blue : Colors.grey[600],
        ),
        title: Text(
          _getMethodLabel(method),
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.debitCard:
        return Icons.credit_card;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.momo:
        return Icons.payment;
      case PaymentMethod.zalopay:
        return Icons.payment;
    }
  }

  String _getMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Tiền mặt';
      case PaymentMethod.creditCard:
        return 'Thẻ tín dụng';
      case PaymentMethod.debitCard:
        return 'Thẻ ghi nợ';
      case PaymentMethod.bankTransfer:
        return 'Chuyển khoản ngân hàng';
      case PaymentMethod.momo:
        return 'Ví MoMo';
      case PaymentMethod.zalopay:
        return 'Ví ZaloPay';
    }
  }
}
