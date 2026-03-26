import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/utils/snackbar_utils.dart';
import 'package:frontend/features/products/presentation/providers/product_provider.dart';
import 'package:frontend/core/utils/validation_utils.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _minStockController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Fruits';
  String _selectedUnit = 'pcs';
  int _initialStock = 0;
  bool _notifyOutOfStock = true;
  bool _saving = false;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final List<String> _categories = [
    'Grains & Staples',
    'Fruits',
    'Vegetables',
    'Dairy & Eggs',
    'Bakery',
    'Household / Personal Care',
  ];

  final Map<String, String> _unitExamples = {
    'kg': 'rice and vegetables',
    'pcs': 'apples and eggs',
    'items': 'bread, toothpaste, oil bottles',
    'packs': 'bundled goods',
    'trays': 'egg trays',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Opens the camera or gallery to let the user pick a product image.
  Future<void> _pickImage(ImageSource source) async {
    try {
      // Use the ImagePicker to select a file.
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000, // Downscale large images to save bandwidth and storage.
        maxHeight: 1000,
        imageQuality: 85, // Slightly compress to reduce file size without losing much detail.
      );
      if (pickedFile != null) {
        // If the user picked a file, update the state to show the preview on screen.
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      // If something goes wrong (like permission denied), show a top snackbar alert.
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error picking image: $e',
          isError: true,
        );
      }
    }
  }

  // Validates the form and sends the new product data to the backend.
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
 
    // Step 2: Show a loading state so the user knows work is happening.
    setState(() => _saving = true);
 
    // Step 3: Bundle all the form fields into a Map for the API.
    final data = {
      'name': _nameController.text.trim(),
      'category': _selectedCategory,
      // Use double.tryParse to handle empty or invalid price inputs gracefully.
      'sellingPrice': double.tryParse(_sellingPriceController.text) ?? 0.0,
      'purchasePrice': double.tryParse(_purchasePriceController.text) ?? 0.0,
      'stockQuantity': _initialStock,
      'minimumStockLevel': int.tryParse(_minStockController.text) ?? 0,
      'description': _descriptionController.text.trim(),
      'unit': _selectedUnit,
      'notifyOutOfStock': _notifyOutOfStock,
    };
 
    // Step 4: Call the ProductProvider to handle the image upload and API POST request.
    final success = await context.read<ProductProvider>().createProduct(
          data,
          imageFile: _imageFile,
        );

    // Guard against the widget being unmounted out from under us during the async call
    if (!context.mounted) return;

    if (mounted) {
      setState(() => _saving = false);
      if (success && mounted) {
        SnackBarUtils.showSnackBar(context, 'Product added successfully');
        Navigator.pop(context);
      } else if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          context.read<ProductProvider>().error ?? 'Failed to add product',
          isError: true,
        );
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
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textMedium),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Product',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade100, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image upload area
                    _buildImageSection(),
                    const SizedBox(height: 24),
                    // Product Name
                    _buildLabel('PRODUCT NAME (REQUIRED)', isRequired: true),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Organic Red Apples',
                      ),
                      validator: (v) => ValidationUtils.validateRequired(v, 'Product name'),
                    ),
                    const SizedBox(height: 20),
                    // Category
                    _buildLabel('CATEGORY'),
                    const SizedBox(height: 6),
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPriceField(
                            'PURCHASE (COST)',
                            _purchasePriceController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Stock section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('INITIAL STOCK'),
                                  const Text(
                                    'Current units available',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  ],
                                ),
                              Row(
                                children: [
                                  _buildUnitSelector(),
                                  const SizedBox(width: 12),
                                  _buildStockStepper(),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('MINIMUM STOCK LEVEL'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _minStockController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Alert threshold...',
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                                validator: ValidationUtils.validateStock,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Description
                    _buildLabel('DESCRIPTION'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Add details about product size, weight, or benefits...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Notification Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        value: _notifyOutOfStock,
                        onChanged: (v) => setState(() => _notifyOutOfStock = v),
                        title: const Text(
                          'Notify when out of stock',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        subtitle: const Text(
                          'Receive an alert when this product hits 0 units.',
                          style: TextStyle(fontSize: 11, color: AppColors.textLight),
                        ),
                        activeThumbColor: AppColors.primary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom buttons
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveProduct,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_saving ? 'Saving...' : 'Save Product'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 2,
              strokeAlign: BorderSide.strokeAlignCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: kIsWeb
                      ? Image.network(
                          _imageFile!.path,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_imageFile!.path),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                )
              else
                Icon(
                  Icons.add_a_photo,
                  size: 36,
                  color: AppColors.textLight.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text(
                    'Take Photo',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.image, size: 18),
                  label: const Text(
                    'Gallery',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMedium,
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Recommended: Square PNG or JPG up to 5MB',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isRequired ? AppColors.primary : AppColors.textMedium,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: AppColors.textLight),
          items: _categories
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, style: const TextStyle(fontSize: 14)),
                ),
              )
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
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: 'Rs.  ',
            prefixStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
            hintText: '0.00',
          ),
          validator: ValidationUtils.validatePrice,
        ),
      ],
    );
  }

  Widget _buildUnitSelector() {
    return GestureDetector(
      onTap: _showUnitSelectionDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedUnit,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showUnitSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Select Unit',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        contentPadding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _unitExamples.entries.map((entry) {
              final isSelected = _selectedUnit == entry.key;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                selected: isSelected,
                selectedTileColor: AppColors.primary.withValues(alpha: 0.05),
                title: Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textDark,
                  ),
                ),
                subtitle: Text(
                  'e.g. ${entry.value}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.7) : AppColors.textLight,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedUnit = entry.key);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMedium)),
          ),
        ],
      ),
    );
  }

  // A custom UI widget that lets the user tap - or + to change the stock count.
  Widget _buildStockStepper() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The 'Minus' button.
          InkWell(
            onTap: () {
              // Decrement, but stop at zero (we can't have negative initial stock).
              if (_initialStock > 0) setState(() => _initialStock--);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Icon(Icons.remove, color: AppColors.primary, size: 18),
            ),
          ),
          // The current count display.
          SizedBox(
            width: 36,
            child: Text(
              '$_initialStock',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          // The 'Plus' button.
          InkWell(
            onTap: () => setState(() => _initialStock++),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Icon(Icons.add, color: AppColors.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
