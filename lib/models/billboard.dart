import 'package:cloud_firestore/cloud_firestore.dart';

class Billboard {
  final String id;
  final String location;
  final String description;
  final String municipalityId;
  final double width;
  final double height;
  final String status; // 'available', 'auction', 'rented'
  final DateTime createdAt;
  final DateTime? auctionEndDate;
  final double? currentBid;
  final String? currentBidderId;
  final double minimumBidIncrement;
  final double minimumPrice;
  final String? imageUrl;
  final double latitude;
  final double longitude;

  Billboard({
    required this.id,
    required this.location,
    required this.description,
    required this.municipalityId,
    required this.width,
    required this.height,
    required this.status,
    required this.createdAt,
    this.auctionEndDate,
    this.currentBid,
    this.currentBidderId,
    this.minimumBidIncrement = 1000.0,
    this.minimumPrice = 0.0,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
  });

  factory Billboard.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Billboard(
      id: doc.id,
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      municipalityId: data['municipalityId'] ?? '',
      width: (data['width'] ?? 0.0).toDouble(),
      height: (data['height'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'available',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      auctionEndDate: data['auctionEndDate'] != null 
          ? (data['auctionEndDate'] as Timestamp).toDate()
          : null,
      currentBid: (data['currentBid'] ?? 0.0).toDouble(),
      currentBidderId: data['currentBidderId'],
      minimumBidIncrement: (data['minimumBidIncrement'] ?? 1000.0).toDouble(),
      minimumPrice: (data['minimumPrice'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'description': description,
      'municipalityId': municipalityId,
      'width': width,
      'height': height,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'auctionEndDate': auctionEndDate != null 
          ? Timestamp.fromDate(auctionEndDate!)
          : null,
      'currentBid': currentBid,
      'currentBidderId': currentBidderId,
      'minimumBidIncrement': minimumBidIncrement,
      'minimumPrice': minimumPrice,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Billboard.fromMap(Map<String, dynamic> map) {
    return Billboard(
      id: map['id'] as String,
      municipalityId: map['municipalityId'] as String,
      location: map['location'] as String,
      description: map['description'] as String,
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String?,
      status: map['status'] as String,
      minimumBidIncrement: (map['minimumBidIncrement'] as num).toDouble(),
      minimumPrice: (map['minimumPrice'] as num).toDouble(),
      currentBid: (map['currentBid'] as num?)?.toDouble(),
      auctionEndDate: map['auctionEndDate'] != null 
          ? (map['auctionEndDate'] as Timestamp).toDate()
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }
} 