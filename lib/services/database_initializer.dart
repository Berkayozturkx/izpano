import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company.dart';
import '../models/billboard.dart';
import '../models/bid.dart';

class DatabaseInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı tipine göre gerekli koleksiyonları oluştur
  Future<void> initializeUserCollections(String userId, String userType) async {
    try {
      if (userType == 'municipality') {
        await _initializeMunicipalityCollections(userId);
      } else if (userType == 'company') {
        await _initializeCompanyCollections(userId);
      }
    } catch (e) {
      print('Koleksiyon oluşturma hatası: $e');
      rethrow;
    }
  }

  // Belediye koleksiyonlarını oluştur
  Future<void> _initializeMunicipalityCollections(String municipalityId) async {
    // Belediye referansını oluştur
    final municipalityRef = _firestore.collection('municipalities').doc(municipalityId);
    
    // Belediye dokümanını oluştur
    await municipalityRef.set({
      'id': municipalityId,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });

    // Billboard koleksiyonu için örnek veri
    final billboardRef = _firestore.collection('billboards').doc();
    final sampleBillboard = Billboard(
      id: billboardRef.id,
      location: 'Örnek Mahallesi',
      description: 'Örnek Pano Açıklaması',
      municipalityId: municipalityId,
      width: 5.0,
      height: 3.0,
      status: 'available',
      createdAt: DateTime.now(),
    );

    await billboardRef.set(sampleBillboard.toMap());
  }

  // Şirket koleksiyonlarını oluştur
  Future<void> _initializeCompanyCollections(String companyId) async {
    // Şirket referansını oluştur
    final companyRef = _firestore.collection('companies').doc(companyId);
    
    // Şirket dokümanını oluştur
    final sampleCompany = Company(
      id: companyId,
      name: 'Örnek Şirket',
      taxNumber: '1234567890',
      address: 'Örnek Adres',
      phoneNumber: '5551234567',
      status: 'pending',
      createdAt: DateTime.now(),
      favoriteBillboards: [],
    );

    await companyRef.set(sampleCompany.toMap());

    // Bid koleksiyonu için örnek veri
    final bidRef = _firestore.collection('bids').doc();
    final sampleBid = Bid(
      id: bidRef.id,
      billboardId: 'sample_billboard_id',
      companyId: companyId,
      amount: 1000.0,
      status: 'active',
      createdAt: DateTime.now(),
    );

    await bidRef.set(sampleBid.toMap());
  }

  // Koleksiyonların varlığını kontrol et
  Future<bool> checkCollectionsExist(String userId, String userType) async {
    try {
      if (userType == 'municipality') {
        final municipalityDoc = await _firestore.collection('municipalities').doc(userId).get();
        return municipalityDoc.exists;
      } else if (userType == 'company') {
        final companyDoc = await _firestore.collection('companies').doc(userId).get();
        return companyDoc.exists;
      }
      return false;
    } catch (e) {
      print('Koleksiyon kontrol hatası: $e');
      return false;
    }
  }

  // Koleksiyonları temizle (test için)
  Future<void> cleanupCollections(String userId, String userType) async {
    try {
      if (userType == 'municipality') {
        await _firestore.collection('municipalities').doc(userId).delete();
        // İlgili panoları da sil
        final billboards = await _firestore
            .collection('billboards')
            .where('municipalityId', isEqualTo: userId)
            .get();
        
        for (var doc in billboards.docs) {
          await doc.reference.delete();
        }
      } else if (userType == 'company') {
        await _firestore.collection('companies').doc(userId).delete();
        // İlgili teklifleri de sil
        final bids = await _firestore
            .collection('bids')
            .where('companyId', isEqualTo: userId)
            .get();
        
        for (var doc in bids.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      print('Koleksiyon temizleme hatası: $e');
      rethrow;
    }
  }
} 