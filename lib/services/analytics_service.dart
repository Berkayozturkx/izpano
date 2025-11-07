import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/billboard.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getMonthlyRevenue(String municipalityId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final querySnapshot = await _firestore
        .collection('billboards')
        .where('municipalityId', isEqualTo: municipalityId)
        .where('status', isEqualTo: 'rented')
        .where('auctionEndDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('auctionEndDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    double totalRevenue = 0;
    for (var doc in querySnapshot.docs) {
      final billboard = Billboard.fromFirestore(doc);
      totalRevenue += billboard.currentBid ?? 0;
    }

    return {
      'totalRevenue': totalRevenue,
      'billboardCount': querySnapshot.docs.length,
    };
  }

  Future<Map<String, dynamic>> getYearlyRevenue(String municipalityId) async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31);

    final querySnapshot = await _firestore
        .collection('billboards')
        .where('municipalityId', isEqualTo: municipalityId)
        .where('status', isEqualTo: 'rented')
        .where('auctionEndDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear))
        .where('auctionEndDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear))
        .get();

    double totalRevenue = 0;
    for (var doc in querySnapshot.docs) {
      final billboard = Billboard.fromFirestore(doc);
      totalRevenue += billboard.currentBid ?? 0;
    }

    return {
      'totalRevenue': totalRevenue,
      'billboardCount': querySnapshot.docs.length,
    };
  }

  Future<List<Map<String, dynamic>>> getBillboardAnalytics(String municipalityId) async {
    final querySnapshot = await _firestore
        .collection('billboards')
        .where('municipalityId', isEqualTo: municipalityId)
        .get();

    List<Map<String, dynamic>> analytics = [];
    for (var doc in querySnapshot.docs) {
      final billboard = Billboard.fromFirestore(doc);
      analytics.add({
        'location': billboard.location,
        'revenue': billboard.currentBid ?? 0,
        'status': billboard.status,
      });
    }

    return analytics;
  }

  Future<List<Map<String, dynamic>>> getAuctionAnalytics(String municipalityId) async {
    final querySnapshot = await _firestore
        .collection('billboards')
        .where('municipalityId', isEqualTo: municipalityId)
        .where('status', isEqualTo: 'rented')
        .get();

    List<Map<String, dynamic>> analytics = [];
    for (var doc in querySnapshot.docs) {
      final billboard = Billboard.fromFirestore(doc);
      analytics.add({
        'location': billboard.location,
        'finalBid': billboard.currentBid ?? 0,
        'endDate': billboard.auctionEndDate,
      });
    }

    return analytics;
  }
}