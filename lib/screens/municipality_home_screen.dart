import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'add_billboard_screen.dart';

class MunicipalityHomeScreen extends StatefulWidget {
  const MunicipalityHomeScreen({Key? key}) : super(key: key);

  @override
  State<MunicipalityHomeScreen> createState() => _MunicipalityHomeScreenState();
}

class _MunicipalityHomeScreenState extends State<MunicipalityHomeScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Belediye Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildBillboardsTab(),
          _buildAuctionsTab(),
          _buildBidsTab(),
          _buildAnalyticsTab(),
          _buildCompanyManagementTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.view_agenda),
            label: 'Panolar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel),
            label: 'Açık Artırmalar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Teklifler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Firmalar',
          ),
        ],
      ),
    );
  }

  Widget _buildBillboardsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'İlan Panoları',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddBillboardScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Yeni Pano'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 10, // TODO: Replace with actual billboard count
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(Icons.view_agenda),
                  title: Text('Pano ${index + 1}'),
                  subtitle: const Text('Konum: Örnek Mahallesi'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Düzenle'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Sil'),
                      ),
                    ],
                    onSelected: (value) {
                      // TODO: Implement edit/delete functionality
                    },
                  ),
                  onTap: () {
                    // TODO: Navigate to billboard details
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAuctionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Açık Artırmalar',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to new auction screen
                },
                icon: const Icon(Icons.add),
                label: const Text('Yeni Açık Artırma'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5, // TODO: Replace with actual auction count
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(Icons.gavel),
                  title: Text('Açık Artırma ${index + 1}'),
                  subtitle: const Text('Bitiş: 24.03.2024'),
                  trailing: const Text('₺10,000'),
                  onTap: () {
                    // TODO: Navigate to auction details
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBidsTab() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Teklif Yönetimi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 8, // TODO: Replace with actual bid count
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: Text('Teklif ${index + 1}'),
                  subtitle: const Text('Firma: Örnek A.Ş.'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('₺15,000'),
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () {
                          // TODO: Implement bid approval
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        onPressed: () {
                          // TODO: Implement bid rejection
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Navigate to bid history
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Gelir Analizi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildAnalyticsCard(
                'Aylık Gelir',
                Icons.calendar_today,
                '₺45,000',
                () {
                  // TODO: Show monthly analytics
                },
              ),
              _buildAnalyticsCard(
                'Yıllık Gelir',
                Icons.calendar_month,
                '₺540,000',
                () {
                  // TODO: Show yearly analytics
                },
              ),
              _buildAnalyticsCard(
                'Pano Bazlı',
                Icons.view_agenda,
                'Detaylı Rapor',
                () {
                  // TODO: Show billboard-based analytics
                },
              ),
              _buildAnalyticsCard(
                'Açık Artırma',
                Icons.gavel,
                'Detaylı Rapor',
                () {
                  // TODO: Show auction-based analytics
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyManagementTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Firma Yönetimi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to company approval screen
                },
                icon: const Icon(Icons.business),
                label: const Text('Firma Onayları'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 6, // TODO: Replace with actual company count
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(Icons.business),
                  title: Text('Firma ${index + 1}'),
                  subtitle: const Text('Durum: Aktif'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () {
                          // TODO: Implement company approval
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.block),
                        onPressed: () {
                          // TODO: Implement company blacklist
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Navigate to company profile
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    IconData icon,
    String value,
    VoidCallback onTap,
  ) {
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
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 