import 'package:flutter/material.dart';
import '../../models/customer_model.dart';

class BillPreviewScreen extends StatelessWidget {
  final CustomerModel customer;
  final List<Map<String, dynamic>> selectedProducts;
  final Map<String, dynamic>? companyData;
  final double discountPercent;
  final double gstPercent;
  final bool isInclusiveGst;

  const BillPreviewScreen({
    super.key,
    required this.customer,
    required this.selectedProducts,
    this.companyData,
    required this.discountPercent,
    required this.gstPercent,
    required this.isInclusiveGst,
  });

  double get subtotal => selectedProducts.fold(
    0.0,
    (sum, item) => sum + (item['quantity'] * item['price']),
  );

  double get discountAmount => subtotal * (discountPercent / 100);

  double get taxableAmount => subtotal - discountAmount;

  double get gstAmount {
    if (isInclusiveGst) {
      return taxableAmount - (taxableAmount / (1 + gstPercent / 100));
    } else {
      return taxableAmount * (gstPercent / 100);
    }
  }

  double get totalAmount {
    if (isInclusiveGst) {
      return taxableAmount;
    } else {
      return taxableAmount + gstAmount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Bill Preview',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        companyData?['name'] ?? 'Company Name',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        companyData?['address'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (companyData?['pinCode'] != null) ...[
                        Text(
                          'Pincode: ${companyData!['pinCode']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                      Text(
                        'Phone: ${companyData?['mobile'] ?? ''} | GST: ${companyData?['gst'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(
                        'State: Maharashtra | Country: India',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 32),

                // Bill Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bill No: Preview',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Date: ${DateTime.now().toString().split(' ')[0]}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Customer Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bill To:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Name: ${customer.name}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Mobile: ${customer.mobile} | WhatsApp: ${customer.whatsapp ?? customer.mobile}',
                      ),
                      Text('Address: ${customer.address}'),
                      if (customer.pinCode != null) ...[
                        Text('Pincode: ${customer.pinCode}'),
                      ],
                      Text(
                        'Status: ${customer.status} | Country: ${customer.country}',
                      ),
                      if (customer.email != null) ...[
                        Text('Email: ${customer.email}'),
                      ],
                      const Text(
                        'GST No: Not Applicable',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Products Table
                const Text(
                  'Items:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Item',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'HSN',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Qty',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'MRP',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Rate',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Amount',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...selectedProducts.map((item) {
                      final product = item['product'];
                      final quantity = item['quantity'] as int;
                      final price = item['price'] as double;
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(product.name),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(product.hsnCode),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(quantity.toString()),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text('₹${product.mrp.toStringAsFixed(2)}'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text('₹${price.toStringAsFixed(2)}'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              '₹${(quantity * price).toStringAsFixed(2)}',
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 16),

                // Totals
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '₹${subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      if (discountPercent > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Discount (${discountPercent}%):',
                              style: const TextStyle(color: Colors.red),
                            ),
                            Text(
                              '-₹${discountAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Taxable Amount:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '₹${taxableAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'IGST (${gstPercent}% ${isInclusiveGst ? 'Inclusive' : 'Exclusive'}):',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '₹${gstAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'UGST (2.5% Sharing):',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '₹${(gstAmount * 0.025).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const Divider(height: 16, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'राशि देय / Amount Payable',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text(
                              'कुल भुगतान राशि / Total Paid Amount: ₹0.00',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Authorization/Signature
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Authorization / प्राधिकरण',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'Customer Signature',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Container(height: 1, color: Colors.black),
                                const Text(
                                  'हस्ताक्षर',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'Authorized Signatory',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  companyData?['name'] ?? 'Company Name',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Container(height: 1, color: Colors.black),
                                const Text(
                                  'हस्ताक्षर',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Footer
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Thank you for your business!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generated on ${DateTime.now().toString().split(' ')[0]}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
