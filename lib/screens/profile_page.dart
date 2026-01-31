import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ProfilePage extends StatefulWidget {
  final String? uid;
  const ProfilePage({super.key, this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _gstController = TextEditingController();
  final _panController = TextEditingController();
  final _licenseController = TextEditingController();
  final _statusController = TextEditingController();
  final _countryController = TextEditingController();

  File? _logoFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  Map<String, dynamic>? _companyData;
  String? _logoUrl;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _permanentAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _licenseController.dispose();
    _statusController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('ProfilePage: Loading profile data...');
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('ProfilePage: Current user: $user');

      // Pre-fill from Auth
      if (user != null) {
        if (_emailController.text.isEmpty)
          _emailController.text = user.email ?? '';
        if (_phoneController.text.isEmpty)
          _phoneController.text = user.phoneNumber ?? '';
      }

      final targetUid = widget.uid ?? user?.uid;
      debugPrint('ProfilePage: Target UID: $targetUid');

      if (targetUid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('shops')
            .doc(targetUid)
            .get();

        debugPrint('ProfilePage: Document exists: ${doc.exists}');
        if (doc.exists) {
          final data = doc.data()!;
          debugPrint('ProfilePage: Document data keys: ${data.keys.toList()}');
          debugPrint('ProfilePage: Full Data: $data');
          setState(() {
            _companyData = data;
            _nameController.text = (data['name'] ?? '').toString();
            _emailController.text =
                (data['email']?.toString().isNotEmpty == true)
                ? data['email']
                : (user?.email ?? '');
            _phoneController.text =
                (data['phone']?.toString().isNotEmpty == true)
                ? data['phone']
                : (user?.phoneNumber ?? '');
            _addressController.text = (data['address'] ?? '').toString();
            _permanentAddressController.text = (data['permanentAddress'] ?? '')
                .toString();
            _cityController.text = (data['city'] ?? '').toString();
            _stateController.text = (data['state'] ?? '').toString();
            _pinCodeController.text = (data['pinCode'] ?? '').toString();
            _gstController.text = (data['gst'] ?? '').toString();
            _panController.text = (data['pan'] ?? '').toString();
            _licenseController.text = (data['license'] ?? '').toString();
            _statusController.text = (data['status'] ?? 'Active').toString();
            _countryController.text = (data['country'] ?? 'India').toString();
            _logoUrl =
                data['company_logo'] ??
                data['logo']; // Check company_logo first
          });
          debugPrint('ProfilePage: Data loaded successfully');
        } else {
          debugPrint('ProfilePage: Document does not exist - setting defaults');
          // Set default values for new profile but keep auth data
          setState(() {
            _statusController.text = 'Active';
            _countryController.text = 'India';
            if (user != null) {
              _emailController.text = user.email ?? '';
              _phoneController.text = user.phoneNumber ?? '';
            }
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Profile not found. Creating new profile from login details.',
                ),
                backgroundColor: Colors.blue,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('ProfilePage: Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        debugPrint('Image Picked: ${pickedFile.path}');
        debugPrint('Original Name: ${pickedFile.name}');
        setState(() {
          _logoFile = File(pickedFile.path);
        });
      } else {
        debugPrint('Image selection cancelled');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadLogo() async {
    if (_logoFile == null) return _logoUrl;

    try {
      final user = FirebaseAuth.instance.currentUser;
      final targetUid = widget.uid ?? user?.uid;

      if (targetUid == null) {
        debugPrint('Error: No User ID found');
        return null;
      }

      // 1. Get Original Filename
      String fileName = path.basename(_logoFile!.path);
      if (fileName.isEmpty) {
        fileName = '${targetUid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      debugPrint('Processing Image: $fileName');

      // 2. SAVE LOCALLY (First priority as requested)
      String? localSavedPath;
      try {
        final appDir = await getApplicationDocumentsDirectory();
        // Create the specific folder structure: uploads/images
        final saveDir = Directory(path.join(appDir.path, 'uploads', 'images'));

        if (!await saveDir.exists()) {
          await saveDir.create(recursive: true);
        }

        final targetFile = File(path.join(saveDir.path, fileName));

        // Copy the picked file to this new location
        await _logoFile!.copy(targetFile.path);
        localSavedPath = targetFile.path;

        debugPrint('Image saved locally to: $localSavedPath');
      } catch (e) {
        debugPrint('Error saving locally: $e');
        // Fallback: Use the original picked path so UI updates immediately
        localSavedPath = _logoFile!.path;
      }

      // 3. UPLOAD TO FIREBASE (Cloud Sync)
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('uploads')
            .child('images')
            .child(fileName);

        debugPrint('Uploading to Firebase: uploads/images/$fileName');
        await storageRef.putFile(_logoFile!);
        final downloadUrl = await storageRef.getDownloadURL();
        debugPrint('Firebase Download URL: $downloadUrl');

        // Return Cloud URL if successful
        return downloadUrl;
      } catch (firebaseError) {
        debugPrint('Firebase Upload Failed: $firebaseError');

        // Return local path fallback so UI updates
        debugPrint('Returning local path fallback: $localSavedPath');
        return localSavedPath;
      }
    } catch (e) {
      debugPrint('Critial error in _uploadLogo: $e');
      return null;
    }
  }

  Future<void> _removePhoto() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text(
          'Are you sure you want to remove your profile photo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final targetUid = widget.uid ?? user?.uid;

      if (targetUid != null) {
        // Remove from Firestore
        await FirebaseFirestore.instance
            .collection('shops')
            .doc(targetUid)
            .update({
              'company_logo': null,
              'logo': null, // Clear legacy field too
            });

        // Update local state
        setState(() {
          _logoFile = null;
          _logoUrl = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo removed successfully')),
          );
        }

        // Try to delete from local storage if exists
        try {
          final appDir = await getApplicationDocumentsDirectory();
          // We try to guess the filename or delete all in the folder for this user.
          // Since we don't know the exact file name without re-fetching,
          // we'll just leave the file or clear the state. Clearing state is enough for UI.
        } catch (e) {
          debugPrint("Error clearing local file: $e");
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing photo: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final targetUid = widget.uid ?? user?.uid;

      if (targetUid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: No valid User ID found.')),
          );
        }
        return;
      }

      debugPrint('Starting profile save...');

      // Upload logo first
      final logoUrl = await _uploadLogo();
      debugPrint('Logo URL after upload: $logoUrl');

      // Prepare data
      final updatedData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'permanentAddress': _permanentAddressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pinCode': _pinCodeController.text.trim(),
        'gst': _gstController.text.trim(),
        'pan': _panController.text.trim(),
        'license': _licenseController.text.trim(),
        'status': _statusController.text.trim(),
        'country': _countryController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only add logo if we have one
      if (logoUrl != null && logoUrl.isNotEmpty) {
        updatedData['company_logo'] = logoUrl;
      } else if (_logoUrl != null && _logoUrl!.isNotEmpty) {
        // Keep existing logo
        updatedData['company_logo'] = _logoUrl;
      }

      debugPrint('--------------- PROFILE UPDATE DATA ---------------');
      debugPrint(updatedData.toString());
      debugPrint('---------------------------------------------------');

      await FirebaseFirestore.instance
          .collection('shops')
          .doc(targetUid)
          .set(updatedData, SetOptions(merge: true));

      setState(() {
        if (logoUrl != null) {
          _logoUrl = logoUrl;
        }
        _logoFile = null; // Clear picked file
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload data
      await _loadProfileData();
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo Section
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.green.shade700,
                            width: 2,
                          ),
                          image: _logoFile != null
                              ? DecorationImage(
                                  image: FileImage(_logoFile!),
                                  fit: BoxFit.cover,
                                )
                              : _logoUrl != null && _logoUrl!.isNotEmpty
                              ? (_logoUrl!.startsWith('http')
                                    ? DecorationImage(
                                        image: NetworkImage(_logoUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : DecorationImage(
                                        // It's a local path
                                        image: FileImage(File(_logoUrl!)),
                                        fit: BoxFit.cover,
                                      ))
                              : null,
                        ),
                        child: _logoFile == null && _logoUrl == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey.shade400,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_logoFile != null ||
                        (_logoUrl != null && _logoUrl!.isNotEmpty))
                      TextButton.icon(
                        onPressed: _removePhoto,
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        label: const Text(
                          'Remove Photo',
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                    else
                      Text(
                        'Tap to change photo',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Information Section
                    // Information Section
                    _buildEditForm(),

                    const SizedBox(height: 24),

                    // Save Button (only in edit mode)
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEditForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Company Name *',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Company name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      prefixIcon: Icon(Icons.map),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pinCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Pin Code',
                      prefixIcon: Icon(Icons.pin_drop),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      prefixIcon: Icon(Icons.flag),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _licenseController,
              decoration: const InputDecoration(
                labelText: 'License Number',
                prefixIcon: Icon(Icons.card_membership),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gstController,
              decoration: const InputDecoration(
                labelText: 'GST Number',
                prefixIcon: Icon(Icons.receipt),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _panController,
              decoration: const InputDecoration(
                labelText: 'PAN Number',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
