import 'dart:async';
import 'package:flutter/material.dart';

import '../../api/admin_products_api.dart';
import '../../constants.dart';
import '../../models/product.dart';
import '../../widgets/admin_section_header.dart';
import '../product_detail_screen.dart';
import '../product_edit_screen.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = ['Все'];
  int _selectedCategoryIndex = 0;

  List<AdminProduct> _products = [];
  bool _loading = false;
  String? _error;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _loadProducts(query: value.trim().length >= 2 ? value : null);
    });
  }

  Future<void> _loadProducts({String? query}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await AdminProductsApi.fetchProducts(
        query: query,
        category: _selectedCategoryIndex == 0 ? null : _categories[_selectedCategoryIndex],
      );
      setState(() => _products = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalStock => _products.length; // пока нет остатков в API

  double get _totalStockValue =>
      _products.fold(0, (sum, p) => sum + p.price);

  Future<void> _openCreateProduct() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProductEditScreen()),
    );
    if (changed == true) _loadProducts(query: _searchController.text);
  }

  Future<void> _openEditProduct(AdminProduct product) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductEditScreen(product: product)),
    );
    if (changed == true) _loadProducts(query: _searchController.text);
  }

  void _deleteProduct(AdminProduct product) {
    // Пока только локально скрываем; отдельный эндпоинт удаления на бэке не используется.
    setState(() => _products.removeWhere((p) => p.id == product.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AdminSectionHeader(title: 'Товары'),
            Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Поиск товара или кода',
                      filled: true,
                      fillColor: AppColors.inputBg,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.view_agenda_outlined),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (ctx, i) {
                final selected = i == _selectedCategoryIndex;
                return ChoiceChip(
                  label: Text(_categories[i]),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _selectedCategoryIndex = i);
                    _loadProducts(query: _searchController.text);
                  },
                  selectedColor: AppColors.accent.withValues(alpha: 0.25),
                  backgroundColor: AppColors.cardElevated,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.accent : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _categories.length,
            ),
          ),
          const SizedBox(height: 8),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadProducts(query: _searchController.text),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: _products.length,
                      itemBuilder: (ctx, i) {
                        final product = _products[i];
                        return _ProductCard(
                          product: product,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                  product: product,
                                  onEdit: () => _openEditProduct(product),
                                  onDelete: () => _deleteProduct(product),
                                ),
                              ),
                            );
                          },
                          onEdit: () => _openEditProduct(product),
                          onDelete: () => _deleteProduct(product),
                        );
                      },
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Товаров: $_totalStock',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Сумма цен: ${_totalStockValue.toStringAsFixed(0)} TJS',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _openCreateProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Новый товар',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
}

class _ProductCard extends StatelessWidget {
  final AdminProduct product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.cardElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.radiusLg),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.inputBg,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (product.image != null && product.image!.isNotEmpty)
                      ? Image.network(
                          buildImageUrl(product.image),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.inbox_outlined, color: AppColors.textSecondary),
                        )
                      : const Icon(Icons.inbox_outlined, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Категория: ${product.category ?? 'Без категории'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Цена: ${product.price.toStringAsFixed(0)} TJS',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Редактировать'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Удалить'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

