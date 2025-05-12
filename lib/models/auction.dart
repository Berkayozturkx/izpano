import 'package:cloud_firestore/cloud_firestore.dart';

class Auction {
  final String id;
  final String billboardId;
  final String billboardLocation;
  final double minimumBid;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? winningCompanyId;
  final String? winningCompanyName;
  final double? winningBid;
  final DateTime createdAt;
  final DateTime updatedAt;

  Auction({
    required this.id,
    required this.billboardId,
    required this.billboardLocation,
    required this.minimumBid,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.winningCompanyId,
    this.winningCompanyName,
    this.winningBid,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Auction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Auction(
      id: doc.id,
      billboardId: data['billboardId'] ?? '',
      billboardLocation: data['billboardLocation'] ?? '',
      minimumBid: (data['minimumBid'] ?? 0.0).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      winningCompanyId: data['winningCompanyId'],
      winningCompanyName: data['winningCompanyName'],
      winningBid: data['winningBid']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'billboardId': billboardId,
      'billboardLocation': billboardLocation,
      'minimumBid': minimumBid,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'winningCompanyId': winningCompanyId,
      'winningCompanyName': winningCompanyName,
      'winningBid': winningBid,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class Bid {
  final String id;
  final String auctionId;
  final String companyId;
  final String companyName;
  final double amount;
  final DateTime createdAt;

  Bid({
    required this.id,
    required this.auctionId,
    required this.companyId,
    required this.companyName,
    required this.amount,
    required this.createdAt,
  });

  factory Bid.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Bid(
      id: doc.id,
      auctionId: data['auctionId'] ?? '',
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'auctionId': auctionId,
      'companyId': companyId,
      'companyName': companyName,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
} 