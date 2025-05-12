import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_type.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı tipini string'e çevirme
  String _userTypeToString(UserType type) {
    return type == UserType.municipality ? 'municipality' : 'company';
  }

  // Koleksiyon adını alma
  String _getCollectionName(UserType type) {
    return type == UserType.municipality ? 'municipalities' : 'companies';
  }

  // Kayıt olma işlemi
  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required UserType userType,
  }) async {
    try {
      // Firebase Auth ile kullanıcı oluştur
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore'a kullanıcı bilgilerini kaydet
      await _firestore.collection(_getCollectionName(userType)).doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'type': _userTypeToString(userType),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message = 'Bir hata oluştu';
      if (e.code == 'weak-password') {
        message = 'Şifre çok zayıf';
      } else if (e.code == 'email-already-in-use') {
        message = 'Bu e-posta adresi zaten kullanımda';
      }
      throw message;
    }
  }

  // Giriş yapma işlemi
  Future<UserCredential> login({
    required String email,
    required String password,
    required UserType userType,
  }) async {
    try {
      // Firebase Auth ile giriş yap
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı tipini kontrol et
      DocumentSnapshot userDoc = await _firestore
          .collection(_getCollectionName(userType))
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw 'Bu hesap türü için giriş yapamazsınız';
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message = 'Bir hata oluştu';
      if (e.code == 'user-not-found') {
        message = 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı';
      } else if (e.code == 'wrong-password') {
        message = 'Hatalı şifre';
      }
      throw message;
    }
  }

  // Çıkış yapma işlemi
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Mevcut kullanıcıyı alma
  User? get currentUser => _auth.currentUser;

  // Kullanıcı durumu değişikliklerini dinleme
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      // Çıkış yapıldıktan sonra login sayfasına yönlendirme
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Çıkış yapılırken bir hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 