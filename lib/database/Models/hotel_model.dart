import 'package:cloud_firestore/cloud_firestore.dart';

class Hotel {
  final String name;
  final String description;
  final String location;
  final double rating;
  final String priceRange;
  final List<String> amenities;
  final String imageUrl;
  final double latitude;
  final double longitude;

  Hotel({
    required this.name,
    required this.description,
    required this.location,
    required this.rating,
    required this.priceRange,
    required this.amenities,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      priceRange: json['priceRange'] ?? '',
      amenities: List<String>.from(json['amenities'] ?? []),
      imageUrl: json['imageUrl'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  factory Hotel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Hotel.fromJson(data);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'location': location,
      'rating': rating,
      'priceRange': priceRange,
      'amenities': amenities,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
