import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/product.dart';

class ProductDetailScreen extends StatelessWidget {
  final AdminProduct product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали товара'),
        actions: [
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 180,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.inbox_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _row('Название', product.name),
                      _row('Код / штрихкод', product.articul ?? '-'),
                      _row('Категория', product.category ?? 'Без категории'),
                      _row('Подкатегория', product.subcategory ?? '—'),
                      _row('Ед. измерения', product.unit ?? 'шт'),
                      _row('Цена продажи', product.price.toStringAsFixed(0)),
                      _row('Описание', product.description ?? '—'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEdit,
                    child: const Text('Редактировать'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Удалить'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

