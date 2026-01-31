import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/product_model.dart';
import '../../models/sale_model.dart';
import '../../services/product_service.dart';
import '../../services/sale_service.dart';
import '../../utils/app_theme_provider.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final ProductService _productService = ProductService();
  final SaleService _saleService = SaleService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _searchQuery = '';
  Map<String, int> _soldQuantities = {};

  final List<String> _categories = [
    'All',
    'Bottle',
    'Capsule',
    'Syrup',
    'Tablet',
    'Injection',
    'Cream',
    'Ointment',
    'Powder',
    'Sachet',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadSoldQuantities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadSoldQuantities() async {
    try {
      final sales = await _saleService.getSales().first;
      final soldMap = <String, int>{};

      for (final sale in sales) {
        for (final item in sale.items) {
          final productId = item.productId;
          soldMap[productId] = (soldMap[productId] ?? 0) + item.quantity;
        }
      }

      setState(() {
        _soldQuantities = soldMap;
      });
    } catch (e) {
      debugPrint('Error loading sold quantities: $e');
    }
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    return products.where((product) {
      // Category filter
      if (_selectedCategory != 'All' &&
          product.productType != _selectedCategory) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery;
        return product.name.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query) ||
            product.hsnCode.toLowerCase().contains(query) ||
            (product.productType?.toLowerCase().contains(query) ?? false);
      }

      return true;
    }).toList();
  }

  int _getSoldQuantity(String productId) {
    return _soldQuantities[productId] ?? 0;
  }

  int _getRemainingStock(ProductModel product) {
    final sold = _getSoldQuantity(product.id!);
    return product.quantity - sold;
  }

  Color _getStockStatusColor(int remaining) {
    if (remaining <= 0) return Colors.red;
    if (remaining <= 10) return Colors.orange;
    return Colors.green;
  }

  String _getStockStatusText(int remaining) {
    if (remaining <= 0) return 'Out of Stock';
    if (remaining <= 10) return 'Low Stock';
    return 'In Stock';
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Provider.of<AppTheme>(context);
    return Scaffold(
      backgroundColor: appTheme.colors.background,
      appBar: AppBar(
        title: const Text(
          'Inventory Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: appTheme.colors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            onPressed: _loadSoldQuantities,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                // Category Filter
                Row(
                  children: [
                    const Text(
                      'Filter by Type:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Inventory Summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: StreamBuilder<List<ProductModel>>(
              stream: _productService.getProducts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final products = snapshot.data!;
                final totalProducts = products.length;
                final lowStockProducts = products.where((p) {
                  final remaining = _getRemainingStock(p);
                  return remaining <= 10 && remaining > 0;
                }).length;
                final outOfStockProducts = products
                    .where((p) => _getRemainingStock(p) <= 0)
                    .length;
                final totalValue = products.fold<double>(
                  0.0,
                  (sum, p) => sum + (p.quantity * p.buyRate),
                );

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryCard(
                      'Total Products',
                      totalProducts.toString(),
                      Icons.inventory,
                      appTheme,
                    ),
                    _buildSummaryCard(
                      'Low Stock',
                      lowStockProducts.toString(),
                      Icons.warning,
                      appTheme,
                      Colors.orange,
                    ),
                    _buildSummaryCard(
                      'Out of Stock',
                      outOfStockProducts.toString(),
                      Icons.error,
                      appTheme,
                      Colors.red,
                    ),
                    _buildSummaryCard(
                      'Total Value',
                      '₹${totalValue.toStringAsFixed(0)}',
                      Icons.currency_rupee,
                      appTheme,
                    ),
                  ],
                );
              },
            ),
          ),

          // Products List
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _productService.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final filteredProducts = _filterProducts(snapshot.data!);

                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products match your search',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildInventoryCard(product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    AppTheme appTheme, [
    Color? color,
  ]) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color ?? appTheme.colors.primary, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color ?? Colors.black87,
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryCard(ProductModel product) {
    final sold = _getSoldQuantity(product.id!);
    final remaining = _getRemainingStock(product);
    final stockStatusColor = _getStockStatusColor(remaining);
    final stockStatusText = _getStockStatusText(remaining);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Header
            Row(
              children: [
                // Product Image
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    image: product.imageUrl != null
                        ? (product.imageUrl!.startsWith('http')
                              ? DecorationImage(
                                  image: NetworkImage(product.imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : DecorationImage(
                                  image: FileImage(File(product.imageUrl!)),
                                  fit: BoxFit.cover,
                                ))
                        : null,
                  ),
                  child: product.imageUrl == null
                      ? Icon(
                          Icons.image_not_supported,
                          color: Colors.grey.shade400,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'HSN: ${product.hsnCode}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      if (product.productType != null) ...[
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Text(
                            product.productType!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Stock Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: stockStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: stockStatusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    stockStatusText,
                    style: TextStyle(
                      color: stockStatusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Stock Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStockDetail('Total Stock', product.quantity.toString()),
                _buildStockDetail('Sold', sold.toString()),
                _buildStockDetail(
                  'Remaining',
                  remaining.toString(),
                  stockStatusColor,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Value Information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Buy Rate: ₹${product.buyRate.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(
                  'Stock Value: ₹${(remaining * product.buyRate).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockDetail(String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
