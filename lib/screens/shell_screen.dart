import 'package:flutter/material.dart';

import '../api/admin_auth_api.dart';
import '../constants.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/kassa_tab.dart';
import 'tabs/masters_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/products_tab.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  static const _destinations = [
    (icon: Icons.dashboard_outlined, selected: Icons.dashboard, label: 'Главная'),
    (icon: Icons.inventory_2_outlined, selected: Icons.inventory_2, label: 'Товары'),
    (icon: Icons.receipt_long_outlined, selected: Icons.receipt_long, label: 'Заказы'),
    (icon: Icons.engineering_outlined, selected: Icons.engineering, label: 'Мастера'),
    (icon: Icons.point_of_sale_outlined, selected: Icons.point_of_sale, label: 'Касса'),
  ];

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const DashboardTab(),
      const ProductsTab(),
      const OrdersTab(),
      const MastersTab(),
      const KassaTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selected),
                label: d.label,
              ),
          ],
        ),
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.small(
              onPressed: () {
                AdminAuthApi.logout();
                widget.onLogout();
              },
              backgroundColor: AppColors.cardElevated,
              child: const Icon(Icons.logout, color: AppColors.textSecondary),
            )
          : null,
    );
  }
}

class AdminAppBarActions extends StatelessWidget {
  const AdminAppBarActions({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
      color: AppColors.card,
      onSelected: (value) {
        if (value == 'logout') {
          AdminAuthApi.logout();
          onLogout();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'logout',
          child: Text('Выйти', style: TextStyle(color: AppColors.text)),
        ),
      ],
    );
  }
}
