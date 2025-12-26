import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/Models/room_model.dart';
import '../database/Models/booking_model.dart';
import '../database/Models/user_model.dart';
import '../services/email_service.dart';
import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final RoomModel room;

  const BookingScreen({super.key, required this.room});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _numberOfGuests = 1;
  final _specialRequestsController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  int get _numberOfNights {
    if (_checkInDate == null || _checkOutDate == null) return 0;
    return _checkOutDate!.difference(_checkInDate!).inDays;
  }

  double get _totalPrice {
    return _numberOfNights * widget.room.pricePerNight;
  }

  Future<void> _selectCheckInDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Chọn ngày nhận phòng',
    );

    if (picked != null) {
      setState(() {
        _checkInDate = picked;
        // Reset checkout date if it's before check-in
        if (_checkOutDate != null && _checkOutDate!.isBefore(picked)) {
          _checkOutDate = null;
        }
      });
    }
  }

  Future<void> _selectCheckOutDate() async {
    if (_checkInDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày nhận phòng trước')),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate!.add(const Duration(days: 1)),
      firstDate: _checkInDate!.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Chọn ngày trả phòng',
    );

    if (picked != null) {
      setState(() => _checkOutDate = picked);
    }
  }

  Future<void> _createBooking() async {
    if (_checkInDate == null || _checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày nhận và trả phòng')),
      );
      return;
    }

    if (_numberOfGuests > widget.room.maxGuests) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Số khách tối đa: ${widget.room.maxGuests}')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final bookingRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc();

      final booking = BookingModel(
        id: bookingRef.id,
        userId: userId,
        roomId: widget.room.id,
        checkInDate: _checkInDate!,
        checkOutDate: _checkOutDate!,
        numberOfGuests: _numberOfGuests,
        totalPrice: _totalPrice,
        status: BookingStatus.pending,
        paymentStatus: PaymentStatus.pending,
        specialRequests: _specialRequestsController.text.isNotEmpty
            ? _specialRequestsController.text
            : null,
        createdAt: DateTime.now(),
      );

      await bookingRef.set(booking.toFirestore());

      // Lấy thông tin user để gửi email
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final user = UserModel.fromFirestore(userDoc);
        // Gửi email xác nhận đặt phòng (không chờ để không làm chậm UI)
        EmailService.sendBookingConfirmationEmail(
          recipientEmail: user.email,
          fullName: user.fullName,
          roomName: widget.room.name,
          checkInDate:
              '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}',
          checkOutDate:
              '${_checkOutDate!.day}/${_checkOutDate!.month}/${_checkOutDate!.year}',
          totalPrice: _totalPrice.toStringAsFixed(0),
        ).catchError((e) {
          print('Lỗi gửi email: $e');
        });
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentScreen(booking: booking, room: widget.room),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đặt phòng',
          style: TextStyle(
            color: Color(0xFF667eea),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF667eea)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Room Info Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
              shadowColor: const Color(0xFF667eea).withOpacity(0.08),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    if (widget.room.images.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.room.images.first,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 90,
                            height: 90,
                            color: Colors.grey[300],
                            child: const Icon(Icons.hotel),
                          ),
                        ),
                      ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.room.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF667eea),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${widget.room.formattedPrice}/đêm',
                            style: const TextStyle(
                              color: Color(0xFF764ba2),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Date Selection
            const Text(
              'Chọn ngày',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF667eea),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _DateSelector(
                    label: 'Nhận phòng',
                    date: _checkInDate,
                    onTap: _selectCheckInDate,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _DateSelector(
                    label: 'Trả phòng',
                    date: _checkOutDate,
                    onTap: _selectCheckOutDate,
                  ),
                ),
              ],
            ),
            if (_numberOfNights > 0) ...[
              const SizedBox(height: 10),
              Text(
                '$_numberOfNights đêm',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 28),
            // Number of Guests
            const Text(
              'Số lượng khách',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF667eea),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFF667eea).withOpacity(0.15)),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Khách (Tối đa: ${widget.room.maxGuests})',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Color(0xFF764ba2),
                        ),
                        onPressed: _numberOfGuests > 1
                            ? () {
                                setState(() => _numberOfGuests--);
                              }
                            : null,
                      ),
                      Text(
                        '$_numberOfGuests',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667eea),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Color(0xFF764ba2),
                        ),
                        onPressed: _numberOfGuests < widget.room.maxGuests
                            ? () {
                                setState(() => _numberOfGuests++);
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Special Requests
            const Text(
              'Yêu cầu đặc biệt (Tùy chọn)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF667eea),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _specialRequestsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Nhập yêu cầu đặc biệt của bạn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF667eea)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF764ba2),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Price Summary
            if (_numberOfNights > 0) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFe0e7ff), Color(0xFFf3e8ff)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(0xFF667eea).withOpacity(0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.room.formattedPrice} x $_numberOfNights đêm',
                          style: const TextStyle(
                            color: Color(0xFF667eea),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          RoomModel.formatPrice(_totalPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF764ba2),
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
                            color: Color(0xFF667eea),
                          ),
                        ),
                        Text(
                          RoomModel.formatPrice(_totalPrice),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF764ba2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
            // Book Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createBooking,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.zero,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Tiếp tục thanh toán',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateSelector({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF667eea).withOpacity(0.15)),
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              date != null
                  ? '${date!.day}/${date!.month}/${date!.year}'
                  : 'Chọn ngày',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: date != null ? const Color(0xFF667eea) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
