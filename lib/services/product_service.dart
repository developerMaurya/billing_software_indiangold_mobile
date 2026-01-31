import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductService {
  late final CollectionReference _productsCollection;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _uid;

  ProductService() : _uid = FirebaseAuth.instance.currentUser?.uid ?? '' {
    if (_uid.isEmpty) {
      debugPrint("Warning: No user logged in for ProductService");
      _productsCollection = FirebaseFirestore.instance.collection('products');
    } else {
      _productsCollection = FirebaseFirestore.instance.collection('products');
    }
  }

  // Create
  Future<void> addProduct(ProductModel product, File? imageFile) async {
    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile);
      }

      await _productsCollection.add({
        'name': product.name,
        'description': product.description,
        'hsnCode': product.hsnCode,
        'batchNo': product.batchNo,
        'mrp': product.mrp,
        'buyRate': product.buyRate,
        'givenRate': product.givenRate,
        'quantity': product.quantity,
        'category': product.category,
        'productType': product.productType,
        'unitSize': product.unitSize,
        'imageUrl': imageUrl,
        'expireDate': product.expireDate?.millisecondsSinceEpoch,
        'shopId': _uid,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint("Error adding product: $e");
      throw Exception('Failed to add product');
    }
  }

  // Read
  Stream<List<ProductModel>> getProducts() {
    return _productsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ProductModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  // Update
  Future<void> updateProduct(ProductModel product, File? newImageFile) async {
    if (product.id == null) return;
    try {
      String? imageUrl = product.imageUrl;
      if (newImageFile != null) {
        imageUrl = await _uploadImage(newImageFile);
      }

      await _productsCollection.doc(product.id).update({
        'name': product.name,
        'description': product.description,
        'hsnCode': product.hsnCode,
        'batchNo': product.batchNo,
        'mrp': product.mrp,
        'buyRate': product.buyRate,
        'givenRate': product.givenRate,
        'quantity': product.quantity,
        'category': product.category,
        'productType': product.productType,
        'unitSize': product.unitSize,
        'imageUrl': imageUrl,
        'expireDate': product.expireDate?.millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint("Error updating product: $e");
      throw Exception('Failed to update product');
    }
  }

  // Delete
  Future<void> deleteProduct(String id, String? imageUrl) async {
    try {
      await _productsCollection.doc(id).delete();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          debugPrint("Error deleting image: $e");
        }
      }
    } catch (e) {
      debugPrint("Error deleting product: $e");
      throw Exception('Failed to delete product');
    }
  }

  // Helper: Upload Image
  Future<String> _uploadImage(File file) async {
    try {
      if (_uid.isEmpty) throw Exception('User not logged in');
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = 'prod_$timestamp.jpg';
      Reference ref = _storage.ref().child('users/$_uid/products/$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading image: $e");
      throw Exception('Failed to upload image');
    }
  }
}
