import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../constants.dart';
import '../models/product.dart';
import '../api/admin_products_api.dart';

class ProductEditScreen extends StatefulWidget {
  final AdminProduct? product;

  const ProductEditScreen({super.key, this.product});

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _categoryController;
  late final TextEditingController _subcategoryController;
  late final TextEditingController _unitController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  bool _saving = false;
  final List<_SizeRow> _sizes = [];
  final List<_ColorRow> _colors = [];
  final List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name);
    _skuController = TextEditingController(text: p?.articul);
    _categoryController = TextEditingController(text: p?.category);
    _subcategoryController = TextEditingController(text: p?.subcategory);
    _unitController = TextEditingController(text: p?.unit ?? 'шт');
    _priceController = TextEditingController(text: p?.price.toStringAsFixed(0));
    _descriptionController = TextEditingController(text: p?.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _subcategoryController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final draft = AdminProductDraft(
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.replaceAll(',', '.')),
      category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      subcategory: _subcategoryController.text.trim().isEmpty ? null : _subcategoryController.text.trim(),
      articul: _skuController.text.trim(),
      description: _descriptionController.text.trim(),
      unit: _unitController.text.trim().isEmpty ? 'шт' : _unitController.text.trim(),
      sizesNames: _sizes.map((e) => e.name.text.trim()).where((t) => t.isNotEmpty).toList(),
      sizesPrices: _sizes
          .map((e) => double.tryParse(e.price.text.replaceAll(',', '.')) ?? 0)
          .toList(),
      colorsNames: _colors.map((e) => e.name.text.trim()).where((t) => t.isNotEmpty).toList(),
      colorsValues: _colors.map((e) => e.value.text.trim()).where((t) => t.isNotEmpty).toList(),
    );

    setState(() => _saving = true);
    try {
      final files = <http.MultipartFile>[];
      for (final img in _images) {
        files.add(await http.MultipartFile.fromPath('files', img.path));
      }

      if (widget.product == null) {
        await AdminProductsApi.createProduct(draft, files: files);
      } else {
        await AdminProductsApi.updateProduct(widget.product!.id, draft, newFiles: files);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.product != null;

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактировать товар' : 'Новый товар'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: inputDecoration.copyWith(labelText: 'Название'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите название' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _skuController,
                decoration: inputDecoration.copyWith(labelText: 'Код / штрихкод'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите код' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: inputDecoration.copyWith(labelText: 'Категория'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subcategoryController,
                decoration: inputDecoration.copyWith(labelText: 'Подкатегория'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitController,
                decoration: inputDecoration.copyWith(labelText: 'Ед. измерения'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: inputDecoration.copyWith(labelText: 'Цена продажи (TJS)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите цену' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: inputDecoration.copyWith(labelText: 'Описание'),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Размеры (имя + цена)', style: TextStyle(color: theme.colorScheme.onSurface)),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  for (final row in _sizes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: row.name,
                              decoration: inputDecoration.copyWith(hintText: 'Размер (например, 25 кг)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: row.price,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: inputDecoration.copyWith(hintText: 'Цена'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() => _sizes.remove(row));
                            },
                          ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _sizes.add(_SizeRow()));
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить размер'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Цвета', style: TextStyle(color: theme.colorScheme.onSurface)),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  for (final row in _colors)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: row.name,
                              decoration: inputDecoration.copyWith(hintText: 'Название цвета'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: row.value,
                              decoration: inputDecoration.copyWith(hintText: '#RRGGBB'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() => _colors.remove(row));
                            },
                          ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _colors.add(_ColorRow()));
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить цвет'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Фото товара', style: TextStyle(color: theme.colorScheme.onSurface)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final img in _images)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(img.path),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _images.remove(img));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setState(() => _images.add(picked));
                      }
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: theme.colorScheme.surface,
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text(
                      'Сохранить',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SizeRow {
  final TextEditingController name = TextEditingController();
  final TextEditingController price = TextEditingController();
}

class _ColorRow {
  final TextEditingController name = TextEditingController();
  final TextEditingController value = TextEditingController();
}


