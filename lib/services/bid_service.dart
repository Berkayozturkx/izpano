import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bid.dart';

class BidService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'bids';

  // Yeni teklif oluşturma
  Future<String> createBid(Bid bid) async {
    DocumentReference docRef = await _firestore.collection(_collection).add(bid.toMap());
    return docRef.id;
  }

  // Teklif güncelleme
  Future<void> updateBid(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update(data);
  }

  // Şirketin aktif tekliflerini getirme
  Stream<List<Bid>> getActiveBidsByCompany(String companyId) {
    return _firestore
        .collection(_collection)
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Bid.fromFirestore(doc)).toList();
    });
  }

  // Şirketin kazandığı teklifleri getirme
  Stream<List<Bid>> getWonBidsByCompany(String companyId) {
    return _firestore
        .collection(_collection)
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: 'won')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Bid.fromFirestore(doc)).toList();
    });
  }

  // Panoya ait tüm teklifleri getirme
  Stream<List<Bid>> getBidsByBillboard(String billboardId) {
    return _firestore
        .collection(_collection)
        .where('billboardId', isEqualTo: billboardId)
        .orderBy('amount', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Bid.fromFirestore(doc)).toList();
    });
  }

  // Teklif durumunu güncelleme (onaylama/reddetme)
  Future<void> updateBidStatus(String bidId, String status) async {
    await _firestore.collection(_collection).doc(bidId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  // Teklifi iptal etme
  Future<void> cancelBid(String bidId) async {
    await _firestore.collection(_collection).doc(bidId).update({
      'status': 'cancelled',
      'updatedAt': Timestamp.now(),
    });
  }

  // Teklif geçmişini getirme
  Stream<List<Bid>> getBidHistory(String companyId) {
    return _firestore
        .collection(_collection)
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Bid.fromFirestore(doc)).toList();
    });
  }
} 