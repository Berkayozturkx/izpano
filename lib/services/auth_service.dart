import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_type.dart';
import 'package:flutter/material.dart';
import 'database_initializer.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseInitializer _dbInitializer = DatabaseInitializer();

  // Kullanıcı tipini string'e çevirme
  String _userTypeToString(UserType type) {
    return type == UserType.municipality ? 'municipality' : 'company';
  }

  // Koleksiyon adını alma
  String _getCollectionName(UserType type) {
    return type == UserType.municipality ? 'municipalities' : 'companies';
  }

  // Kullanıcı tipini kontrol et
  Future<String?> getUserType(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.get('userType') as String?;
      }
      return null;
    } catch (e) {
      print('Kullanıcı tipi kontrol hatası: $e');
      return null;
    }
  }

  // Kullanıcı kaydı
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String userType,
    Map<String, dynamic> userData,
  ) async {
    try {
      // Firebase Auth ile kullanıcı oluştur
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı dokümanını oluştur
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
        ...userData,
      });

      // Kullanıcı tipine göre gerekli koleksiyonları oluştur
      await _dbInitializer.initializeUserCollections(
        userCredential.user!.uid,
        userType,
      );

      return userCredential;
    } catch (e) {
      print('Kayıt hatası: $e');
      rethrow;
    }
  }

  // Giriş yapma
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı tipini kontrol et
      String? userType = await getUserType(userCredential.user!.uid);
      if (userType == null) {
        throw Exception('Kullanıcı tipi bulunamadı!');
      }

      // Koleksiyonların varlığını kontrol et
      bool collectionsExist = await _dbInitializer.checkCollectionsExist(
        userCredential.user!.uid,
        userType,
      );

      // Eğer koleksiyonlar yoksa oluştur
      if (!collectionsExist) {
        await _dbInitializer.initializeUserCollections(
          userCredential.user!.uid,
          userType,
        );
      }

      return userCredential;
    } catch (e) {
      print('Giriş hatası: $e');
      rethrow;
    }
  }

  // Çıkış yapma
  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      // Ana sayfaya yönlendir
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('Çıkış hatası: $e');
      rethrow;
    }
  }

  // Şifre sıfırlama
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Şifre sıfırlama hatası: $e');
      rethrow;
    }
  }

  // Kullanıcı bilgilerini güncelleme
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      print('Profil güncelleme hatası: $e');
      rethrow;
    }
  }

  // Mevcut kullanıcıyı alma
  User? get currentUser => _auth.currentUser;

  // Kullanıcı durumu değişikliklerini dinleme
  Stream<User?> get authStateChanges => _auth.authStateChanges();
} 