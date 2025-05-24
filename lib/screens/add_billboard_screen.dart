import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/cloudinary_config.dart';

class AddBillboardScreen extends StatefulWidget {
  const AddBillboardScreen({Key? key}) : super(key: key);

  @override
  State<AddBillboardScreen> createState() => _AddBillboardScreenState();
}

class _AddBillboardScreenState extends State<AddBillboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _sizeController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  File? _selectedImage;
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _locationController.dispose();
    _sizeController.dispose();
    _descriptionController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf seçilirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);

      // Konum servislerinin açık olup olmadığını kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Konum servisleri kapalı. Lütfen cihazınızın konum servislerini açın.');
      }

      // Konum izinlerini kontrol et
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Konum izni reddedildi. Lütfen uygulama ayarlarından konum iznini etkinleştirin.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Konum izni kalıcı olarak reddedildi. Lütfen cihaz ayarlarından konum iznini etkinleştirin.');
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        // Mevcut konumu al
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        final latLng = LatLng(position.latitude, position.longitude);

        // Adres bilgisini al
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final address = '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
            setState(() {
              _locationController.text = address;
              _selectedLocation = latLng;
            });
          } else {
            setState(() {
              _locationController.text = '${position.latitude}, ${position.longitude}';
              _selectedLocation = latLng;
            });
          }
        } catch (e) {
          setState(() {
            _locationController.text = '${position.latitude}, ${position.longitude}';
            _selectedLocation = latLng;
          });
        }

        // Haritayı mevcut konuma taşı
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 15),
        );
      }
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

  Future<String> _uploadImageToCloudinary(File imageFile) async {
    try {
      // API isteği için URL
      final url = 'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload';

      // Form verilerini hazırla
      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['api_key'] = CloudinaryConfig.apiKey
        ..fields['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString()
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        ));

      // İsteği gönder
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'];
      } else {
        throw Exception('Fotoğraf yüklenemedi: ${jsonResponse['error']}');
      }
    } catch (e) {
      throw Exception('Fotoğraf yüklenirken hata oluştu: $e');
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
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir fotoğraf seçin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Fotoğrafı Cloudinary'ye yükle
      final imageUrl = await _uploadImageToCloudinary(_selectedImage!);

      // Boyut bilgisini parse et
      final sizeParts = _sizeController.text.split('x');
      final width = double.parse(sizeParts[0].trim().replaceAll('m', ''));
      final height = double.parse(sizeParts[1].trim().replaceAll('m', ''));

      await FirebaseFirestore.instance.collection('billboards').add({
        'municipalityId': user.uid,
        'location': _locationController.text,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'width': width,
        'height': height,
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
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
              // Fotoğraf seçici
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Fotoğraf Seç',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
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
                    onTap: (latLng) async {
                      setState(() => _selectedLocation = latLng);
                      
                      try {
                        final placemarks = await placemarkFromCoordinates(
                          latLng.latitude,
                          latLng.longitude,
                        );

                        if (placemarks.isNotEmpty) {
                          final place = placemarks.first;
                          final address = '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
                          _locationController.text = address;
                        } else {
                          _locationController.text = '${latLng.latitude}, ${latLng.longitude}';
                        }
                      } catch (e) {
                        _locationController.text = '${latLng.latitude}, ${latLng.longitude}';
                      }
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
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'İlan panosu hakkında açıklama',
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