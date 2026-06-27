import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';

class AdminAuthApi {
  static const _timeout = Duration(seconds: 15);
  static String? _cookie;

  static String? get cookie => _cookie;
  static bool get isLoggedIn => _cookie != null && _cookie!.isNotEmpty;

  static Map<String, String> authHeaders({Map<String, String>? extra}) {
    final headers = <String, String>{
      if (_cookie != null) 'Cookie': _cookie!,
      ...?extra,
    };
    return headers;
  }

  static Future<void> login(String login, String password) async {
    final uri = Uri.parse('$baseUrl/admin/login');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'login': login.trim(),
            'password': password,
          }),
        )
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw Exception('Неверный логин или пароль');
    }

    final setCookie = res.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) {
      throw Exception('Сервер не вернул сессию');
    }
    _cookie = setCookie.split(';').first;
  }

  static Future<void> ensureAdminSession() async {
    if (!isLoggedIn) {
      throw Exception('Требуется вход в систему');
    }
  }

  static void logout() {
    _cookie = null;
  }
}
