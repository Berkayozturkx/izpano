import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/billboard.dart';

class BillboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'billboards';

  // Yeni pano ekleme
  Future<String> addBillboard(Billboard billboard) async {
    DocumentReference docRef = await _firestore.collection(_collection).add(billboard.toMap());
    return docRef.id;
  }

  // Pano güncelleme
  Future<void> updateBillboard(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update(data);
  }

  // Pano silme
  Future<void> deleteBillboard(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Belediyeye ait panoları getirme
  Stream<List<Billboard>> getBillboardsByMunicipality(String municipalityId) {
    return _firestore
        .collection(_collection)
        .where('municipalityId', isEqualTo: municipalityId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Billboard.fromFirestore(doc)).toList();
    });
  }

  // Açık artırmadaki panoları getirme
  Stream<List<Billboard>> getActiveAuctions() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'auction')
        .where('auctionEndDate', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Billboard.fromFirestore(doc)).toList();
    });
  }

  // Tek bir pano detayını getirme
  Future<Billboard?> getBillboard(String id) async {
    DocumentSnapshot doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return Billboard.fromFirestore(doc);
    }
    return null;
  }

  // Açık artırma başlatma
  Future<void> startAuction(String billboardId, DateTime endDate, double minimumBid) async {
    await _firestore.collection(_collection).doc(billboardId).update({
      'status': 'auction',
      'auctionEndDate': Timestamp.fromDate(endDate),
      'currentBid': minimumBid,
      'minimumBidIncrement': 1000.0,
    });
  }

  // Teklif verme
  Future<void> placeBid(String billboardId, String companyId, double amount) async {
    DocumentReference docRef = _firestore.collection(_collection).doc(billboardId);
    
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot doc = await transaction.get(docRef);
      if (!doc.exists) {
        throw Exception('Pano bulunamadı!');
      }

      Billboard billboard = Billboard.fromFirestore(doc);
      if (billboard.status != 'auction') {
        throw Exception('Bu pano için açık artırma aktif değil!');
      }

      if (billboard.auctionEndDate!.isBefore(DateTime.now())) {
        throw Exception('Açık artırma süresi dolmuş!');
      }

      if (amount <= (billboard.currentBid ?? 0)) {
        throw Exception('Teklif mevcut tekliften yüksek olmalıdır!');
      }

      if (amount < (billboard.currentBid ?? 0) + billboard.minimumBidIncrement) {
        throw Exception('Minimum artış tutarı: ₺${billboard.minimumBidIncrement}');
      }

      transaction.update(docRef, {
        'currentBid': amount,
        'currentBidderId': companyId,
      });
    });
  }
} 