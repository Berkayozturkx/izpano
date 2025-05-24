import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import '../services/billboard_service.dart';
import '../services/company_service.dart';
import '../services/bid_service.dart';
import '../services/analytics_service.dart';
import '../models/billboard.dart';
import '../models/company.dart';
import '../models/bid.dart';
import 'add_billboard_screen.dart';
import 'edit_billboard_screen.dart';
import 'start_auction_screen.dart';
import 'auction_details_screen.dart';

class MunicipalityHomeScreen extends StatefulWidget {
  const MunicipalityHomeScreen({Key? key}) : super(key: key);

  @override
  State<MunicipalityHomeScreen> createState() => _MunicipalityHomeScreenState();
}

class _MunicipalityHomeScreenState extends State<MunicipalityHomeScreen> {
  final AuthService _authService = AuthService();
  final BillboardService _billboardService = BillboardService();
  final CompanyService _companyService = CompanyService();
  final BidService _bidService = BidService();
  final AnalyticsService _analyticsService = AnalyticsService();
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
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
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
              Text(
                'İlan Panoları',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              CustomButton(
                text: 'Yeni Pano',
                icon: Icons.add,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddBillboardScreen(),
                    ),
                  );
                },
                width: 150,
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Billboard>>(
            stream: _billboardService.getBillboardsByMunicipality(_authService.currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Henüz pano bulunmuyor.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final billboard = snapshot.data![index];
                  return CustomCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        if (billboard.imageUrl != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.network(
                              billboard.imageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ListTile(
                          title: Text(billboard.location),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(billboard.description),
                              const SizedBox(height: 4),
                              Text('Boyut: ${billboard.width}m x ${billboard.height}m'),
                              Text('Minimum Fiyat: ₺${billboard.minimumPrice.toStringAsFixed(2)}'),
                              Text('Minimum Teklif: ₺${billboard.minimumBidIncrement.toStringAsFixed(2)}'),
                            ],
                          ),
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
                            onSelected: (value) async {
                              if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditBillboardScreen(billboard: billboard),
                                  ),
                                );
                              } else if (value == 'delete') {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Pano Sil'),
                                    content: const Text('Bu panoyu silmek istediğinizden emin misiniz?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('İptal'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Sil'),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldDelete == true) {
                                  await _billboardService.deleteBillboard(billboard.id);
                                }
                              }
                            },
                          ),
                          onTap: () {
                            // TODO: Navigate to billboard details
                          },
                        ),
                      ],
                    ),
                  );
                },
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
              Text(
                'Açık Artırmalar',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              CustomButton(
                text: 'Yeni Açık Artırma',
                icon: Icons.add,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Açık Artırma Başlat'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: StreamBuilder<List<Billboard>>(
                          stream: _billboardService.getBillboardsByMunicipality(_authService.currentUser!.uid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Center(child: Text('Hata: ${snapshot.error}'));
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(child: Text('Açık artırma için uygun pano bulunmuyor.'));
                            }

                            final availableBillboards = snapshot.data!
                                .where((billboard) => billboard.status == 'available')
                                .toList();

                            if (availableBillboards.isEmpty) {
                              return const Center(child: Text('Açık artırma için uygun pano bulunmuyor.'));
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: availableBillboards.length,
                              itemBuilder: (context, index) {
                                final billboard = availableBillboards[index];
                                return ListTile(
                                  leading: billboard.imageUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.network(
                                            billboard.imageUrl!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(Icons.view_agenda),
                                  title: Text(billboard.location),
                                  subtitle: Text('${billboard.width}m x ${billboard.height}m'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StartAuctionScreen(billboard: billboard),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İptal'),
                        ),
                      ],
                    ),
                  );
                },
                width: 180,
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Billboard>>(
            stream: _billboardService.getActiveAuctions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Aktif açık artırma bulunmuyor.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final billboard = snapshot.data![index];
                  final timeLeft = billboard.auctionEndDate!.difference(DateTime.now());
                  final daysLeft = timeLeft.inDays;
                  final hoursLeft = timeLeft.inHours.remainder(24);
                  final minutesLeft = timeLeft.inMinutes.remainder(60);

                  return CustomCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        if (billboard.imageUrl != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.network(
                              billboard.imageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ListTile(
                          title: Text(billboard.location),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Boyut: ${billboard.width}m x ${billboard.height}m'),
                              Text('Minimum Fiyat: ₺${billboard.minimumPrice.toStringAsFixed(2)}'),
                              Text('Minimum Teklif: ₺${billboard.minimumBidIncrement.toStringAsFixed(2)}'),
                              Text(
                                'Kalan Süre: ${daysLeft}g ${hoursLeft}s ${minutesLeft}dk',
                                style: TextStyle(
                                  color: timeLeft.isNegative ? AppTheme.errorColor : AppTheme.successColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'end',
                                child: Text('Açık Artırmayı Sonlandır'),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'end') {
                                final shouldEnd = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Açık Artırmayı Sonlandır'),
                                    content: const Text('Bu açık artırmayı sonlandırmak istediğinizden emin misiniz?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('İptal'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Sonlandır'),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldEnd == true) {
                                  try {
                                    await _billboardService.endAuction(billboard.id);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Açık artırma sonlandırıldı')),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Hata oluştu: $e')),
                                      );
                                    }
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Teklif Yönetimi',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Billboard>>(
            stream: _billboardService.getActiveAuctions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Aktif açık artırma bulunmuyor.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final billboard = snapshot.data![index];
                  return CustomCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AuctionDetailsScreen(billboard: billboard),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          if (billboard.imageUrl != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.network(
                                billboard.imageUrl!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ListTile(
                            title: Text(billboard.location),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Boyut: ${billboard.width}m x ${billboard.height}m'),
                                Text('Minimum Fiyat: ₺${billboard.minimumPrice.toStringAsFixed(2)}'),
                                Text('Minimum Teklif: ₺${billboard.minimumBidIncrement.toStringAsFixed(2)}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Gelir Analizi',
            style: Theme.of(context).textTheme.headlineSmall,
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
                FutureBuilder<Map<String, dynamic>>(
                  future: _analyticsService.getMonthlyRevenue(_authService.currentUser!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Hata: ${snapshot.error}');
                    }
                    final data = snapshot.data!;
                    return Text(
                      '₺${data['totalRevenue'].toStringAsFixed(2)}\n${data['billboardCount']} Pano',
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                () {
                  // TODO: Show monthly analytics details
                },
              ),
              _buildAnalyticsCard(
                'Yıllık Gelir',
                Icons.calendar_month,
                FutureBuilder<Map<String, dynamic>>(
                  future: _analyticsService.getYearlyRevenue(_authService.currentUser!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Hata: ${snapshot.error}');
                    }
                    final data = snapshot.data!;
                    return Text(
                      '₺${data['totalRevenue'].toStringAsFixed(2)}\n${data['billboardCount']} Pano',
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                () {
                  // TODO: Show yearly analytics details
                },
              ),
              _buildAnalyticsCard(
                'Pano Bazlı',
                Icons.view_agenda,
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _analyticsService.getBillboardAnalytics(_authService.currentUser!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Hata: ${snapshot.error}');
                    }
                    final data = snapshot.data!;
                    final totalRevenue = data.fold<double>(
                      0,
                      (sum, item) => sum + (item['revenue'] as double),
                    );
                    return Text(
                      '₺${totalRevenue.toStringAsFixed(2)}\n${data.length} Pano',
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                () {
                  // TODO: Show billboard-based analytics details
                },
              ),
              _buildAnalyticsCard(
                'Açık Artırma',
                Icons.gavel,
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _analyticsService.getAuctionAnalytics(_authService.currentUser!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Hata: ${snapshot.error}');
                    }
                    final data = snapshot.data!;
                    final totalRevenue = data.fold<double>(
                      0,
                      (sum, item) => sum + (item['finalBid'] as double),
                    );
                    return Text(
                      '₺${totalRevenue.toStringAsFixed(2)}\n${data.length} Açık Artırma',
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                () {
                  // TODO: Show auction-based analytics details
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
              Text(
                'Firma Yönetimi',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              CustomButton(
                text: 'Firma Onayları',
                icon: Icons.business,
                onPressed: () {
                  // TODO: Navigate to company approval screen
                },
                width: 180,
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Company>>(
            stream: _companyService.getAllCompanies(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Henüz firma bulunmuyor.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final company = snapshot.data![index];
                  return CustomCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: const Icon(Icons.business),
                      title: Text(company.name),
                      subtitle: Text('Durum: ${company.status}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            color: AppTheme.successColor,
                            onPressed: () async {
                              await _companyService.updateCompanyStatus(company.id, 'approved');
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.block),
                            color: AppTheme.errorColor,
                            onPressed: () async {
                              await _companyService.updateCompanyStatus(company.id, 'blacklisted');
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
    Widget value,
    VoidCallback onTap,
  ) {
    return CustomCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: AppTheme.primaryColor,
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
          value,
        ],
      ),
    );
  }
} 