import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import '../../models/sale_model.dart';
import '../../services/product_service.dart';
import '../../services/sale_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final SaleService _saleService = SaleService();
  final ProductService _productService = ProductService();

  String _selectedPeriod = 'This Month';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
    'All Time',
  ];

  @override
  void initState() {
    super.initState();
    _setDateRange(_selectedPeriod);
  }

  void _setDateRange(String period) {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case 'Today':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'This Week':
          final monday = now.subtract(Duration(days: now.weekday - 1));
          _startDate = DateTime(monday.year, monday.month, monday.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'This Month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case 'This Year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
          break;
        case 'All Time':
          _startDate = null;
          _endDate = null;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Reports & Analytics',
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
          // Period Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Text(
                  'Period:',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _periods.map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _setDateRange(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Reports Grid
          Expanded(
            child: StreamBuilder<List<SaleModel>>(
              stream: _saleService.getSales(),
              builder: (context, salesSnapshot) {
                return StreamBuilder<List<ProductModel>>(
                  stream: _productService.getProducts(),
                  builder: (context, productsSnapshot) {
                    if (salesSnapshot.connectionState ==
                            ConnectionState.waiting ||
                        productsSnapshot.connectionState ==
                            ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (salesSnapshot.hasError || productsSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${salesSnapshot.error ?? productsSnapshot.error}',
                        ),
                      );
                    }

                    final sales = _filterSalesByDate(salesSnapshot.data ?? []);
                    final products = productsSnapshot.data ?? [];

                    final reportData = _calculateReportData(sales, products);

                    return GridView.count(
                      padding: const EdgeInsets.all(16),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildReportCard(
                          'Total Sales',
                          '₹${reportData['totalSales']?.toStringAsFixed(2) ?? '0.00'}',
                          Icons.currency_rupee,
                          Colors.green,
                        ),
                        _buildReportCard(
                          'Total Orders',
                          '${reportData['totalOrders'] ?? 0}',
                          Icons.receipt,
                          Colors.blue,
                        ),
                        _buildReportCard(
                          'Avg Order Value',
                          '₹${reportData['avgOrderValue']?.toStringAsFixed(2) ?? '0.00'}',
                          Icons.trending_up,
                          Colors.orange,
                        ),
                        _buildReportCard(
                          'Top Product',
                          reportData['topProduct'] ?? 'N/A',
                          Icons.star,
                          Colors.purple,
                        ),
                        _buildReportCard(
                          'Low Stock Items',
                          '${reportData['lowStockItems'] ?? 0}',
                          Icons.warning,
                          Colors.red,
                        ),
                        _buildReportCard(
                          'Out of Stock',
                          '${reportData['outOfStockItems'] ?? 0}',
                          Icons.error,
                          Colors.red.shade800,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Detailed Reports Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detailed Reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildDetailedReportButton(
                  'Sales by Product',
                  Icons.inventory,
                  _showSalesByProduct,
                ),
                _buildDetailedReportButton(
                  'Sales by Date',
                  Icons.date_range,
                  _showSalesByDate,
                ),
                _buildDetailedReportButton(
                  'Top Customers',
                  Icons.people,
                  _showTopCustomers,
                ),
                _buildDetailedReportButton(
                  'Stock Report',
                  Icons.warehouse,
                  _showStockReport,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<SaleModel> _filterSalesByDate(List<SaleModel> sales) {
    if (_startDate == null || _endDate == null) return sales;

    return sales.where((sale) {
      return sale.saleDate.isAfter(
            _startDate!.subtract(const Duration(days: 1)),
          ) &&
          sale.saleDate.isBefore(_endDate!.add(const Duration(days: 1)));
    }).toList();
  }

  Map<String, dynamic> _calculateReportData(
    List<SaleModel> sales,
    List<ProductModel> products,
  ) {
    double totalSales = 0.0;
    int totalOrders = sales.length;
    double avgOrderValue = 0.0;
    String topProduct = 'N/A';
    int lowStockItems = 0;
    int outOfStockItems = 0;

    // Calculate sales metrics
    if (sales.isNotEmpty) {
      totalSales = sales.fold(0.0, (sum, sale) => sum + sale.totalAmount);
      avgOrderValue = totalSales / totalOrders;
    }

    // Calculate top product
    final productSales = <String, Map<String, dynamic>>{};
    for (final sale in sales) {
      for (final item in sale.items) {
        final productId = item.productId;
        final quantity = item.quantity;
        final revenue = item.amount;
        if (productSales.containsKey(productId)) {
          productSales[productId]!['quantity'] += quantity;
          productSales[productId]!['revenue'] += revenue;
        } else {
          productSales[productId] = {
            'name': item.productName,
            'quantity': quantity,
            'revenue': revenue,
          };
        }
      }
    }

    // Calculate stock metrics
    final soldQuantities = <String, int>{};
    for (final sale in sales) {
      for (final item in sale.items) {
        final productId = item.productId;
        soldQuantities[productId] =
            (soldQuantities[productId] ?? 0) + item.quantity;
      }
    }

    for (final product in products) {
      final sold = soldQuantities[product.id] ?? 0;
      final remaining = product.quantity - sold;

      if (remaining <= 0) {
        outOfStockItems++;
      } else if (remaining <= 10) {
        lowStockItems++;
      }
    }

    return {
      'totalSales': totalSales,
      'totalOrders': totalOrders,
      'avgOrderValue': avgOrderValue,
      'topProduct': topProduct,
      'lowStockItems': lowStockItems,
      'outOfStockItems': outOfStockItems,
    };
  }

  Widget _buildReportCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedReportButton(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.green.shade700),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showSalesByProduct() async {
    final sales = await FirebaseFirestore.instance.collection('sales').get();
    final salesData = sales.docs
        .map((doc) => SaleModel.fromMap(doc.data(), doc.id))
        .toList();

    final productSales = <String, Map<String, dynamic>>{};

    for (final sale in salesData) {
      for (final item in sale.items) {
        final productId = item.productId;
        final quantity = item.quantity;
        final revenue = item.amount;

        if (productSales.containsKey(productId)) {
          productSales[productId]!['quantity'] += quantity;
          productSales[productId]!['revenue'] += revenue;
        } else {
          productSales[productId] = {
            'name': item.productName,
            'quantity': quantity,
            'revenue': revenue,
          };
        }
      }
    }

    final sortedProducts = productSales.values.toList()
      ..sort(
        (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double),
      );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sales by Product'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sortedProducts.length,
            itemBuilder: (context, index) {
              final product = sortedProducts[index];
              return ListTile(
                title: Text(product['name']),
                subtitle: Text('Qty: ${product['quantity']}'),
                trailing: Text('₹${product['revenue'].toStringAsFixed(2)}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSalesByDate() async {
    final sales = await FirebaseFirestore.instance.collection('sales').get();
    final salesData = sales.docs
        .map((doc) => SaleModel.fromMap(doc.data(), doc.id))
        .toList();

    final dateSales = <String, Map<String, dynamic>>{};

    for (final sale in salesData) {
      final dateKey = DateFormat('yyyy-MM-dd').format(sale.saleDate);
      if (dateSales.containsKey(dateKey)) {
        dateSales[dateKey]!['orders'] += 1;
        dateSales[dateKey]!['revenue'] += sale.totalAmount;
      } else {
        dateSales[dateKey] = {
          'date': sale.saleDate,
          'orders': 1,
          'revenue': sale.totalAmount,
        };
      }
    }

    final sortedDates = dateSales.values.toList()
      ..sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
      );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sales by Date'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final dateData = sortedDates[index];
              return ListTile(
                title: Text(DateFormat('dd/MM/yyyy').format(dateData['date'])),
                subtitle: Text('${dateData['orders']} orders'),
                trailing: Text('₹${dateData['revenue'].toStringAsFixed(2)}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTopCustomers() async {
    final sales = await FirebaseFirestore.instance.collection('sales').get();
    final salesData = sales.docs
        .map((doc) => SaleModel.fromMap(doc.data(), doc.id))
        .toList();

    final customerSales = <String, Map<String, dynamic>>{};

    for (final sale in salesData) {
      final customerKey = sale.customerMobile ?? sale.customerName ?? 'Walk-in';
      if (customerSales.containsKey(customerKey)) {
        customerSales[customerKey]!['orders'] += 1;
        customerSales[customerKey]!['total'] += sale.totalAmount;
      } else {
        customerSales[customerKey] = {
          'name': sale.customerName ?? 'Walk-in Customer',
          'mobile': sale.customerMobile,
          'orders': 1,
          'total': sale.totalAmount,
        };
      }
    }

    final sortedCustomers = customerSales.values.toList()
      ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Top Customers'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sortedCustomers.take(10).length,
            itemBuilder: (context, index) {
              final customer = sortedCustomers[index];
              return ListTile(
                title: Text(customer['name']),
                subtitle: Text(
                  '${customer['orders']} orders • ${customer['mobile'] ?? ''}',
                ),
                trailing: Text('₹${customer['total'].toStringAsFixed(2)}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStockReport() async {
    final products = await FirebaseFirestore.instance
        .collection('products')
        .get();
    final productsData = products.docs
        .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
        .toList();

    // This would show a detailed stock report
    // For now, just show a summary
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stock Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total Products: ${productsData.length}'),
            const SizedBox(height: 8),
            Text(
              'In Stock: ${productsData.where((p) => p.quantity > 0).length}',
            ),
            const SizedBox(height: 8),
            Text(
              'Low Stock (≤10): ${productsData.where((p) => p.quantity > 0 && p.quantity <= 10).length}',
            ),
            const SizedBox(height: 8),
            Text(
              'Out of Stock: ${productsData.where((p) => p.quantity <= 0).length}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
