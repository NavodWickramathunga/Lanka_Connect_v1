import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../../ui/web/web_page_scaffold.dart';
import '../../utils/firestore_error_handler.dart';
import '../../utils/firestore_refs.dart';
import '../../utils/validators.dart';

class ServiceFormScreen extends StatefulWidget {
  const ServiceFormScreen({super.key});

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _saving = false;
  final List<XFile> _selectedImages = [];
  static const int _maxImages = 5;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final remaining = _maxImages - _selectedImages.length;
      if (remaining <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 5 images allowed.')),
          );
        }
        return;
      }
      final images = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.take(remaining));
        });
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to pick images.')));
      }
    }
  }

  Future<List<String>> _uploadImages(String serviceId) async {
    final urls = <String>[];
    for (var i = 0; i < _selectedImages.length; i++) {
      final file = _selectedImages[i];
      final ext = file.name.split('.').last;
      final mimeType = lookupMimeType(file.name) ?? 'image/jpeg';
      final ref = FirebaseStorage.instance.ref(
        'service_images/$serviceId/${i}_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );

      UploadTask task;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        task = ref.putData(bytes, SettableMetadata(contentType: mimeType));
      } else {
        task = ref.putFile(
          File(file.path),
          SettableMetadata(contentType: mimeType),
        );
      }
      final snapshot = await task;
      final url = await snapshot.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      FirestoreErrorHandler.showSignInRequired(context);
      return;
    }

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _saving = true;
    });

    var saved = false;
    try {
      final district = _districtController.text.trim();
      final city = _cityController.text.trim();
      final lat = double.tryParse(_latController.text.trim());
      final lng = double.tryParse(_lngController.text.trim());

      final docRef = await FirestoreRefs.services().add({
        'providerId': user.uid,
        'title': _titleController.text.trim(),
        'category': _categoryController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'district': district,
        'city': city,
        'location': '$city, $district',
        'lat': lat,
        'lng': lng,
        'description': _descriptionController.text.trim(),
        'status': 'pending',
        'imageUrls': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Upload images if any were selected
      if (_selectedImages.isNotEmpty) {
        final imageUrls = await _uploadImages(docRef.id);
        await docRef.update({'imageUrls': imageUrls});
      }

      saved = true;
    } on FirebaseException catch (e, st) {
      FirestoreErrorHandler.logWriteError(
        operation: 'services_add',
        error: e,
        stackTrace: st,
        details: {'uid': user.uid},
      );
      if (mounted) {
        FirestoreErrorHandler.showError(
          context,
          FirestoreErrorHandler.toUserMessage(e),
        );
      }
    } catch (e, st) {
      FirestoreErrorHandler.logWriteError(
        operation: 'services_add_unknown',
        error: e,
        stackTrace: st,
        details: {'uid': user.uid},
      );
      if (mounted) {
        FirestoreErrorHandler.showError(
          context,
          FirestoreErrorHandler.toUserMessage(e),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }

    if (saved && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) =>
                  Validators.requiredField(value, 'Title required'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
              validator: (value) =>
                  Validators.requiredField(value, 'Category required'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price (LKR)'),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  Validators.priceField(value, 'Price required'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _districtController,
              decoration: const InputDecoration(labelText: 'District'),
              validator: (value) =>
                  Validators.requiredField(value, 'District required'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City'),
              validator: (value) =>
                  Validators.requiredField(value, 'City required'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude (optional)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: Validators.optionalLatitude,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude (optional)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: Validators.optionalLongitude,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'If latitude/longitude are empty, map uses approximate city/district location.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            // ── Image Picker Section ──
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Service Images (${_selectedImages.length}/$_maxImages)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? FutureBuilder<Uint8List>(
                                    future: _selectedImages[index]
                                        .readAsBytes(),
                                    builder: (context, snap) {
                                      if (!snap.hasData) {
                                        return const SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      return Image.memory(
                                        snap.data!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  )
                                : Image.file(
                                    File(_selectedImages[index].path),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              validator: (value) =>
                  Validators.requiredField(value, 'Description required'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Post Service'),
            ),
          ],
        ),
      ),
    );

    if (kIsWeb) {
      return WebPageScaffold(
        title: 'Post Service',
        subtitle: 'Create a new service listing for seekers to discover.',
        useScaffold: true,
        child: body,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Post Service')),
      body: body,
    );
  }
}
