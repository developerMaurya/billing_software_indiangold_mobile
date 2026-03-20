import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'cloudinary_service.dart';

class CustomerService {
  final CollectionReference _customersCollection = FirebaseFirestore.instance
      .collection('customers');

  // Create
  Future<void> addCustomer(CustomerModel customer, File? imageFile) async {
    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile);
      }

      await _customersCollection.add({
        'name': customer.name,
        'mobile': customer.mobile,
        'address': customer.address,
        'email': customer.email,
        'pinCode': customer.pinCode,
        'whatsapp': customer.whatsapp,
        'gstNumber': customer.gstNumber,
        'city': customer.city,
        'state': customer.state,
        'permanentAddress': customer.permanentAddress,
        'status': customer.status,
        'country': customer.country,
        'imageUrl': imageUrl,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint("Error adding customer: $e");
      throw Exception('Failed to add customer');
    }
  }

  // Read
  Stream<List<CustomerModel>> getCustomers() {
    return _customersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CustomerModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  // Update
  Future<void> updateCustomer(
    CustomerModel customer,
    File? newImageFile, {
    bool deleteImage = false,
  }) async {
    if (customer.id == null) return;
    try {
      String? imageUrl = customer.imageUrl;

      if (deleteImage) {
        imageUrl = null;
        // Optionally delete old image from storage if needed
      } else if (newImageFile != null) {
        imageUrl = await _uploadImage(newImageFile);
      }

      await _customersCollection.doc(customer.id).update({
        'name': customer.name,
        'mobile': customer.mobile,
        'address': customer.address,
        'email': customer.email,
        'pinCode': customer.pinCode,
        'whatsapp': customer.whatsapp,
        'gstNumber': customer.gstNumber,
        'city': customer.city,
        'state': customer.state,
        'permanentAddress': customer.permanentAddress,
        'status': customer.status,
        'country': customer.country,
        'imageUrl': imageUrl,
      });
    } catch (e) {
      debugPrint("Error updating customer: $e");
      throw Exception('Failed to update customer');
    }
  }

  // Delete
  Future<void> deleteCustomer(String id, String? imageUrl) async {
    try {
      await _customersCollection.doc(id).delete();
      // Cloudinary image deletion logic is skipped here.
    } catch (e) {
      debugPrint("Error deleting customer: $e");
      throw Exception('Failed to delete customer');
    }
  }

  // Helper: Upload Image (Hybrid: Local + Cloud)
  Future<String> _uploadImage(File file) async {
    // 1. Prepare Filename
    String fileName = path.basename(file.path);
    if (fileName.isEmpty || !fileName.contains('.')) {
      fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    }

    // 2. SAVE LOCALLY (First priority)
    String? localSavedPath;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final saveDir = Directory(path.join(appDir.path, 'uploads', 'customers'));
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }
      final targetFile = File(path.join(saveDir.path, fileName));
      await file.copy(targetFile.path);
      localSavedPath = targetFile.path;
      debugPrint('Customer image saved locally: $localSavedPath');
    } catch (e) {
      debugPrint("Error saving locally: $e");
      // Fallback to original path if copy fails
      localSavedPath = file.path;
    }

    // 3. UPLOAD TO CLOUDINARY
    try {
      String? cloudinaryUrl = await CloudinaryService.uploadImage(file, folder: "customers");
      if (cloudinaryUrl != null) {
        return cloudinaryUrl;
      }
      return localSavedPath ?? file.path;
    } catch (e) {
      debugPrint("Error uploading customer image: $e");
      return localSavedPath ?? file.path;
    }
  }
}
