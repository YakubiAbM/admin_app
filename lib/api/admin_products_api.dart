import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product.dart';
import 'admin_auth_api.dart';

class AdminProductsApi {
  static const _timeout = Duration(seconds: 20);

  static Uri _u(String path, [Map<String, String>? q]) {
    final uri = Uri.parse('$baseUrl$path');
    return q == null ? uri : uri.replace(queryParameters: q);
  }

  /// Загрузка товаров для вкладки "Товары".
  static Future<List<AdminProduct>> fetchProducts({String? query, String? category}) async {
    http.Response res;
    if (query != null && query.trim().isNotEmpty) {
      res = await http
          .get(_u('/products/search', {
            'q': query.trim(),
            if (category != null && category.isNotEmpty) 'category': category,
          }))
          .timeout(_timeout);
    } else {
      res = await http.get(_u('/products')).timeout(_timeout);
    }

    if (res.statusCode != 200) {
      throw Exception('Ошибка загрузки товаров: ${res.statusCode}');
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (data is! List) return [];

    return data
        .map<AdminProduct>(
          (e) => AdminProduct.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// Создание товара через /admin/add_product (multipart-форма).
  /// Пока без загрузки фото: files, sizes, colors отправляем пустыми.
  static Future<void> createProduct(
    AdminProductDraft p, {
    List<http.MultipartFile> files = const [],
  }) async {
    await AdminAuthApi.ensureAdminSession();

    final req = http.MultipartRequest('POST', _u('/admin/add_product'));

    req.fields['name'] = p.name;
    req.fields['price'] = p.price.toString();
    req.fields['brand'] = p.brand ?? '';
    req.fields['category'] = p.category ?? '';
    req.fields['new_category'] = p.newCategory ?? '';
    req.fields['subcategory'] = p.subcategory ?? '';
    req.fields['new_subcategory'] = p.newSubcategory ?? '';
    req.fields['articul'] = p.articul ?? '';
    req.fields['description'] = p.description ?? '';
    req.fields['unit'] = p.unit ?? 'шт';

    for (final s in p.sizesNames) {
      req.fields['sizes_names'] = s;
    }
    for (final sp in p.sizesPrices) {
      req.fields['sizes_prices'] = sp.toString();
    }
    for (final cn in p.colorsNames) {
      req.fields['colors_names'] = cn;
    }
    for (final cv in p.colorsValues) {
      req.fields['colors_values'] = cv;
    }

    req.files.addAll(files);
    if (AdminAuthApi.cookie != null) {
      req.headers['cookie'] = AdminAuthApi.cookie!;
    }

    final res = await req.send().timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 400) {
      throw Exception('Ошибка создания товара: ${res.statusCode}');
    }
  }

  /// Редактирование товара через /admin/edit_product/{id}
  static Future<void> updateProduct(
    int productId,
    AdminProductDraft p, {
    List<String> existingPhotos = const [],
    List<http.MultipartFile> newFiles = const [],
  }) async {
    await AdminAuthApi.ensureAdminSession();

    final req = http.MultipartRequest('POST', _u('/admin/edit_product/$productId'));

    req.fields['name'] = p.name;
    req.fields['price'] = p.price.toString();
    req.fields['brand'] = p.brand ?? '';
    req.fields['category'] = p.category ?? '';
    req.fields['new_category'] = p.newCategory ?? '';
    req.fields['subcategory'] = p.subcategory ?? '';
    req.fields['new_subcategory'] = p.newSubcategory ?? '';
    req.fields['articul'] = p.articul ?? '';
    req.fields['description'] = p.description ?? '';
    req.fields['unit'] = p.unit ?? 'шт';

    for (final ph in existingPhotos) {
      req.fields['existing_photos'] = ph;
    }

    for (final s in p.sizesNames) {
      req.fields['sizes_names'] = s;
    }
    for (final sp in p.sizesPrices) {
      req.fields['sizes_prices'] = sp.toString();
    }
    for (final cn in p.colorsNames) {
      req.fields['colors_names'] = cn;
    }
    for (final cv in p.colorsValues) {
      req.fields['colors_values'] = cv;
    }

    req.files.addAll(newFiles);

    if (AdminAuthApi.cookie != null) {
      req.headers['cookie'] = AdminAuthApi.cookie!;
    }

    final res = await req.send().timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 400) {
      throw Exception('Ошибка обновления товара: ${res.statusCode}');
    }
  }
}

