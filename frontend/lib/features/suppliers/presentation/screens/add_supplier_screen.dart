import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/utils/snackbar_utils.dart';
import 'package:frontend/features/suppliers/domain/entities/supplier.dart';
import 'package:frontend/features/suppliers/presentation/providers/supplier_provider.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';

class AddSupplierScreen extends StatefulWidget {
  final Supplier? supplier;
  const AddSupplierScreen({super.key, this.supplier});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _nameController.text = widget.supplier!.name;
      _phoneController.text = widget.supplier!.phone;
      _emailController.text = widget.supplier!.email;
      _addressController.text = widget.supplier!.address;
      _notesController.text = widget.supplier!.notes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      SnackBarUtils.showSnackBar(
        context,
        'Name and phone number are required',
        isError: true,
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final provider = Provider.of<SupplierProvider>(context, listen: false);

    final supplierData = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'notes': _notesController.text.trim(),
    };

    bool success;
    if (widget.supplier != null) {
      success = await provider.updateSupplier(
        widget.supplier!.id,
        supplierData,
      );
    } else {
      success = await provider.addSupplier(supplierData);
    }

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      if (widget.supplier == null) {
        context.read<NotificationProvider>().createNotification(
          type: 'info',
          title: 'New Supplier Added',
          message:
              'Supplier "${_nameController.text}" has been successfully added to your contact list.',
        );
      }
      SnackBarUtils.showSnackBar(
        context,
        widget.supplier != null
            ? 'Supplier updated successfully'
            : 'Supplier added successfully',
      );
      Navigator.pop(context);
    } else if (mounted) {
      SnackBarUtils.showSnackBar(
        context,
        provider.error ?? 'Failed to save supplier',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.supplier != null ? 'Edit Supplier' : 'Add New Supplier',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon header
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),

            _buildLabel('Supplier Name *'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Enter supplier name',
                prefixIcon: Icon(
                  Icons.business_outlined,
                  color: AppColors.textLight,
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel('Phone Number *'),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '+94 XX XXX XXXX',
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: AppColors.textLight,
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel('Email'),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'supplier@example.com',
                prefixIcon: Icon(
                  Icons.mail_outline,
                  color: AppColors.textLight,
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel('Address'),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Enter supplier address',
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: AppColors.textLight,
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel('Notes'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Additional notes about the supplier...',
                prefixIcon: Icon(
                  Icons.note_outlined,
                  color: AppColors.textLight,
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.supplier != null
                                ? Icons.save_outlined
                                : Icons.add_circle_outline,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.supplier != null
                                ? 'Update Supplier'
                                : 'Add Supplier',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.textDark,
      ),
    );
  }
}
