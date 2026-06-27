import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/admin_dashboard_api.dart';
import '../../constants.dart';
import '../../models/admin_transaction.dart';
import '../../widgets/admin_section_header.dart';
import '../../widgets/admin_stat_card.dart';

class KassaTab extends StatefulWidget {
  const KassaTab({super.key});

  @override
  State<KassaTab> createState() => _KassaTabState();
}

class _KassaTabState extends State<KassaTab> {
  AdminCashierSummary? _summary;
  bool _loading = true;
  String? _error;

  final _idController = TextEditingController();
  final _amountController = TextEditingController(text: '100');
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _idController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await AdminCashierApi.summary();
      if (!mounted) return;
      setState(() {
        _summary = s;
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

  Future<void> _points(bool add) async {
    final id = _idController.text.trim();
    final amount = int.tryParse(_amountController.text.trim() ?? '');
    if (id.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Укажите ID/телефон и сумму баллов'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final res = add
          ? await AdminCashierApi.addPoints(id, amount)
          : await AdminCashierApi.spendPoints(id, amount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.ok ? res.message : res.message),
          backgroundColor: res.ok ? AppColors.accent : Colors.redAccent,
        ),
      );
      if (res.ok) _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const AdminSectionHeader(title: 'Касса'),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5))),
                )
              else if (_summary != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppLayout.screenPadding),
                  child: Column(
                    children: [
                      AdminStatCard(
                        label: 'Операций сегодня',
                        value: '${_summary!.operationsToday}',
                        icon: Icons.point_of_sale_outlined,
                      ),
                      const SizedBox(height: 12),
                      AdminStatCard(
                        label: 'Начислено сегодня',
                        value: '${_summary!.revenueToday.toStringAsFixed(0)} балл',
                        icon: Icons.payments_outlined,
                        accentColor: AppColors.orange,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(AppLayout.radiusLg),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Баллы мастеру',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'ID мастера или последние 9 цифр телефона',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _idController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: AppColors.text),
                              decoration: const InputDecoration(
                                labelText: 'ID / телефон',
                                hintText: '986505650',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(color: AppColors.text),
                              decoration: const InputDecoration(
                                labelText: 'Баллы',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _submitting ? null : () => _points(true),
                                    child: const Text('Начислить'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _submitting ? null : () => _points(false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.orange,
                                      side: const BorderSide(color: AppColors.orange),
                                    ),
                                    child: const Text('Списать'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Последние операции',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_summary!.recent.isEmpty)
                        const Text(
                          'Операций пока нет',
                          style: TextStyle(color: AppColors.textSecondary),
                        )
                      else
                        ..._summary!.recent.map((t) => _TxRow(tx: t)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.tx});

  final AdminTransaction tx;

  @override
  Widget build(BuildContext context) {
    final positive = tx.amount >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(AppLayout.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tx.masterName ?? '—',
              style: const TextStyle(color: AppColors.text),
            ),
          ),
          Text(
            '${positive ? '+' : ''}${tx.amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: positive ? AppColors.accent : AppColors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            tx.createdAt ?? '',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
