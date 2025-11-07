import 'package:flutter/material.dart';
import '../models/billboard.dart';
import '../services/billboard_service.dart';

class StartAuctionScreen extends StatefulWidget {
  final Billboard billboard;

  const StartAuctionScreen({
    Key? key,
    required this.billboard,
  }) : super(key: key);

  @override
  State<StartAuctionScreen> createState() => _StartAuctionScreenState();
}

class _StartAuctionScreenState extends State<StartAuctionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _billboardService = BillboardService();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  final _minimumBidController = TextEditingController();
  final _minimumPriceController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _minimumBidController.dispose();
    _minimumPriceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _billboardService.startAuction(
        widget.billboard.id,
        _endDate,
        double.parse(_minimumBidController.text),
        double.parse(_minimumPriceController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Açık artırma başarıyla başlatıldı')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Açık Artırma Başlat'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pano Bilgileri',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Konum: ${widget.billboard.location}'),
                      Text('Boyut: ${widget.billboard.width}m x ${widget.billboard.height}m'),
                      if (widget.billboard.imageUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.billboard.imageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Açık Artırma Detayları',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _minimumPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Minimum Fiyat (TL)',
                          hintText: 'Örn: 5000',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen minimum fiyatı girin';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Geçerli bir sayı girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _minimumBidController,
                        decoration: const InputDecoration(
                          labelText: 'Minimum Teklif Artışı (TL)',
                          hintText: 'Örn: 1000',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen minimum teklif artışını girin';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Geçerli bir sayı girin';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Bitiş Tarihi'),
                subtitle: Text(
                  '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Açık Artırmayı Başlat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 