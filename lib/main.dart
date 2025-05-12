import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/municipality_home_screen.dart';
import 'screens/company_home_screen.dart';
import 'services/auth_service.dart';
import 'models/user_type.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MainApp());
  } catch (e) {
    print('Firebase initialization error: $e');
    // Firebase başlatılamazsa bile uygulamayı başlat
    runApp(const MainApp());
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İzPano',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => StreamBuilder(
          stream: AuthService().authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData) {
              // Kullanıcı giriş yapmış, kullanıcı tipine göre yönlendir
              return FutureBuilder(
                future: _getUserType(snapshot.data!.uid),
                builder: (context, typeSnapshot) {
                  if (typeSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (typeSnapshot.hasData) {
                    final userType = typeSnapshot.data as UserType;
                    if (userType == UserType.municipality) {
                      return const MunicipalityHomeScreen();
                    } else {
                      return const CompanyHomeScreen();
                    }
                  }

                  return const LoginScreen();
                },
              );
            }

            return const LoginScreen();
          },
        ),
        '/login': (context) => const LoginScreen(),
        '/municipality-home': (context) => const MunicipalityHomeScreen(),
        '/company-home': (context) => const CompanyHomeScreen(),
      },
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('Sayfa bulunamadı: ${settings.name}'),
            ),
          ),
        );
      },
      navigatorObservers: [
        _CustomNavigatorObserver(),
      ],
    );
  }

  Future<UserType> _getUserType(String uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Önce belediye koleksiyonunda ara
      final municipalityDoc = await firestore.collection('municipalities').doc(uid).get();
      if (municipalityDoc.exists) {
        return UserType.municipality;
      }

      // Belediye koleksiyonunda bulunamazsa şirket koleksiyonunda ara
      final companyDoc = await firestore.collection('companies').doc(uid).get();
      if (companyDoc.exists) {
        return UserType.company;
      }

      // Hiçbir koleksiyonda bulunamazsa varsayılan olarak belediye döndür
      return UserType.municipality;
    } catch (e) {
      print('Error getting user type: $e');
      // Hata durumunda varsayılan olarak belediye döndür
      return UserType.municipality;
    }
  }
}

class _CustomNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    print('Navigated to: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    print('Popped from: ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    print('Replaced route: ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    print('Removed route: ${route.settings.name}');
  }
}
