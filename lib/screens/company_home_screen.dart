import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/billboard_service.dart';
import '../services/bid_service.dart';
import '../models/billboard.dart';
import '../models/bid.dart';
import 'package:intl/intl.dart';

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({Key? key}) : super(key: key);

  @override
  State<CompanyHomeScreen> createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  final AuthService _authService = AuthService();
  final BillboardService _billboardService = BillboardService();
  final BidService _bidService = BidService();
  int _selectedIndex = 0;
  final Map<String, TextEditingController> _bidControllers = {};

  @override
  void dispose() {
    _bidControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
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
                await _authService.signOut(context);
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
              const Text(
                'Açık Artırmalar',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
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

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        if (billboard.imageUrl != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
                              Text('${billboard.width}m x ${billboard.height}m'),
                              Text('Mevcut Teklif: ₺${NumberFormat('#,##0.00').format(billboard.currentBid ?? 0)}'),
                              Text('Minimum Artış: ₺${NumberFormat('#,##0.00').format(billboard.minimumBidIncrement)}'),
                              Text('Kalan Süre: $daysLeft gün, $hoursLeft saat, $minutesLeft dakika'),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _bidControllers[billboard.id],
                                  decoration: const InputDecoration(
                                    labelText: 'Teklif Tutarı',
                                    border: OutlineInputBorder(),
                                    prefixText: '₺',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
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
                                child: const Text('Teklif Ver'),
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

                final hoursLeft = billboard.auctionEndDate!.difference(DateTime.now()).inHours;
                final minutesLeft = billboard.auctionEndDate!.difference(DateTime.now()).inMinutes % 60;
                final isHighestBid = billboard.currentBidderId == AuthService().currentUser!.uid;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isHighestBid)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
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
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Teklifiniz: ₺${bid.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kalan Süre: $hoursLeft saat $minutesLeft dakika',
                          style: TextStyle(
                            fontSize: 16,
                            color: hoursLeft < 24 ? Colors.red : Colors.black,
                          ),
                        ),
                        if (!isHighestBid) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Teklifinizi Güncelleyin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _bidControllers[billboard.id] ??= TextEditingController(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Yeni Teklif',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
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
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Güncelle'),
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
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Kazandığım Teklifler',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3, // TODO: Replace with actual won bids count
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(Icons.emoji_events),
                  title: Text('Pano ${index + 1}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kazanan Teklif: ₺20,000'),
                      const Text('Bitiş Tarihi: 24.03.2024'),
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
          const Text(
            'Firma Profili',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Firma Bilgileri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Firma Adı',
                      border: OutlineInputBorder(),
                    ),
                    // TODO: Add controller and initial value
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Vergi Numarası',
                      border: OutlineInputBorder(),
                    ),
                    // TODO: Add controller and initial value
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Adres',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    // TODO: Add controller and initial value
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'İletişim Numarası',
                      border: OutlineInputBorder(),
                    ),
                    // TODO: Add controller and initial value
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Save company profile
                      },
                      child: const Text('Bilgileri Güncelle'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Geçmiş Tekliflerim',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5, // TODO: Replace with actual history count
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.history),
                        title: Text('Pano ${index + 1}'),
                        subtitle: const Text('Teklif: ₺15,000'),
                        trailing: const Text('24.03.2024'),
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
} 