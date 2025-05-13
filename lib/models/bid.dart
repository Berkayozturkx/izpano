import 'package:cloud_firestore/cloud_firestore.dart';

class Bid {
  final String id;
  final String billboardId;
  final String companyId;
  final double amount;
  final String status; // 'active', 'won', 'lost', 'cancelled'
  final DateTime createdAt;
  final DateTime? updatedAt;

  Bid({
    required this.id,
    required this.billboardId,
    required this.companyId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Bid.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Bid(
      id: doc.id,
      billboardId: data['billboardId'] ?? '',
      companyId: data['companyId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'billboardId': billboardId,
      'companyId': companyId,
      'amount': amount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null 
          ? Timestamp.fromDate(updatedAt!)
          : null,
    };
  }
} 