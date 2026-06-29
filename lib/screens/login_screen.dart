import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/admin_auth_api.dart';
import '../constants.dart';
import '../providers/theme_provider.dart';
import '../widgets/admin_brand_logo.dart';

enum _LoginStep { phone, password }

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onSuccess,
    required this.themeProvider,
  });

  final VoidCallback onSuccess;
  final AdminThemeProvider themeProvider;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  _LoginStep _step = _LoginStep.phone;
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String _loginValue = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _phoneDigits() =>
      _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');

  void _goToPassword() {
    final digits = _phoneDigits();
    if (digits.length != 9) {
      setState(() => _error = 'Введите 9 цифр номера после +992');
      return;
    }
    setState(() {
      _error = null;
      _loginValue = digits;
      _step = _LoginStep.password;
      _passwordController.clear();
    });
  }

  void _backToPhone() {
    setState(() {
      _step = _LoginStep.phone;
      _error = null;
      _passwordController.clear();
    });
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = 'Введите пароль');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AdminAuthApi.login(_loginValue, password);
      if (!mounted) return;
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppLayout.screenPadding),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AdminBrandLogo(),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius:
                              BorderRadius.circular(AppLayout.radiusLg),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Вход',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _step == _LoginStep.phone
                                  ? 'Введите номер телефона администратора'
                                  : 'Введите пароль для +992 $_loginValue',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_step == _LoginStep.phone) ...[
                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                maxLength: 9,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: TextStyle(color: onSurface),
                                decoration: const InputDecoration(
                                  prefixText: '+992 ',
                                  labelText: 'Номер телефона',
                                  hintText: '92 777 11 22',
                                  counterText: '',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                                onSubmitted: (_) => _goToPassword(),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _loading ? null : _goToPassword,
                                child: const Text('Далее'),
                              ),
                            ] else ...[
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                style: TextStyle(color: onSurface),
                                decoration: InputDecoration(
                                  labelText: 'Пароль',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) =>
                                    _loading ? null : _submit(),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Text('Войти'),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _loading ? null : _backToPhone,
                                child: const Text('← Изменить номер'),
                              ),
                            ],
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Color(0xFFFCA5A5),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: widget.themeProvider.isDark
                    ? 'Светлая тема'
                    : 'Тёмная тема',
                onPressed: widget.themeProvider.toggle,
                icon: Icon(
                  widget.themeProvider.isDark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
