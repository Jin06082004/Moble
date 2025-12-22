import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingModel {
  final String id;
  final String userId;
  final String? roomId; // Nullable cho hotel bookings
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numberOfGuests;
  final double totalPrice;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String? specialRequests;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  // Hotel booking fields
  final String? hotelName;
  final String? hotelLocation;
  final double? hotelRating;
  final int? numberOfNights;
  final String? paymentMethod;

  BookingModel({
    required this.id,
    required this.userId,
    this.roomId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfGuests,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    this.specialRequests,
    required this.createdAt,
    this.updatedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.hotelName,
    this.hotelLocation,
    this.hotelRating,
    this.numberOfNights,
    this.paymentMethod,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      roomId: data['roomId'],
      checkInDate: (data['checkInDate'] as Timestamp).toDate(),
      checkOutDate: (data['checkOutDate'] as Timestamp).toDate(),
      numberOfGuests: data['numberOfGuests'] ?? 1,
      totalPrice: data['totalPrice'] != null
          ? (data['totalPrice'] as num).toDouble()
          : (data['estimatedPrice'] != null
                ? (data['estimatedPrice'] as num).toDouble()
                : 0.0),
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == 'BookingStatus.${data['status']}',
        orElse: () => BookingStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${data['paymentStatus']}',
        orElse: () => PaymentStatus.pending,
      ),
      specialRequests: data['specialRequests'] ?? data['notes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      cancellationReason: data['cancellationReason'],
      hotelName: data['hotelName'],
      hotelLocation: data['hotelLocation'],
      hotelRating: data['hotelRating'] != null
          ? (data['hotelRating'] as num).toDouble()
          : null,
      numberOfNights: data['numberOfNights'],
      paymentMethod: data['paymentMethod'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'roomId': roomId,
      'checkInDate': Timestamp.fromDate(checkInDate),
      'checkOutDate': Timestamp.fromDate(checkOutDate),
      'numberOfGuests': numberOfGuests,
      'totalPrice': totalPrice,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'specialRequests': specialRequests,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'cancelledAt': cancelledAt != null
          ? Timestamp.fromDate(cancelledAt!)
          : null,
      'cancellationReason': cancellationReason,
    };
  }

  // Getter để tính số đêm nếu field numberOfNights null
  int get nights {
    return numberOfNights ?? checkOutDate.difference(checkInDate).inDays;
  }

  // Getter để format tổng giá
  String get formattedTotalPrice {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(totalPrice)} VNĐ';
  }

  // Method static để format bất kỳ số tiền nào
  static String formatPrice(double price) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price)} VNĐ';
  }

  BookingModel copyWith({
    String? userId,
    String? roomId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? numberOfGuests,
    double? totalPrice,
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    String? specialRequests,
    DateTime? updatedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) {
    return BookingModel(
      id: id,
      userId: userId ?? this.userId,
      roomId: roomId ?? this.roomId,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      specialRequests: specialRequests ?? this.specialRequests,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}

enum BookingStatus { pending, confirmed, checkedIn, checkedOut, cancelled }

enum PaymentStatus { pending, partiallyPaid, paid, refunded }
