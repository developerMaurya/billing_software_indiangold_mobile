import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';
import 'package:flutter/material.dart';

class CustomerService {
  final CollectionReference _customersCollection = FirebaseFirestore.instance
      .collection('customers');

  // Create
  Future<void> addCustomer(CustomerModel customer) async {
    try {
      await _customersCollection.add({
        'name': customer.name,
        'mobile': customer.mobile,
        'address': customer.address,
        'email': customer.email,
        'pinCode': customer.pinCode,
        'whatsapp': customer.whatsapp,
        'status': customer.status,
        'country': customer.country,
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
  Future<void> updateCustomer(CustomerModel customer) async {
    if (customer.id == null) return;
    try {
      await _customersCollection.doc(customer.id).update({
        'name': customer.name,
        'mobile': customer.mobile,
        'address': customer.address,
        'email': customer.email,
        'pinCode': customer.pinCode,
        'whatsapp': customer.whatsapp,
        'status': customer.status,
        'country': customer.country,
      });
    } catch (e) {
      debugPrint("Error updating customer: $e");
      throw Exception('Failed to update customer');
    }
  }

  // Delete
  Future<void> deleteCustomer(String id) async {
    try {
      await _customersCollection.doc(id).delete();
    } catch (e) {
      debugPrint("Error deleting customer: $e");
      throw Exception('Failed to delete customer');
    }
  }
}
