import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import '../services/billboard_service.dart';
import '../services/bid_service.dart';
import '../models/billboard.dart';
import '../models/bid.dart';
import 'package:intl/intl.dart';
import '../services/company_service.dart';

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({Key? key}) : super(key: key);

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  final AuthService _authService = AuthService();
  final BillboardService _billboardService = BillboardService();
  final BidService _bidService = BidService();
  final CompanyService _companyService = CompanyService();
  int _selectedIndex = 0;
  final Map<String, TextEditingController> _bidControllers = {};
  
  // Add controllers for company profile fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _taxNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCompanyProfile();
  }

  @override
  void dispose() {
    _bidControllers.values.forEach((controller) => controller.dispose());
    _nameController.dispose();
    _taxNumberController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyProfile() async {
    try {
      final company = await _companyService.getCompany(_authService.currentUser!.uid);
      if (company != null) {
        setState(() {
          _nameController.text = company.name;
          _taxNumberController.text = company.taxNumber;
          _addressController.text = company.address;
          _phoneNumberController.text = company.phoneNumber;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _updateCompanyProfile() async {
    try {
      await _companyService.updateCompany(
        _authService.currentUser!.uid,
        {
          'name': _nameController.text,
          'taxNumber': _taxNumberController.text,
          'address': _addressController.text,
          'phoneNumber': _phoneNumberController.text,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil bilgileri başarıyla güncellendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil güncellenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _submitBid(String billboardId, String currentBid) async {
    try {
      final amount = double.tryParse(currentBid);
      if (amount == null) {
        throw Exception('Geçerli bir teklif tutarı giriniz.');
      }

      await _billboardService.placeBid(
        billboardId,
        _authService.currentUser!.uid,
        amount,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teklifiniz başarıyla verildi.')),
        );
        // Teklif alanını temizle
        _bidControllers[billboardId]?.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şirket Paneli'),
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
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildAuctionsTab(),
          _buildActiveBidsTab(),
          _buildWonBidsTab(),
          _buildCompanyProfileTab(),
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
            icon: Icon(Icons.gavel),
            label: 'Açık Artırmalar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Aktif Teklifler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Kazandıklarım',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Profilim',
          ),
        ],
      ),
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
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Billboard>>(
            stream: _billboardService.getActiveAuctions(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Hata oluştu: ${snapshot.error}'),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final billboards = snapshot.data ?? [];

              if (billboards.isEmpty) {
                return const Center(
                  child: Text('Aktif açık artırma bulunmuyor.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: billboards.length,
                itemBuilder: (context, index) {
                  final billboard = billboards[index];
                  _bidControllers[billboard.id] ??= TextEditingController();
                  
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
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                billboard.location,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Boyut: ${billboard.width}m x ${billboard.height}m',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                'Mevcut Teklif: ₺${NumberFormat('#,##0.00').format(billboard.currentBid ?? 0)}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                'Minimum Fiyat: ₺${NumberFormat('#,##0.00').format(billboard.minimumPrice)}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                'Minimum Artış: ₺${NumberFormat('#,##0.00').format(billboard.minimumBidIncrement)}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                'Kalan Süre: $daysLeft gün, $hoursLeft saat, $minutesLeft dakika',
                                style: TextStyle(
                                  color: timeLeft.isNegative ? AppTheme.errorColor : AppTheme.successColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: _bidControllers[billboard.id]!,
                                      label: 'Teklif Tutarı',
                                      hint: 'Teklif tutarını girin',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  CustomButton(
                                    text: 'Teklif Ver',
                                    onPressed: () async {
                                      final bidAmount = _bidControllers[billboard.id]?.text;
                                      if (bidAmount != null && bidAmount.isNotEmpty) {
                                        await _submitBid(billboard.id, bidAmount);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Lütfen bir teklif tutarı giriniz.')),
                                        );
                                      }
                                    },
                                    width: 120,
                                  ),
                                ],
                              ),
                            ],
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

  Widget _buildActiveBidsTab() {
    return StreamBuilder<List<Bid>>(
      stream: BidService().getActiveBidsByCompany(AuthService().currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Hata: ${snapshot.error}'),
          );
        }

        final bids = snapshot.data ?? [];
        if (bids.isEmpty) {
          return const Center(
            child: Text('Aktif teklifiniz bulunmamaktadır.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bids.length,
          itemBuilder: (context, index) {
            final bid = bids[index];
            return FutureBuilder<Billboard?>(
              future: BillboardService().getBillboard(bid.billboardId),
              builder: (context, billboardSnapshot) {
                if (billboardSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final billboard = billboardSnapshot.data;
                if (billboard == null) {
                  return const SizedBox.shrink();
                }

                if (billboard.status != 'active' || 
                    billboard.auctionEndDate == null || 
                    billboard.auctionEndDate!.isBefore(DateTime.now())) {
                  return const SizedBox.shrink();
                }

                final hoursLeft = billboard.auctionEndDate!.difference(DateTime.now()).inHours;
                final minutesLeft = billboard.auctionEndDate!.difference(DateTime.now()).inMinutes % 60;
                final isHighestBid = billboard.currentBidderId == AuthService().currentUser!.uid;

                return CustomCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                billboard.location,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            if (isHighestBid)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'En Yüksek Teklif',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Boyut: ${billboard.width}m x ${billboard.height}m',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Teklifiniz: ₺${bid.amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kalan Süre: $hoursLeft saat $minutesLeft dakika',
                          style: TextStyle(
                            fontSize: 16,
                            color: hoursLeft < 24 ? AppTheme.errorColor : AppTheme.successColor,
                          ),
                        ),
                        if (!isHighestBid) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Teklifinizi Güncelleyin',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _bidControllers[billboard.id] ??= TextEditingController(),
                                  label: 'Yeni Teklif',
                                  hint: 'Yeni teklif tutarını girin',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              CustomButton(
                                text: 'Güncelle',
                                onPressed: () async {
                                  try {
                                    final newAmount = double.parse(_bidControllers[billboard.id]?.text ?? '');
                                    await _billboardService.placeBid(
                                      billboard.id,
                                      _authService.currentUser!.uid,
                                      newAmount,
                                    );
                                    _bidControllers[billboard.id]?.clear();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Teklifiniz başarıyla güncellendi'),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Hata: $e'),
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                    );
                                  }
                                },
                                width: 120,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildWonBidsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Kazandığım Teklifler',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Bid>>(
            stream: _bidService.getWonBidsByCompany(_authService.currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Hata: ${snapshot.error}'),
                );
              }

              final bids = snapshot.data ?? [];
              if (bids.isEmpty) {
                return const Center(
                  child: Text('Henüz kazandığınız teklif bulunmamaktadır.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bids.length,
                itemBuilder: (context, index) {
                  final bid = bids[index];
                  return FutureBuilder<Billboard?>(
                    future: _billboardService.getBillboard(bid.billboardId),
                    builder: (context, billboardSnapshot) {
                      if (billboardSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final billboard = billboardSnapshot.data;
                      if (billboard == null) {
                        return const SizedBox.shrink();
                      }

                      return CustomCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: const Icon(Icons.emoji_events, color: Colors.amber),
                          title: Text(
                            billboard.location,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Kazanan Teklif: ₺${NumberFormat('#,##0.00').format(bid.amount)}'),
                              Text('Boyut: ${billboard.width}m x ${billboard.height}m'),
                              Text('Bitiş Tarihi: ${DateFormat('dd.MM.yyyy').format(billboard.auctionEndDate!)}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.info_outline),
                            onPressed: () {
                              // TODO: Show billboard details
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Firma Profili',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _nameController.text.isNotEmpty ? _nameController.text : 'Firma Adı Yükleniyor...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Firma Bilgileri',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _nameController,
                    label: 'Firma Adı',
                    hint: 'Firma adını girin',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _taxNumberController,
                    label: 'Vergi Numarası',
                    hint: 'Vergi numarasını girin',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _addressController,
                    label: 'Adres',
                    hint: 'Adres bilgilerini girin',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _phoneNumberController,
                    label: 'İletişim Numarası',
                    hint: 'İletişim numarasını girin',
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Bilgileri Güncelle',
                    onPressed: _updateCompanyProfile,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Geçmiş Tekliflerim',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<Bid>>(
                    stream: _bidService.getWonBidsByCompany(_authService.currentUser!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Hata: ${snapshot.error}'),
                        );
                      }

                      final bids = snapshot.data ?? [];
                      if (bids.isEmpty) {
                        return const Center(
                          child: Text('Henüz kazandığınız teklif bulunmamaktadır.'),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: bids.length,
                        itemBuilder: (context, index) {
                          final bid = bids[index];
                          return FutureBuilder<Billboard?>(
                            future: _billboardService.getBillboard(bid.billboardId),
                            builder: (context, billboardSnapshot) {
                              if (billboardSnapshot.connectionState == ConnectionState.waiting) {
                                return const ListTile(
                                  title: Text('Pano bilgisi yükleniyor...'),
                                );
                              }

                              final billboard = billboardSnapshot.data;
                              if (billboard == null) {
                                return const SizedBox.shrink();
                              }

                              return ListTile(
                                leading: const Icon(Icons.history),
                                title: Text(
                                  billboard.location,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Teklif: ₺${NumberFormat('#,##0.00').format(bid.amount)}'),
                                    Text('Durum: ${_getBidStatusText(bid.status)}'),
                                    Text('Tarih: ${DateFormat('dd.MM.yyyy HH:mm').format(bid.createdAt)}'),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getBidStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'won':
        return 'Kazanıldı';
      case 'lost':
        return 'Kaybedildi';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return status;
    }
  }
} 