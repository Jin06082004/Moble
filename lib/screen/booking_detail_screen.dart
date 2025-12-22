import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/Models/booking_model.dart';
import '../database/Models/room_model.dart';
import 'review_screen.dart';

class BookingDetailScreen extends StatelessWidget {
  final BookingModel booking;
  final RoomModel room;

  const BookingDetailScreen({
    super.key,
    required this.booking,
    required this.room,
  });

  Future<void> _cancelBooking(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đặt phòng'),
        content: const Text('Bạn có chắc chắn muốn hủy đặt phòng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Có'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(booking.id)
            .update({
              'status': BookingStatus.cancelled.name,
              'cancelledAt': Timestamp.now(),
              'updatedAt': Timestamp.now(),
            });

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã hủy đặt phòng')));
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đặt phòng')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Room Image
            if (room.images.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  room.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.hotel, size: 64),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room Name and Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          room.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _StatusChip(status: booking.status),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Booking Info
                  const Text(
                    'Thông tin đặt phòng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    icon: Icons.login,
                    label: 'Ngày nhận phòng',
                    value:
                        '${booking.checkInDate.day}/${booking.checkInDate.month}/${booking.checkInDate.year}',
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.logout,
                    label: 'Ngày trả phòng',
                    value:
                        '${booking.checkOutDate.day}/${booking.checkOutDate.month}/${booking.checkOutDate.year}',
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.people,
                    label: 'Số khách',
                    value: '${booking.numberOfGuests}',
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    icon: Icons.nightlight,
                    label: 'Số đêm',
                    value: '${booking.nights}',
                  ),
                  if (booking.specialRequests != null) ...[
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.note,
                      label: 'Yêu cầu đặc biệt',
                      value: booking.specialRequests!,
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Payment Info
                  const Text(
                    'Thông tin thanh toán',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
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
                              '${room.formattedPrice} x ${booking.nights} đêm',
                            ),
                            Text(
                              booking.formattedTotalPrice,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng cộng',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              booking.formattedTotalPrice,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Trạng thái thanh toán'),
                            _PaymentStatusChip(status: booking.paymentStatus),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Actions
                  if (booking.status == BookingStatus.pending ||
                      booking.status == BookingStatus.confirmed)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _cancelBooking(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Hủy đặt phòng'),
                      ),
                    ),
                  if (booking.status == BookingStatus.checkedOut) ...[
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('reviews')
                          .where('bookingId', isEqualTo: booking.id)
                          .where('userId', isEqualTo: booking.userId)
                          .limit(1)
                          .get(),
                      builder: (context, snapshot) {
                        final hasReviewed =
                            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                        if (hasReviewed) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Bạn đã đánh giá phòng này',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        }

                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ReviewScreen(
                                    booking: booking,
                                    room: room,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Đánh giá phòng'),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final BookingStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        label = 'Đang chờ';
        break;
      case BookingStatus.confirmed:
        color = Colors.blue;
        label = 'Đã xác nhận';
        break;
      case BookingStatus.checkedIn:
        color = Colors.green;
        label = 'Đã nhận phòng';
        break;
      case BookingStatus.checkedOut:
        color = Colors.grey;
        label = 'Đã trả phòng';
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        label = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PaymentStatusChip extends StatelessWidget {
  final PaymentStatus status;

  const _PaymentStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case PaymentStatus.pending:
        color = Colors.orange;
        label = 'Chờ thanh toán';
        break;
      case PaymentStatus.partiallyPaid:
        color = Colors.blue;
        label = 'Đã cọc';
        break;
      case PaymentStatus.paid:
        color = Colors.green;
        label = 'Đã thanh toán';
        break;
      case PaymentStatus.refunded:
        color = Colors.grey;
        label = 'Đã hoàn tiền';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
