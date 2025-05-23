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
    await _firestore.collection(_collection).doc(id).update({
      ...data,
      'updatedAt': Timestamp.now(),
    });
  }

  // Şirketin aktif tekliflerini getirme
  Stream<List<Bid>> getActiveBidsByCompany(String companyId) {
    return _firestore
        .collection(_collection)
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      // Her pano için en yüksek teklifi bul
      Map<String, Bid> highestBids = {};
      for (var doc in snapshot.docs) {
        final bid = Bid.fromFirestore(doc);
        if (!highestBids.containsKey(bid.billboardId) || 
            bid.amount > highestBids[bid.billboardId]!.amount) {
          highestBids[bid.billboardId] = bid;
        }
      }
      return highestBids.values.toList();
    });
  }

  // Şirketin kazandığı teklifleri getirme
  Stream<List<Bid>> getWonBidsByCompany(String companyId) {
    return _firestore
        .collection(_collection)
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: 'won')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      // Her pano için kazanılan en yüksek teklifi bul
      Map<String, Bid> highestWonBids = {};
      for (var doc in snapshot.docs) {
        final bid = Bid.fromFirestore(doc);
        if (!highestWonBids.containsKey(bid.billboardId) || 
            bid.amount > highestWonBids[bid.billboardId]!.amount) {
          highestWonBids[bid.billboardId] = bid;
        }
      }
      return highestWonBids.values.toList();
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