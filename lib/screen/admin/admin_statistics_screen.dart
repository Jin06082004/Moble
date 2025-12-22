import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database/Models/booking_model.dart';

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan hệ thống',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // Statistics Cards
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
            builder: (context, roomSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .snapshots(),
                builder: (context, bookingSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      final totalRooms = roomSnapshot.data?.docs.length ?? 0;
                      final totalBookings =
                          bookingSnapshot.data?.docs.length ?? 0;
                      final totalUsers = userSnapshot.data?.docs.length ?? 0;

                      final availableRooms =
                          roomSnapshot.data?.docs
                              .where(
                                (doc) =>
                                    (doc.data() as Map)['status'] ==
                                    'available',
                              )
                              .length ??
                          0;

                      final pendingBookings =
                          bookingSnapshot.data?.docs
                              .where(
                                (doc) =>
                                    (doc.data() as Map)['status'] == 'pending',
                              )
                              .length ??
                          0;

                      double totalRevenue = 0;
                      if (bookingSnapshot.hasData) {
                        for (var doc in bookingSnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          // Chỉ tính doanh thu từ các booking ở trạng thái Hoàn thành (checkedOut hoặc cancelled)
                          // VÀ đã thanh toán (paid, partiallyPaid, hoặc completed)
                          final status = data['status'];
                          final paymentStatus = data['paymentStatus'];

                          if ((status == 'checkedOut' ||
                                  status == 'cancelled') &&
                              (paymentStatus == 'paid' ||
                                  paymentStatus == 'partiallyPaid' ||
                                  paymentStatus == 'completed')) {
                            totalRevenue += (data['totalPrice'] ?? 0)
                                .toDouble();
                          }
                        }
                      }

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Tổng phòng',
                                  value: totalRooms.toString(),
                                  subtitle: '$availableRooms phòng trống',
                                  icon: Icons.hotel,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  title: 'Đặt phòng',
                                  value: totalBookings.toString(),
                                  subtitle: '$pendingBookings chờ xử lý',
                                  icon: Icons.book_online,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Người dùng',
                                  value: totalUsers.toString(),
                                  subtitle: 'Tổng tài khoản',
                                  icon: Icons.people,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  title: 'Doanh thu',
                                  value: BookingModel.formatPrice(totalRevenue),
                                  subtitle: 'Tổng thu nhập',
                                  icon: Icons.attach_money,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Đặt phòng gần đây',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final bookings = snapshot.data!.docs
                  .map((doc) => BookingModel.fromFirestore(doc))
                  .toList();

              if (bookings.isEmpty) {
                return const Center(child: Text('Chưa có đặt phòng nào'));
              }

              return Column(
                children: bookings
                    .map((booking) => _RecentBookingCard(booking: booking))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 32),
              // Không hiển thị value ở đây nếu là doanh thu (để hiển thị dưới)
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: title == 'Doanh thu' ? 18 : 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _RecentBookingCard extends StatelessWidget {
  final BookingModel booking;

  const _RecentBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(booking.status),
          child: Icon(_getStatusIcon(booking.status), color: Colors.white),
        ),
        title: Text('Booking #${booking.id.substring(0, 8)}'),
        subtitle: Text(
          '${booking.checkInDate.day}/${booking.checkInDate.month} - ${booking.checkOutDate.day}/${booking.checkOutDate.month}',
        ),
        trailing: Text(
          booking.formattedTotalPrice,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.checkedIn:
        return Colors.green;
      case BookingStatus.checkedOut:
        return Colors.grey;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.hourglass_empty;
      case BookingStatus.confirmed:
        return Icons.check;
      case BookingStatus.checkedIn:
        return Icons.login;
      case BookingStatus.checkedOut:
        return Icons.logout;
      case BookingStatus.cancelled:
        return Icons.cancel;
    }
  }
}
