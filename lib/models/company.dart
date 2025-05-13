import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String name;
  final String taxNumber;
  final String address;
  final String phoneNumber;
  final String status; // 'active', 'pending', 'blacklisted'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> favoriteBillboards;

  Company({
    required this.id,
    required this.name,
    required this.taxNumber,
    required this.address,
    required this.phoneNumber,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.favoriteBillboards = const [],
  });

  factory Company.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Company(
      id: doc.id,
      name: data['name'] ?? '',
      taxNumber: data['taxNumber'] ?? '',
      address: data['address'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      favoriteBillboards: List<String>.from(data['favoriteBillboards'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'taxNumber': taxNumber,
      'address': address,
      'phoneNumber': phoneNumber,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null 
          ? Timestamp.fromDate(updatedAt!)
          : null,
      'favoriteBillboards': favoriteBillboards,
    };
  }
} 