import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddBillboardScreen extends StatefulWidget {
  const AddBillboardScreen({Key? key}) : super(key: key);

  @override
  State<AddBillboardScreen> createState() => _AddBillboardScreenState();
}

class _AddBillboardScreenState extends State<AddBillboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _sizeController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _locationController.dispose();
    _sizeController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);

      // Konum servislerinin açık olup olmadığını kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Konum servisleri kapalı. Lütfen konum servislerini açın.');
      }

      // Konum izinlerini kontrol et
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Konum izni reddedildi. Lütfen ayarlardan konum iznini etkinleştirin.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Konum izni kalıcı olarak reddedildi. Lütfen ayarlardan konum iznini etkinleştirin.');
      }

      // Mevcut konumu al
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Konum alınamadı. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.');
        },
      );

      final latLng = LatLng(position.latitude, position.longitude);

      // Adres bilgisini al
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Adres bilgisi alınamadı.');
          },
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final address = '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
          _locationController.text = address;
        }
      } catch (e) {
        // Adres alınamazsa sadece koordinatları göster
        _locationController.text = '${position.latitude}, ${position.longitude}';
      }

      setState(() {
        _selectedLocation = latLng;
      });

      // Haritayı mevcut konuma taşı
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 15),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Tamam',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen haritadan bir konum seçin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      await FirebaseFirestore.instance.collection('billboards').add({
        'municipalityId': user.uid,
        'location': _locationController.text,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'size': _sizeController.text,
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İlan panosu başarıyla eklendi')),
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
        title: const Text('Yeni İlan Panosu Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Harita
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation ?? const LatLng(41.0082, 28.9784), // İstanbul
                      zoom: 12,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    onTap: (latLng) {
                      setState(() => _selectedLocation = latLng);
                    },
                    markers: _selectedLocation == null
                        ? {}
                        : {
                            Marker(
                              markerId: const MarkerId('selected_location'),
                              position: _selectedLocation!,
                            ),
                          },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Konum seçme butonu
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Mevcut Konumu Kullan'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Konum',
                  hintText: 'İlan panosunun bulunduğu konum',
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen konum bilgisini girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sizeController,
                decoration: const InputDecoration(
                  labelText: 'Boyut',
                  hintText: 'Örn: 3m x 4m',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen boyut bilgisini girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Fiyat (TL)',
                  hintText: 'Aylık kiralama fiyatı',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen fiyat bilgisini girin';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Geçerli bir sayı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'İlan panosu hakkında ek bilgiler',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen açıklama girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('İlan Panosu Ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 