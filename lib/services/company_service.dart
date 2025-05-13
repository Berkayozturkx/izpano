import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company.dart';

class CompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'companies';

  // Yeni şirket oluşturma
  Future<String> createCompany(Company company) async {
    DocumentReference docRef = await _firestore.collection(_collection).add(company.toMap());
    return docRef.id;
  }

  // Şirket bilgilerini güncelleme
  Future<void> updateCompany(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update({
      ...data,
      'updatedAt': Timestamp.now(),
    });
  }

  // Şirket durumunu güncelleme (onaylama/kara liste)
  Future<void> updateCompanyStatus(String id, String status) async {
    await _firestore.collection(_collection).doc(id).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  // Şirket detaylarını getirme
  Future<Company?> getCompany(String id) async {
    DocumentSnapshot doc = await _firestore.collection(_collection).doc(id).get();
    if (doc.exists) {
      return Company.fromFirestore(doc);
    }
    return null;
  }

  // Tüm şirketleri getirme
  Stream<List<Company>> getAllCompanies() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Company.fromFirestore(doc)).toList();
    });
  }

  // Onay bekleyen şirketleri getirme
  Stream<List<Company>> getPendingCompanies() {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Company.fromFirestore(doc)).toList();
    });
  }

  // Favori panoları güncelleme
  Future<void> updateFavoriteBillboards(String companyId, List<String> billboardIds) async {
    await _firestore.collection(_collection).doc(companyId).update({
      'favoriteBillboards': billboardIds,
      'updatedAt': Timestamp.now(),
    });
  }

  // Favori panoya ekleme
  Future<void> addFavoriteBillboard(String companyId, String billboardId) async {
    DocumentReference docRef = _firestore.collection(_collection).doc(companyId);
    
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot doc = await transaction.get(docRef);
      if (!doc.exists) {
        throw Exception('Şirket bulunamadı!');
      }

      Company company = Company.fromFirestore(doc);
      List<String> favorites = List.from(company.favoriteBillboards);
      
      if (!favorites.contains(billboardId)) {
        favorites.add(billboardId);
        transaction.update(docRef, {
          'favoriteBillboards': favorites,
          'updatedAt': Timestamp.now(),
        });
      }
    });
  }

  // Favori panelardan çıkarma
  Future<void> removeFavoriteBillboard(String companyId, String billboardId) async {
    DocumentReference docRef = _firestore.collection(_collection).doc(companyId);
    
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot doc = await transaction.get(docRef);
      if (!doc.exists) {
        throw Exception('Şirket bulunamadı!');
      }

      Company company = Company.fromFirestore(doc);
      List<String> favorites = List.from(company.favoriteBillboards);
      
      if (favorites.contains(billboardId)) {
        favorites.remove(billboardId);
        transaction.update(docRef, {
          'favoriteBillboards': favorites,
          'updatedAt': Timestamp.now(),
        });
      }
    });
  }
} 