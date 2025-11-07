import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/billboard.dart';
import '../models/bid.dart';

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
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Billboard.fromFirestore(doc))
          .where((billboard) => 
              billboard.auctionEndDate != null && 
              billboard.auctionEndDate!.isAfter(DateTime.now()))
          .toList();
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

  // Açık artırma başlat
  Future<void> startAuction(String billboardId, DateTime endDate, double minimumBidIncrement, double minimumPrice) async {
    try {
      await _firestore.collection('billboards').doc(billboardId).update({
        'status': 'active',
        'auctionEndDate': Timestamp.fromDate(endDate),
        'minimumBidIncrement': minimumBidIncrement,
        'minimumPrice': minimumPrice,
        'currentBid': 0.0,
        'currentBidderId': null,
      });
    } catch (e) {
      print('Açık artırma başlatma hatası: $e');
      rethrow;
    }
  }

  // Açık artırmayı sonlandır
  Future<void> endAuction(String billboardId) async {
    try {
      final billboardDoc = await _firestore.collection('billboards').doc(billboardId).get();
      final billboard = Billboard.fromFirestore(billboardDoc);

      // Panoya ait tüm teklifleri getir
      final bidsSnapshot = await _firestore
          .collection('bids')
          .where('billboardId', isEqualTo: billboardId)
          .get();

      if (billboard.currentBidderId != null) {
        // Kazanan teklifi onayla
        await _firestore.collection('billboards').doc(billboardId).update({
          'status': 'rented',
        });

        // Kazanan teklifi güncelle
        for (var bidDoc in bidsSnapshot.docs) {
          final bid = Bid.fromFirestore(bidDoc);
          if (bid.companyId == billboard.currentBidderId) {
            await _firestore.collection('bids').doc(bidDoc.id).update({
              'status': 'won',
              'updatedAt': Timestamp.now(),
            });
          } else {
            // Diğer teklifleri kaybedilmiş olarak işaretle
            await _firestore.collection('bids').doc(bidDoc.id).update({
              'status': 'lost',
              'updatedAt': Timestamp.now(),
            });
          }
        }
      } else {
        // Teklif yoksa panoyu tekrar müsait hale getir
        await _firestore.collection('billboards').doc(billboardId).update({
          'status': 'available',
          'auctionEndDate': null,
          'currentBid': null,
          'currentBidderId': null,
        });

        // Tüm teklifleri iptal et
        for (var bidDoc in bidsSnapshot.docs) {
          await _firestore.collection('bids').doc(bidDoc.id).update({
            'status': 'cancelled',
            'updatedAt': Timestamp.now(),
          });
        }
      }
    } catch (e) {
      print('Açık artırma sonlandırma hatası: $e');
      rethrow;
    }
  }

  // Teklif verme
  Future<void> placeBid(String billboardId, String companyId, double amount) async {
    DocumentReference billboardRef = _firestore.collection(_collection).doc(billboardId);
    CollectionReference bidsRef = _firestore.collection('bids');
    
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot doc = await transaction.get(billboardRef);
        if (!doc.exists) {
          throw Exception('Pano bulunamadı!');
        }

        Billboard billboard = Billboard.fromFirestore(doc);
        if (billboard.status != 'active') {
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

        // Pano dokümanını güncelle
        transaction.update(billboardRef, {
          'currentBid': amount,
          'currentBidderId': companyId,
          'updatedAt': Timestamp.now(),
        });

        // Yeni teklif dokümanı oluştur
        DocumentReference newBidRef = bidsRef.doc();
        Bid newBid = Bid(
          id: newBidRef.id,
          billboardId: billboardId,
          companyId: companyId,
          amount: amount,
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        transaction.set(newBidRef, newBid.toMap());
      });
    } catch (e) {
      print('Teklif verme hatası: $e');
      rethrow;
    }
  }
} 