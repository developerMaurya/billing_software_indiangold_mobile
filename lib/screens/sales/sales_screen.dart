import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../models/product_model.dart';
import '../../services/customer_service.dart';
import '../../services/product_service.dart';
import '../customers/customer_list_screen.dart';
import 'bill_generation_screen.dart';
import 'discount_tax_screen.dart';
import 'product_selection_screen.dart';

class SalesScreen extends StatefulWidget {
  final String? uid;
  final Map<String, dynamic>? companyData;
  const SalesScreen({super.key, this.uid, this.companyData});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  CustomerModel? _selectedCustomer;
  final List<Map<String, dynamic>> _selectedProducts = [];
  Map<String, dynamic>? _companyData;
  Map<String, dynamic>? _lastAddedProduct;
  bool _showAddedNotification = false;

  double get _totalAmount => _selectedProducts.fold(
    0.0,
    (sum, item) => sum + (item['quantity'] * item['price']),
  );

  int get _totalItems =>
      _selectedProducts.fold(0, (sum, item) => sum + item['quantity'] as int);

  @override
  void initState() {
    super.initState();
    if (widget.companyData != null) {
      _companyData = widget.companyData;
    } else {
      _fetchCompanyData();
    }
  }

  @override
  void didUpdateWidget(SalesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.companyData != oldWidget.companyData &&
        widget.companyData != null) {
      setState(() {
        _companyData = widget.companyData;
      });
    }
  }

  Future<void> _fetchCompanyData() async {
    try {
      debugPrint('Fetching company data...');
      String? targetUid = widget.uid;

      if (targetUid == null) {
        final user = FirebaseAuth.instance.currentUser;
        targetUid = user?.uid;
      }

      debugPrint('Target UID for Company Data: $targetUid');

      if (targetUid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('shops')
            .doc(targetUid)
            .get();
        debugPrint('Document exists: ${doc.exists}');
        if (doc.exists) {
          debugPrint('Document data: ${doc.data()}');
          if (mounted) {
            setState(() => _companyData = doc.data());
          }
          debugPrint('Company data set successfully');
        } else {
          debugPrint('Document does not exist in shops collection');
        }
      } else {
        debugPrint('No valid UID found for Company Data');
      }
    } catch (e) {
      debugPrint('Error fetching company data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Sales',
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
      body: Column(
        children: [
          // Customer Selection
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Customer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _selectedCustomer != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedCustomer!.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Email: ${_selectedCustomer!.email}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    'Mobile: ${_selectedCustomer!.mobile}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    'Address: ${_selectedCustomer!.address}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if (_selectedCustomer!.pinCode != null &&
                                      _selectedCustomer!.pinCode!.isNotEmpty)
                                    Text(
                                      'Pincode: ${_selectedCustomer!.pinCode}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                ],
                              )
                            : const Text(
                                'No customer selected',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      Column(
                        children: [
                          TextButton.icon(
                            onPressed: _selectCustomer,
                            icon: const Icon(Icons.search),
                            label: const Text('Search'),
                          ),
                          TextButton.icon(
                            onPressed: _addManualCustomer,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Manual'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Products Selection
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Selected Products',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addProduct,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Total Summary
                    if (_selectedProducts.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Total Items: $_totalItems',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              'Total Amount: ₹${_totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Added notification
                    if (_showAddedNotification && _lastAddedProduct != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade200.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Product Added!',
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Items: ${_selectedProducts.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Qty: ${_lastAddedProduct!['quantity']} x ₹${_lastAddedProduct!['price'].toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    'Amount: ₹${(_lastAddedProduct!['quantity'] * _lastAddedProduct!['price']).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total Amount: ₹${_totalAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    Expanded(
                      child: _selectedProducts.isEmpty
                          ? const Center(child: Text('No products selected'))
                          : ListView.builder(
                              itemCount: _selectedProducts.length,
                              itemBuilder: (context, index) {
                                final item = _selectedProducts[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: item['product'].imageUrl != null
                                        ? (item['product'].imageUrl!.startsWith(
                                                'http',
                                              )
                                              ? Image.network(
                                                  item['product'].imageUrl!,
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.file(
                                                  File(
                                                    item['product'].imageUrl!,
                                                  ),
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                ))
                                        : const Icon(Icons.inventory_2),
                                    title: Text(item['product'].name),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Qty: ${item['quantity']} x ₹${item['price']}',
                                        ),
                                        Text(
                                          'Amount: ₹${(item['quantity'] * item['price']).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeProduct(index),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Actions
          if (_selectedProducts.isNotEmpty)
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearAll,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _continueToDiscount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _selectCustomer() async {
    final result = await Navigator.push<CustomerModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerListScreen(forSelection: true),
      ),
    );
    if (result != null) {
      setState(() => _selectedCustomer = result);
    }
  }

  void _addManualCustomer() async {
    final result = await Navigator.push<CustomerModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerListScreen(addManual: true),
      ),
    );
    if (result != null) {
      setState(() => _selectedCustomer = result);
    }
  }

  void _addProduct() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const ProductSelectionScreen()),
    );
    if (result != null) {
      setState(() {
        _selectedProducts.add(result);
        _lastAddedProduct = result;
        _showAddedNotification = true;
      });

      // Hide the notification after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _showAddedNotification = false;
            _lastAddedProduct = null;
          });
        }
      });
    }
  }

  void _removeProduct(int index) {
    setState(() => _selectedProducts.removeAt(index));
  }

  void _clearAll() {
    setState(() {
      _selectedCustomer = null;
      _selectedProducts.clear();
      _showAddedNotification = false;
      _lastAddedProduct = null;
    });
  }

  void _continueToDiscount() {
    debugPrint('Continue button pressed');
    debugPrint('Selected customer: $_selectedCustomer');
    debugPrint('Company data: $_companyData');
    debugPrint('Selected products count: ${_selectedProducts.length}');

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint('Navigating to DiscountTaxScreen');
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DiscountTaxScreen(
            customer: _selectedCustomer!,
            selectedProducts: _selectedProducts,
            companyData: _companyData,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to DiscountTaxScreen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
