import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Thêm import này

class RoomModel {
  final String id;
  final String name;
  final String description;
  final RoomType type;
  final double pricePerNight;
  final int maxGuests;
  final int bedCount;
  final int bathroomCount;
  final double area; // in square meters
  final List<String> amenities;
  final List<String> images;
  final RoomStatus status;
  final String? floor;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RoomModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.pricePerNight,
    required this.maxGuests,
    required this.bedCount,
    required this.bathroomCount,
    required this.area,
    required this.amenities,
    required this.images,
    required this.status,
    this.floor,
    required this.createdAt,
    this.updatedAt,
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: RoomType.values.firstWhere(
        (e) => e.toString() == 'RoomType.${data['type']}',
        orElse: () => RoomType.standard,
      ),
      pricePerNight: (data['pricePerNight'] ?? 0).toDouble(),
      maxGuests: data['maxGuests'] ?? 1,
      bedCount: data['bedCount'] ?? 1,
      bathroomCount: data['bathroomCount'] ?? 1,
      area: (data['area'] ?? 0).toDouble(),
      amenities: List<String>.from(data['amenities'] ?? []),
      images: List<String>.from(data['images'] ?? []),
      status: RoomStatus.values.firstWhere(
        (e) => e.toString() == 'RoomStatus.${data['status']}',
        orElse: () => RoomStatus.available,
      ),
      floor: data['floor'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'pricePerNight': pricePerNight,
      'maxGuests': maxGuests,
      'bedCount': bedCount,
      'bathroomCount': bathroomCount,
      'area': area,
      'amenities': amenities,
      'images': images,
      'status': status.name,
      'floor': floor,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  RoomModel copyWith({
    String? name,
    String? description,
    RoomType? type,
    double? pricePerNight,
    int? maxGuests,
    int? bedCount,
    int? bathroomCount,
    double? area,
    List<String>? amenities,
    List<String>? images,
    RoomStatus? status,
    String? floor,
    DateTime? updatedAt,
  }) {
    return RoomModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      maxGuests: maxGuests ?? this.maxGuests,
      bedCount: bedCount ?? this.bedCount,
      bathroomCount: bathroomCount ?? this.bathroomCount,
      area: area ?? this.area,
      amenities: amenities ?? this.amenities,
      images: images ?? this.images,
      status: status ?? this.status,
      floor: floor ?? this.floor,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Thêm getter để format giá
  String get formattedPrice {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(pricePerNight)} VNĐ';
  }

  // Hoặc thêm method static để format bất kỳ số tiền nào
  static String formatPrice(double price) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price)} VNĐ';
  }
}

enum RoomType { standard, deluxe, suite, presidential }

enum RoomStatus { available, occupied, maintenance, reserved }
