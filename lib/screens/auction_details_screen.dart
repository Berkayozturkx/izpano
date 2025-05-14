import 'package:flutter/material.dart';
import '../models/billboard.dart';
import '../models/bid.dart';
import '../models/company.dart';
import '../services/billboard_service.dart';
import '../services/bid_service.dart';
import '../services/company_service.dart';

class AuctionDetailsScreen extends StatelessWidget {
  final Billboard billboard;
  final BillboardService _billboardService = BillboardService();
  final BidService _bidService = BidService();
  final CompanyService _companyService = CompanyService();

  AuctionDetailsScreen({
    Key? key,
    required this.billboard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeLeft = billboard.auctionEndDate!.difference(DateTime.now());
    final daysLeft = timeLeft.inDays;
    final hoursLeft = timeLeft.inHours.remainder(24);
    final minutesLeft = timeLeft.inMinutes.remainder(60);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Açık Artırma Detayları'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (billboard.imageUrl != null)
              Image.network(
                billboard.imageUrl!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    billboard.location,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Boyut: ${billboard.width}m x ${billboard.height}m',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'Minimum Teklif Artışı: ₺${billboard.minimumBidIncrement.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'Mevcut En Yüksek Teklif: ₺${billboard.currentBid?.toStringAsFixed(2) ?? '0.00'}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: timeLeft.isNegative ? Colors.red.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          color: timeLeft.isNegative ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Kalan Süre: ${daysLeft}g ${hoursLeft}s ${minutesLeft}dk',
                          style: TextStyle(
                            color: timeLeft.isNegative ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teklifler',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<Bid>>(
                    stream: _bidService.getBidsByBillboard(billboard.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Hata: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Henüz teklif verilmemiş.'));
                      }

                      // Teklifleri miktara göre sırala
                      final sortedBids = List<Bid>.from(snapshot.data!)
                        ..sort((a, b) => b.amount.compareTo(a.amount));

                      return Column(
                        children: sortedBids.map((bid) {
                          return FutureBuilder<Company?>(
                            future: _companyService.getCompany(bid.companyId),
                            builder: (context, companySnapshot) {
                              if (companySnapshot.connectionState == ConnectionState.waiting) {
                                return const ListTile(
                                  title: Text('Firma bilgisi yükleniyor...'),
                                );
                              }

                              if (companySnapshot.hasError) {
                                return ListTile(
                                  title: Text('Hata: ${companySnapshot.error}'),
                                );
                              }

                              final company = companySnapshot.data;
                              final isHighestBid = bid.amount == billboard.currentBid;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isHighestBid ? Colors.green : Colors.grey,
                                    child: Text(
                                      '₺${bid.amount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(company?.name ?? 'Bilinmeyen Firma'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Teklif: ₺${bid.amount.toStringAsFixed(2)}'),
                                      Text('Tarih: ${bid.createdAt.toLocal().toString().split('.')[0]}'),
                                    ],
                                  ),
                                  trailing: isHighestBid
                                      ? const Chip(
                                          label: Text('En Yüksek Teklif'),
                                          backgroundColor: Colors.green,
                                          labelStyle: TextStyle(color: Colors.white),
                                        )
                                      : null,
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                  if (billboard.currentBidderId != null) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final shouldApprove = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Teklifi Onayla'),
                            content: const Text('Bu teklifi onaylamak istediğinizden emin misiniz?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('İptal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Onayla'),
                              ),
                            ],
                          ),
                        );

                        if (shouldApprove == true) {
                          try {
                            await _billboardService.endAuction(billboard.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Teklif onaylandı')),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Hata oluştu: $e')),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('En Yüksek Teklifi Onayla'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 