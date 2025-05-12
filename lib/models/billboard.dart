import 'package:cloud_firestore/cloud_firestore.dart';

class Billboard {
  final String id;
  final String location;
  final double width;
  final double height;
  final String technicalSpecs;
  final double minPrice;
  final double maxPrice;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Billboard({
    required this.id,
    required this.location,
    required this.width,
    required this.height,
    required this.technicalSpecs,
    required this.minPrice,
    required this.maxPrice,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Billboard.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Billboard(
      id: doc.id,
      location: data['location'] ?? '',
      width: (data['width'] ?? 0.0).toDouble(),
      height: (data['height'] ?? 0.0).toDouble(),
      technicalSpecs: data['technicalSpecs'] ?? '',
      minPrice: (data['minPrice'] ?? 0.0).toDouble(),
      maxPrice: (data['maxPrice'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'width': width,
      'height': height,
      'technicalSpecs': technicalSpecs,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
} 