import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hsnCodeController = TextEditingController();
  final _batchNoController = TextEditingController();
  final _mrpController = TextEditingController();
  final _buyRateController = TextEditingController();
  final _givenRateController = TextEditingController();
  final _quantityController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitSizeController = TextEditingController();

  String? _productType;
  final List<String> _productTypes = [
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

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  DateTime? _expireDate;

  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _hsnCodeController.text = widget.product!.hsnCode;
      _batchNoController.text = widget.product!.batchNo ?? '';
      _mrpController.text = widget.product!.mrp.toString();
      _buyRateController.text = widget.product!.buyRate.toString();
      _givenRateController.text = widget.product!.givenRate.toString();
      _quantityController.text = widget.product!.quantity.toString();
      _categoryController.text = widget.product!.category;
      _productType = widget.product!.productType;
      _unitSizeController.text = widget.product!.unitSize ?? '';
      _expireDate = widget.product!.expireDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _hsnCodeController.dispose();
    _batchNoController.dispose();
    _mrpController.dispose();
    _buyRateController.dispose();
    _givenRateController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _unitSizeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
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

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final product = ProductModel(
          id: widget.product?.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          hsnCode: _hsnCodeController.text.trim(),
          batchNo: _batchNoController.text.trim().isEmpty
              ? null
              : _batchNoController.text.trim(),
          mrp: double.tryParse(_mrpController.text.trim()) ?? 0.0,
          buyRate: double.tryParse(_buyRateController.text.trim()) ?? 0.0,
          givenRate: double.tryParse(_givenRateController.text.trim()) ?? 0.0,
          quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
          category: _categoryController.text.trim(),
          productType: _productType,
          unitSize: _unitSizeController.text.trim().isEmpty
              ? null
              : _unitSizeController.text.trim(),
          imageUrl: widget.product?.imageUrl, // Keep existing if not changing
          expireDate: _expireDate,
          createdAt: widget.product?.createdAt ?? DateTime.now(),
        );

        if (widget.product == null) {
          await _productService.addProduct(product, _imageFile);
        } else {
          await _productService.updateProduct(product, _imageFile);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.product == null ? 'Product Created' : 'Product Updated',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct() async {
    if (widget.product == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _productService.deleteProduct(
          widget.product!.id!,
          widget.product!.imageUrl,
        );
        if (mounted) {
          Navigator.pop(context); // Pop AddEdit
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product Deleted'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (widget.product != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteProduct,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    _imageFile != null ||
                                        widget.product?.imageUrl != null
                                    ? Colors.green.shade400
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                              image: _imageFile != null
                                  ? DecorationImage(
                                      image: FileImage(_imageFile!),
                                      fit: BoxFit.cover,
                                    )
                                  : widget.product?.imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        widget.product!.imageUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child:
                                _imageFile == null &&
                                    widget.product?.imageUrl == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo,
                                        size: 40,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Add Image",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade600,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_imageFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'New image selected',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Product Details'),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(
                          'Product Name',
                          Icons.shopping_bag,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: _inputDecoration(
                          'Description',
                          Icons.description,
                        ),
                        maxLines: 3,
                        validator: (v) =>
                            v!.isEmpty ? 'Description is required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _hsnCodeController,
                              decoration: _inputDecoration(
                                'HSN Code',
                                Icons.numbers,
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'HSN Code is required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _batchNoController,
                              decoration: _inputDecoration(
                                'Batch No',
                                Icons.batch_prediction,
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
                              controller: _categoryController,
                              decoration: _inputDecoration(
                                'Category',
                                Icons.category,
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Category is required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: _expireDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                );
                                if (pickedDate != null) {
                                  setState(() => _expireDate = pickedDate);
                                }
                              },
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: _inputDecoration(
                                    'Expire Date',
                                    Icons.calendar_today,
                                  ),
                                  controller: TextEditingController(
                                    text: _expireDate != null
                                        ? '${_expireDate!.day}/${_expireDate!.month}/${_expireDate!.year}'
                                        : '',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Form & Unit Info (Optional)'),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _productType,
                              isExpanded: true,
                              decoration: _inputDecoration(
                                'Product Form',
                                Icons.medication,
                              ),
                              items: _productTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => _productType = val),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _unitSizeController,
                              decoration: _inputDecoration(
                                'Size/Vol (e.g. 100ml)',
                                Icons.scale,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Pricing & Inventory'),
              const SizedBox(height: 16),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Pricing Row 1
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _buyRateController, // Buy Rate
                              decoration: _inputDecoration(
                                'Buy Rate',
                                Icons.currency_rupee,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _mrpController, // MRP
                              decoration: _inputDecoration(
                                'MRP',
                                Icons.price_check,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Pricing Row 2 + Quantity
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _givenRateController, // Selling Rate
                              decoration: _inputDecoration(
                                'Selling/Given Rate',
                                Icons.sell,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController, // Quantity
                              decoration: _inputDecoration(
                                'Quantity',
                                Icons.inventory,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.product == null
                              ? 'SAVE PRODUCT'
                              : 'UPDATE PRODUCT',
                          style: const TextStyle(
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green.shade700),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green.shade700, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16, // Slightly smaller
        fontWeight: FontWeight.bold,
        color: Colors.green.shade900,
      ),
    );
  }
}
