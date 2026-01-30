import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../services/customer_service.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final CustomerModel? customer;

  const AddEditCustomerScreen({super.key, this.customer});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _whatsappController = TextEditingController();
  String _status = 'Active';
  bool _isLoading = false;

  final CustomerService _customerService = CustomerService();

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _mobileController.text = widget.customer!.mobile;
      _addressController.text = widget.customer!.address;
      _emailController.text = widget.customer!.email ?? '';
      _pinCodeController.text = widget.customer!.pinCode ?? '';
      _whatsappController.text = widget.customer!.whatsapp ?? '';
      _status = widget.customer!.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _pinCodeController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final customer = CustomerModel(
          id: widget.customer?.id,
          name: _nameController.text.trim(),
          mobile: _mobileController.text.trim(),
          address: _addressController.text.trim(),
          email: _emailController.text.trim(),
          pinCode: _pinCodeController.text.trim(),
          whatsapp: _whatsappController.text.trim(),
          status: _status,
          country: 'India', // Default
        );

        if (widget.customer == null) {
          await _customerService.addCustomer(customer);
        } else {
          await _customerService.updateCustomer(customer);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.customer == null
                    ? 'Customer Created'
                    : 'Customer Updated',
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

  Future<void> _deleteCustomer() async {
    if (widget.customer == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer?'),
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
        await _customerService.deleteCustomer(widget.customer!.id!);
        if (mounted) {
          Navigator.pop(context); // Pop AddEdit
          // Navigator.pop(context); // Pop List (Wait, no, we just modify the list or go back)
          // Actually, we usually just go back to the list screen and it auto-updates.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer Deleted'),
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
        title: Text(
          widget.customer == null ? 'Create Customer' : 'Edit Customer',
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (widget.customer != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteCustomer,
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
              _buildSectionTitle('Basic Information'),
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
                        decoration: _inputDecoration('Full Name', Icons.person),
                        validator: (v) =>
                            v!.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _mobileController,
                        decoration: _inputDecoration(
                          'Mobile Number',
                          Icons.phone,
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v!.isEmpty ? 'Mobile is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: _inputDecoration(
                          'Address',
                          Icons.location_on,
                        ),
                        maxLines: 2,
                        validator: (v) =>
                            v!.isEmpty ? 'Address is required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Optional Details'),
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
                        controller: _emailController,
                        decoration: _inputDecoration(
                          'Email Address',
                          Icons.email,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pinCodeController,
                        decoration: _inputDecoration(
                          'Pin Code',
                          Icons.pin_drop,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _whatsappController,
                        decoration: _inputDecoration(
                          'WhatsApp Number',
                          Icons.chat,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: _inputDecoration('Status', Icons.toggle_on),
                        items: ['Active', 'Inactive'].map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _status = val!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomer,
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
                          widget.customer == null
                              ? 'SAVE CUSTOMER'
                              : 'UPDATE CUSTOMER',
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
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.green.shade900,
      ),
    );
  }
}
