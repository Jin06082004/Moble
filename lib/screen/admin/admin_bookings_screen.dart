import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database/Models/booking_model.dart';
import '../../database/Models/room_model.dart';
import 'admin_booking_detail_screen.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Chờ xử lý'),
            Tab(text: 'Đã xác nhận'),
            Tab(text: 'Đang ở'),
            Tab(text: 'Hoàn thành'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _BookingsTab(status: [BookingStatus.pending]),
              _BookingsTab(status: [BookingStatus.confirmed]),
              _BookingsTab(status: [BookingStatus.checkedIn]),
              _BookingsTab(
                status: [BookingStatus.checkedOut, BookingStatus.cancelled],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookingsTab extends StatelessWidget {
  final List<BookingStatus> status;

  const _BookingsTab({required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .where((booking) => status.contains(booking.status))
            .toList();

        if (bookings.isEmpty) {
          return const Center(child: Text('Không có đặt phòng nào'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return _AdminBookingCard(booking: bookings[index]);
          },
        );
      },
    );
  }
}

class _AdminBookingCard extends StatelessWidget {
  final BookingModel booking;

  const _AdminBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem đây có phải là hotel booking không
    if (booking.roomId == null) {
      // Đây là hotel booking, hiển thị card cho hotel
      return _buildHotelBookingCard(context);
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('rooms')
          .doc(booking.roomId)
          .get(),
      builder: (context, roomSnapshot) {
        if (!roomSnapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Kiểm tra xem document có tồn tại không
        if (!roomSnapshot.data!.exists) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('Phòng không tồn tại')),
            ),
          );
        }

        final room = RoomModel.fromFirestore(roomSnapshot.data!);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AdminBookingDetailScreen(booking: booking, room: room),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Booking #${booking.id.substring(0, 8)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusChip(status: booking.status),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${booking.checkInDate.day}/${booking.checkInDate.month} - ${booking.checkOutDate.day}/${booking.checkOutDate.month}/${booking.checkOutDate.year}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16),
                      const SizedBox(width: 8),
                      Text('${booking.numberOfGuests} khách'),
                      const Spacer(),
                      Text(
                        booking.formattedTotalPrice,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (booking.status == BookingStatus.pending) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateBookingStatus(
                              context,
                              booking,
                              BookingStatus.cancelled,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Từ chối'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateBookingStatus(
                              context,
                              booking,
                              BookingStatus.confirmed,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Xác nhận'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateBookingStatus(
    BuildContext context,
    BookingModel booking,
    BookingStatus newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id)
          .update({'status': newStatus.name});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật trạng thái đặt phòng')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Widget _buildHotelBookingCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Có thể thêm màn hình chi tiết hotel booking sau
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chi tiết đặt khách sạn')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.hotelName ?? 'Khách sạn',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Booking #${booking.id.substring(0, 8)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: booking.status),
                ],
              ),
              const Divider(height: 24),
              if (booking.hotelLocation != null) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.hotelLocation!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${booking.checkInDate.day}/${booking.checkInDate.month} - ${booking.checkOutDate.day}/${booking.checkOutDate.month}/${booking.checkOutDate.year}',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people, size: 16),
                  const SizedBox(width: 8),
                  Text('${booking.numberOfGuests} khách'),
                  const SizedBox(width: 16),
                  const Icon(Icons.nightlight, size: 16),
                  const SizedBox(width: 8),
                  Text('${booking.nights} đêm'),
                  const Spacer(),
                  Text(
                    booking.formattedTotalPrice,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              if (booking.status == BookingStatus.pending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateBookingStatus(
                          context,
                          booking,
                          BookingStatus.cancelled,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Từ chối'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateBookingStatus(
                          context,
                          booking,
                          BookingStatus.confirmed,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Xác nhận'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
        label = 'Chờ xử lý';
        break;
      case BookingStatus.confirmed:
        color = Colors.blue;
        label = 'Đã xác nhận';
        break;
      case BookingStatus.checkedIn:
        color = Colors.green;
        label = 'Đang ở';
        break;
      case BookingStatus.checkedOut:
        color = Colors.grey;
        label = 'Đã trả';
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        label = 'Đã hủy';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
