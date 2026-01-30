import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/customer_model.dart';
import 'package:flutter/material.dart';

class CustomerService {
  final CollectionReference _customersCollection = FirebaseFirestore.instance
      .collection('customers');
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
    File? newImageFile,
  ) async {
    if (customer.id == null) return;
    try {
      String? imageUrl = customer.imageUrl;
      if (newImageFile != null) {
        imageUrl = await _uploadImage(newImageFile);
      }

      await _customersCollection.doc(customer.id).update({
        'name': customer.name,
        'mobile': customer.mobile,
        'address': customer.address,
        'email': customer.email,
        'pinCode': customer.pinCode,
        'whatsapp': customer.whatsapp,
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
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          debugPrint("Error deleting customer image: $e");
        }
      }
    } catch (e) {
      debugPrint("Error deleting customer: $e");
      throw Exception('Failed to delete customer');
    }
  }

  // Helper: Upload Image
  Future<String> _uploadImage(File file) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('customer_images/$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading customer image: $e");
      throw Exception('Failed to upload image');
    }
  }
}
