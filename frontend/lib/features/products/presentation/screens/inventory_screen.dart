import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/utils/snackbar_utils.dart';
import 'package:frontend/features/products/domain/entities/product.dart';
import 'package:frontend/features/products/presentation/providers/product_provider.dart';
import 'package:frontend/features/sales/presentation/providers/sale_provider.dart';
import 'package:frontend/features/products/presentation/screens/add_product_screen.dart';
import 'package:frontend/features/products/presentation/screens/edit_product_screen.dart';
import 'package:frontend/features/products/presentation/utils/inventory_pdf_utils.dart';
import 'package:frontend/features/products/presentation/utils/category_constants.dart';

// InventoryScreen displays the complete list of products from the database.
// It allows users to filter, search, view stock levels, and navigate to
// Add or Edit product screens.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => InventoryScreenState();
}

class InventoryScreenState extends State<InventoryScreen> {
  String _selectedFilter = 'All Items';
  final List<String> _selectedCategories = [];
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductProvider>().fetchProducts();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _searchController.text.isEmpty) {
      context.read<ProductProvider>().fetchProducts(refresh: false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void refresh() {
    if (mounted) {
      context.read<ProductProvider>().fetchProducts();
    }
  }

  List<Product> _filterProducts(List<Product> products) {
    List<Product> filtered = products;
    // Apply category / stock filter chips
    if (_selectedFilter == 'Low Stock') {
      filtered = products.where((p) => p.isLowStock).toList();
    }

    // Apply multi-category selection filters
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((p) => _selectedCategories.contains(p.category)).toList();
    }
    // Apply text search term
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where(
            (p) =>
                p.name.toLowerCase().contains(query) ||
                p.category.toLowerCase().contains(query),
          )
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<ProductProvider>(
          builder: (context, provider, _) {
            final filteredProducts = _filterProducts(provider.products);
            return Column(
              children: [
                _buildHeader(context),
                _buildSearchBar(),
                _buildFilterChips(),
                const SizedBox(height: 12),
                _buildCategoryFilters(),
                Expanded(
                  child: provider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : provider.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                provider.error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textMedium,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: provider.fetchProducts,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () => provider.fetchProducts(),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: 1 + filteredProducts.length + (provider.isFetchingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Add Header Cards (Inventory Value + Products Header) at the top
                                if (index == 0) {
                                  return Column(
                                    children: [
                                      const SizedBox(height: 16),
                                      _buildInventoryValueCard(provider),
                                      const SizedBox(height: 20),
                                      _buildProductsHeader(),
                                      const SizedBox(height: 12),
                                    ],
                                  );
                                }

                                // Adjust index for products
                                final productIndex = index - 1;
                                
                                if (productIndex < filteredProducts.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ProductTile(product: filteredProducts[productIndex]),
                                  );
                                }

                                // Show loading indicator at the bottom if fetching more
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'inventory_add_btn',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          ).then((_) {
            if (!context.mounted) return;
            context.read<ProductProvider>().fetchProducts();
          });
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 10, 16),
      child: Row(
        children: [
          const Spacer(),
          const Text(
            'Product',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          Consumer<ProductProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Download Stock Report',
                onPressed: provider.products.isEmpty || provider.isLoading
                    ? null
                    : () => InventoryPdfUtils.generateAndDownloadInventoryReport(
                          products: provider.products,
                        ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search products, categories...',
            hintStyle: const TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
            prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All Items', 'Low Stock'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 0, 8),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final isSelected = _selectedFilter == filters[index];
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = filters[index]),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.grey.shade200),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  filters[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textMedium,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInventoryValueCard(ProductProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Product Value',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Rs. ${provider.totalInventoryValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.inventory_outlined,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${provider.totalItemsInStock} Items in stock',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${provider.lowStockProducts.length} Low Stock',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Products',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CATEGORIES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMedium,
                  letterSpacing: 1.0,
                ),
              ),
              if (_selectedCategories.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _selectedCategories.clear()),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ProductCategories.list.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCategories.remove(category);
                    } else {
                      _selectedCategories.add(category);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade200,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 0.8,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                              });
                            },
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditProductScreen(product: product),
          ),
        ).then((_) {
          if (!context.mounted) return;
          context.read<ProductProvider>().fetchProducts();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            // Product image
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: AppColors.textLight,
                                    size: 28,
                                  ),
                                ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.textLight,
                              size: 28,
                            ),
                          ),
                  ),
                  if (product.isLowStock)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Low Stock',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.textLight,
                          size: 20,
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditProductScreen(product: product),
                              ),
                            ).then((_) {
                              if (!context.mounted) return;
                              context.read<ProductProvider>().fetchProducts();
                            });
                          } else if (value == 'delete') {
                            _showDeleteConfirmation(context);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Product'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: AppColors.error),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Category: ${product.category}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          text:
                              'Rs. ${product.sellingPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: product.isLowStock
                                ? AppColors.primary
                                : AppColors.textDark,
                          ),
                          children: [
                            TextSpan(
                              text: '/${product.unit}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${product.stockQuantity} ${product.unit} left',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: product.isLowStock
                                      ? AppColors.error
                                      : AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 60,
                                height: 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: product.stockPercentage,
                                    backgroundColor: Colors.grey.shade100,
                                    valueColor: AlwaysStoppedAnimation(
                                      product.isLowStock
                                          ? AppColors.error
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              try {
                                context.read<SaleProvider>().addToCart(product);
                                SnackBarUtils.showSnackBar(
                                  context,
                                  '${product.name} added to cart',
                                );
                              } catch (e) {
                                SnackBarUtils.showSnackBar(
                                  context,
                                  e.toString().replaceAll('Exception: ', ''),
                                  isError: true,
                                );
                              }
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: product.stockQuantity > 0
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: product.stockQuantity > 0
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 
                                            0.3,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Icon(
                                product.stockQuantity > 0
                                    ? Icons.add_shopping_cart
                                    : Icons.remove_shopping_cart,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await context.read<ProductProvider>().deleteProduct(product.id);
              if (context.mounted) {
                if (success) {
                  SnackBarUtils.showSnackBar(
                    context,
                    'Product deleted successfully',
                  );
                } else {
                  SnackBarUtils.showSnackBar(
                    context,
                    'Failed to delete product',
                    isError: true,
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
