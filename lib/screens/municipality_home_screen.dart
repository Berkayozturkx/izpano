import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class MunicipalityHomeScreen extends StatefulWidget {
  const MunicipalityHomeScreen({Key? key}) : super(key: key);

  @override
  State<MunicipalityHomeScreen> createState() => _MunicipalityHomeScreenState();
}

class _MunicipalityHomeScreenState extends State<MunicipalityHomeScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Belediye Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Çıkış yapma onay dialogu
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Çıkış Yap'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await _authService.signOut(context);
              }
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildMenuCard(
            'İlan Panoları',
            Icons.view_agenda,
            () {
              // TODO: İlan panoları sayfasına yönlendirme
            },
          ),
          _buildMenuCard(
            'Açık Artırmalar',
            Icons.gavel,
            () {
              // TODO: Açık artırmalar sayfasına yönlendirme
            },
          ),
          _buildMenuCard(
            'Kiralama Talepleri',
            Icons.request_page,
            () {
              // TODO: Kiralama talepleri sayfasına yönlendirme
            },
          ),
          _buildMenuCard(
            'Raporlar',
            Icons.bar_chart,
            () {
              // TODO: Raporlar sayfasına yönlendirme
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Yeni ilan/panel ekleme sayfasına yönlendirme
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMenuCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 