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
    };
  }
} 