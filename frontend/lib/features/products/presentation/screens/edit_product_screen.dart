import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/utils/snackbar_utils.dart';
import 'package:frontend/features/products/domain/entities/product.dart';
import 'package:frontend/features/products/presentation/providers/product_provider.dart';

// EditProductScreen allows users to modify an existing product's details
// or completely delete it from the system. It pre-fills the form with the
// current product data passed into it via the constructor.
class EditProductScreen extends StatefulWidget {
  final Product product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController _nameController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _minStockController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late int _stockQuantity;
  bool _saving = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _imageRemoved = false;

  final List<String> _categories = [
    'Fruits & Vegetables',
    'Dairy & Eggs',
    'Bakery',
    'Meat & Seafood',
    'Beverages',
    'Fruits',
    'Vegetables',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _sellingPriceController = TextEditingController(
      text: widget.product.sellingPrice.toStringAsFixed(2),
    );
    _minStockController = TextEditingController(
      text: widget.product.minimumStockLevel.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.product.description,
    );
    _selectedCategory = _categories.contains(widget.product.category)
        ? widget.product.category
        : _categories.first;
    _stockQuantity = widget.product.stockQuantity;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sellingPriceController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageRemoved = false;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showTopSnackBar(context, 'Error picking image: $e', isError: true);
      }
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _imageRemoved = true;
    });
  }

  Future<void> _updateProduct() async {
    if (_nameController.text.trim().isEmpty) {
      SnackBarUtils.showTopSnackBar(
        context,
        'Product name is required',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);

    final data = {
      'name': _nameController.text.trim(),
      'category': _selectedCategory,
      'sellingPrice': double.tryParse(_sellingPriceController.text) ?? 0.0,
      'stockQuantity': _stockQuantity,
      'minimumStockLevel': int.tryParse(_minStockController.text) ?? 0,
      'description': _descriptionController.text.trim(),
      'imageUrl': _imageRemoved ? '' : widget.product.imageUrl,
    };

    final success = await context.read<ProductProvider>().updateProduct(
      widget.product.id,
      data,
      imageFile: _imageFile,
    );

    if (mounted) {
      setState(() => _saving = false);
      if (success && mounted) {
        SnackBarUtils.showTopSnackBar(context, 'Product updated successfully');
        Navigator.pop(context);
      } else if (mounted) {
        SnackBarUtils.showTopSnackBar(
          context,
          context.read<ProductProvider>().error ?? 'Failed to update product',
          isError: true,
        );
      }
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${widget.product.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<ProductProvider>().deleteProduct(
        widget.product.id,
      );
      if (mounted) {
        if (success) {
          SnackBarUtils.showTopSnackBar(
            context,
            'Product "${widget.product.name}" has been deleted.',
          );
          Navigator.pop(context);
        } else {
          SnackBarUtils.showTopSnackBar(
            context,
            'Failed to delete product',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Product',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.primary.withValues(alpha: 0.1),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            _buildImageSection(),
            const SizedBox(height: 24),
            // Product Name
            _buildLabel('PRODUCT NAME (REQUIRED)'),
            const SizedBox(height: 8),
            _buildFormField(_nameController),
            const SizedBox(height: 20),
            // Category
            _buildLabel('CATEGORY'),
            const SizedBox(height: 8),
            _buildCategoryDropdown(),
            const SizedBox(height: 20),
            // Prices
            Row(
              children: [
                Expanded(
                  child: _buildPriceField(
                    'SELLING PRICE',
                    _sellingPriceController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Stock quantity
            _buildLabel('CURRENT STOCK QUANTITY'),
            const SizedBox(height: 8),
            _buildStockControl(),
            const SizedBox(height: 20),
            // Min stock
            _buildLabel('MINIMUM STOCK LEVEL'),
            const SizedBox(height: 8),
            _buildFormField(
              _minStockController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            // Description
            _buildLabel('DESCRIPTION'),
            const SizedBox(height: 8),
            _buildFormField(
              _descriptionController,
              maxLines: 4,
              hint: 'Enter product description...',
            ),
            const SizedBox(height: 28),
            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _updateProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Update Product',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _deleteProduct,
                icon: const Icon(Icons.delete_forever, color: AppColors.error),
                label: const Text(
                  'Delete Product',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : (!_imageRemoved && widget.product.imageUrl.isNotEmpty)
                            ? Image.network(
                                widget.product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 40,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 40,
                                  color: AppColors.textLight,
                                ),
                              ),
                  ),
                ),
                Positioned(
                  bottom: -8,
                  right: -8,
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('Take Photo'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.image),
                              title: const Text('Gallery'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.gallery);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.photo_camera,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_imageFile != null || (!_imageRemoved && widget.product.imageUrl.isNotEmpty))
              TextButton.icon(
                onPressed: _removeImage,
                icon: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: AppColors.error,
                ),
                label: const Text(
                  'Remove Image',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
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
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildFormField(
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.primary.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: AppColors.textLight),
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          items: _categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
      ),
    );
  }

  Widget _buildPriceField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: 'Rs.  ',
            prefixStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
            filled: true,
            fillColor: AppColors.primary.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStockControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_stockQuantity > 0) setState(() => _stockQuantity--);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.remove, color: AppColors.primary),
            ),
          ),
          Expanded(
            child: Text(
              '$_stockQuantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _stockQuantity++),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
