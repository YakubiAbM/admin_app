import 'dart:async';
import 'package:flutter/material.dart';

import '../../api/admin_dashboard_api.dart';
import '../../constants.dart';
import '../../models/admin_master.dart';
import '../../widgets/admin_section_header.dart';

class MastersTab extends StatefulWidget {
  const MastersTab({super.key});

  @override
  State<MastersTab> createState() => _MastersTabState();
}

class _MastersTabState extends State<MastersTab> {
  final _searchController = TextEditingController();
  List<AdminMaster> _masters = [];
  bool _loading = true;
  String? _error;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await AdminMastersApi.fetch(search: _searchController.text);
      if (!mounted) return;
      setState(() {
        _masters = items;
        _loading = false;
      });
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AdminSectionHeader(title: 'Мастера'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  hintText: 'Поиск по имени или телефону',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _load,
                  ),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _load(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5))),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  : _masters.isEmpty
                      ? const Center(
                          child: Text(
                            'Мастеров не найдено',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.accent,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _masters.length,
                            itemBuilder: (ctx, i) => _MasterCard(master: _masters[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterCard extends StatelessWidget {
  const _MasterCard({required this.master});

  final AdminMaster master;

  @override
  Widget build(BuildContext context) {
    final cats = master.categories.isEmpty ? '—' : master.categories.take(2).join(', ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppLayout.radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.inputBg,
            child: Text(
              (master.name ?? '?').substring(0, 1).toUpperCase(),
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  master.name ?? 'Без имени',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  master.phone ?? '',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  cats,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${master.points} б.',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (master.debt > 0)
                Text(
                  'долг ${master.debt.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.orange),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
