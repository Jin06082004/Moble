import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../database/Models/booking_model.dart';
import '../../database/Models/room_model.dart';
import '../../database/Models/user_model.dart';
import '../../database/Models/payment_model.dart' as payment;

class AdminBookingDetailScreen extends StatefulWidget {
  final BookingModel booking;
  final RoomModel room;

  const AdminBookingDetailScreen({
    super.key,
    required this.booking,
    required this.room,
  });

  @override
  State<AdminBookingDetailScreen> createState() =>
      _AdminBookingDetailScreenState();
}

class _AdminBookingDetailScreenState extends State<AdminBookingDetailScreen> {
  late BookingModel _currentBooking;
  UserModel? _user;
  payment.PaymentModel? _payment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      // Load user info
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.booking.userId)
          .get();
      if (userDoc.exists) {
        _user = UserModel.fromFirestore(userDoc);
      }

      // Load payment info
      final paymentQuery = await FirebaseFirestore.instance
          .collection('payments')
          .where('bookingId', isEqualTo: widget.booking.id)
          .limit(1)
          .get();
      if (paymentQuery.docs.isNotEmpty) {
        _payment = payment.PaymentModel.fromFirestore(paymentQuery.docs.first);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBookingStatus(BookingStatus newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text(
          'Cập nhật trạng thái thành "${_getStatusLabel(newStatus)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.booking.id)
          .update({'status': newStatus.name, 'updatedAt': Timestamp.now()});

      // Update room status if needed
      if (newStatus == BookingStatus.checkedIn) {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.room.id)
            .update({'status': RoomStatus.occupied.name});
      } else if (newStatus == BookingStatus.checkedOut ||
          newStatus == BookingStatus.cancelled) {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.room.id)
            .update({'status': RoomStatus.available.name});
      }

      setState(() {
        _currentBooking = _currentBooking.copyWith(status: newStatus);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã cập nhật trạng thái')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _updatePaymentStatus(payment.PaymentStatus newStatus) async {
    if (_payment == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(_payment!.id)
          .update({'status': newStatus.name, 'updatedAt': Timestamp.now()});

      // Update booking paymentStatus (convert to BookingModel's PaymentStatus)
      final bookingPaymentStatus = newStatus == payment.PaymentStatus.completed
          ? PaymentStatus.paid
          : PaymentStatus.pending;

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.booking.id)
          .update({
            'paymentStatus': bookingPaymentStatus.name,
            'updatedAt': Timestamp.now(),
          });

      setState(() {
        _payment = _payment!.copyWith(status: newStatus);
        _currentBooking = _currentBooking.copyWith(
          paymentStatus: bookingPaymentStatus,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật trạng thái thanh toán')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _deleteBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa đặt phòng'),
        content: const Text(
          'Bạn có chắc chắn muốn XÓA đặt phòng này?\nHành động này không thể hoàn tác!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Delete booking
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.booking.id)
          .delete();

      // Delete payment if exists
      if (_payment != null) {
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(_payment!.id)
            .delete();
      }

      // Update room status to available
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.room.id)
          .update({'status': RoomStatus.available.name});

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa đặt phòng')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đặt phòng'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_currentBooking.status != BookingStatus.checkedOut &&
              _currentBooking.status != BookingStatus.cancelled)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteBooking();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Xóa đặt phòng',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Trạng thái:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              _StatusChip(status: _currentBooking.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ID: ${widget.booking.id}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer Info
                  _SectionHeader(title: 'Thông tin khách hàng'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _user != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoRow(
                                  icon: Icons.person,
                                  label: 'Họ tên',
                                  value: _user!.fullName,
                                ),
                                const SizedBox(height: 8),
                                _InfoRow(
                                  icon: Icons.email,
                                  label: 'Email',
                                  value: _user!.email,
                                ),
                                const SizedBox(height: 8),
                                _InfoRow(
                                  icon: Icons.phone,
                                  label: 'Điện thoại',
                                  value: _user!.phoneNumber,
                                ),
                              ],
                            )
                          : const Text('Đang tải...'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Room Info
                  _SectionHeader(title: 'Thông tin phòng'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.room.images.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.room.images.first,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            widget.room.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(widget.room.description),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Booking Details
                  _SectionHeader(title: 'Chi tiết đặt phòng'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.calendar_today,
                            label: 'Nhận phòng',
                            value:
                                '${_currentBooking.checkInDate.day}/${_currentBooking.checkInDate.month}/${_currentBooking.checkInDate.year}',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.event,
                            label: 'Trả phòng',
                            value:
                                '${_currentBooking.checkOutDate.day}/${_currentBooking.checkOutDate.month}/${_currentBooking.checkOutDate.year}',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.nightlight_round,
                            label: 'Số đêm',
                            value:
                                '${_currentBooking.checkOutDate.difference(_currentBooking.checkInDate).inDays}',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.people,
                            label: 'Số khách',
                            value: '${_currentBooking.numberOfGuests}',
                          ),
                          if (_currentBooking.specialRequests != null) ...[
                            const Divider(height: 24),
                            _InfoRow(
                              icon: Icons.notes,
                              label: 'Yêu cầu đặc biệt',
                              value: _currentBooking.specialRequests!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Info
                  _SectionHeader(title: 'Thông tin thanh toán'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tổng tiền:'),
                              Text(
                                _currentBooking.formattedTotalPrice,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Trạng thái:'),
                              _PaymentStatusChip(
                                status:
                                    _payment?.status ??
                                    payment.PaymentStatus.pending,
                              ),
                            ],
                          ),
                          if (_payment != null) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.payment,
                              label: 'Phương thức',
                              value: _getPaymentMethodLabel(_payment!.method),
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.receipt,
                              label: 'Mã giao dịch',
                              value: _payment!.transactionId ?? 'N/A',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (_currentBooking.status != BookingStatus.checkedOut &&
                      _currentBooking.status != BookingStatus.cancelled)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_currentBooking.status ==
                            BookingStatus.pending) ...[
                          ElevatedButton.icon(
                            onPressed: () =>
                                _updateBookingStatus(BookingStatus.confirmed),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Xác nhận đặt phòng'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _updateBookingStatus(BookingStatus.cancelled),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Từ chối'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                        if (_currentBooking.status ==
                            BookingStatus.confirmed) ...[
                          ElevatedButton.icon(
                            onPressed: () =>
                                _updateBookingStatus(BookingStatus.checkedIn),
                            icon: const Icon(Icons.login),
                            label: const Text('Check-in'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _updateBookingStatus(BookingStatus.cancelled),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Hủy đặt phòng'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                        if (_currentBooking.status ==
                            BookingStatus.checkedIn) ...[
                          ElevatedButton.icon(
                            onPressed: () =>
                                _updateBookingStatus(BookingStatus.checkedOut),
                            icon: const Icon(Icons.logout),
                            label: const Text('Check-out'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                        if (_payment != null &&
                            _payment!.status ==
                                payment.PaymentStatus.pending) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => _updatePaymentStatus(
                              payment.PaymentStatus.completed,
                            ),
                            icon: const Icon(Icons.payment),
                            label: const Text('Xác nhận thanh toán'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  String _getStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Chờ xử lý';
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.checkedIn:
        return 'Đang ở';
      case BookingStatus.checkedOut:
        return 'Đã trả';
      case BookingStatus.cancelled:
        return 'Đã hủy';
    }
  }

  String _getPaymentMethodLabel(payment.PaymentMethod method) {
    switch (method) {
      case payment.PaymentMethod.cash:
        return 'Tiền mặt';
      case payment.PaymentMethod.creditCard:
        return 'Thẻ tín dụng';
      case payment.PaymentMethod.debitCard:
        return 'Thẻ ghi nợ';
      case payment.PaymentMethod.bankTransfer:
        return 'Chuyển khoản';
      case payment.PaymentMethod.momo:
        return 'MoMo';
      case payment.PaymentMethod.zalopay:
        return 'ZaloPay';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(label, style: TextStyle(color: Colors.grey[600])),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
            textAlign: TextAlign.end,
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

class _PaymentStatusChip extends StatelessWidget {
  final payment.PaymentStatus status;

  const _PaymentStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    switch (status) {
      case payment.PaymentStatus.pending:
        color = Colors.orange;
        label = 'Chờ thanh toán';
        break;
      case payment.PaymentStatus.processing:
        color = Colors.blue;
        label = 'Đang xử lý';
        break;
      case payment.PaymentStatus.completed:
        color = Colors.green;
        label = 'Đã thanh toán';
        break;
      case payment.PaymentStatus.failed:
        color = Colors.red;
        label = 'Thất bại';
        break;
      case payment.PaymentStatus.refunded:
        color = Colors.purple;
        label = 'Đã hoàn tiền';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
