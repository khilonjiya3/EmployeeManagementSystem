import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../data/models/app_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../shared/widgets.dart' as w;

final selectedPayrollMonthProvider = StateProvider<DateTime>((_) => DateTime(DateTime.now().year, DateTime.now().month));

final payrollListProvider = FutureProvider.autoDispose.family<List<PayrollModel>, DateTime>((ref, date) {
  return ref.watch(payrollRepositoryProvider).getByMonthYear(date.month, date.year);
});

class PayrollListScreen extends ConsumerWidget {
  const PayrollListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedPayrollMonthProvider);
    final payrollList = ref.watch(payrollListProvider(selectedMonth));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () => context.push('/payroll/process'),
          ),
        ],
      ),
      body: Column(
        children: [
          _MonthSelector(
            selected: selectedMonth,
            onChanged: (m) => ref.read(selectedPayrollMonthProvider.notifier).state = m,
          ),
          Expanded(
            child: payrollList.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return w.EmptyState(
                    title: 'No payroll processed',
                    subtitle: 'Process payroll for ${DateFormat('MMMM yyyy').format(selectedMonth)}',
                    icon: Icons.payments_outlined,
                    actionLabel: 'Process Payroll',
                    onAction: () => context.push('/payroll/process'),
                  );
                }

                final totalNet = list.fold<double>(0, (sum, p) => sum + p.netWage);
                final paidCount = list.where((p) => p.status == 'paid').length;

                return Column(
                  children: [
                    _PayrollSummaryBar(totalNet: totalNet, paidCount: paidCount, total: list.length),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => ref.refresh(payrollListProvider(selectedMonth).future),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _PayrollCard(
                            payroll: list[i],
                            onTap: () => context.push('/payroll/${list[i].id}'),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/payroll/process'),
        icon: const Icon(Icons.calculate_rounded),
        label: const Text('Process Payroll'),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  const _MonthSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(bottom: BorderSide(color: AppColors.secondary200)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => onChanged(DateTime(selected.year, selected.month - 1)),
          ),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(selected),
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: selected.isBefore(DateTime(DateTime.now().year, DateTime.now().month))
                ? () => onChanged(DateTime(selected.year, selected.month + 1))
                : null,
          ),
        ],
      ),
    );
  }
}

class _PayrollSummaryBar extends StatelessWidget {
  final double totalNet;
  final int paidCount;
  final int total;

  const _PayrollSummaryBar({required this.totalNet, required this.paidCount, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.primary50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Total Liability', value: CurrencyUtils.formatCompact(totalNet), color: AppColors.primary600),
          _StatItem(label: 'Employees', value: '$total', color: AppColors.secondary700),
          _StatItem(label: 'Paid', value: '$paidCount', color: AppColors.success600),
          _StatItem(label: 'Pending', value: '${total - paidCount}', color: AppColors.accent600),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: color)),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _PayrollCard extends StatelessWidget {
  final PayrollModel payroll;
  final VoidCallback onTap;

  const _PayrollCard({required this.payroll, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.secondary200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary100,
              child: Text(
                (payroll.employeeName ?? 'E')[0].toUpperCase(),
                style: const TextStyle(color: AppColors.primary600, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payroll.employeeName ?? 'Employee', style: theme.textTheme.titleMedium),
                  Text(payroll.employeeCode ?? '', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary500)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _DayBadge(label: 'P', days: payroll.presentDays, color: AppColors.success500),
                      const SizedBox(width: 4),
                      _DayBadge(label: 'H', days: payroll.halfDays, color: AppColors.accent500),
                      const SizedBox(width: 4),
                      _DayBadge(label: 'A', days: payroll.absentDays, color: AppColors.error500),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(CurrencyUtils.format(payroll.netWage), style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary600)),
                const SizedBox(height: 4),
                w.StatusBadge(status: payroll.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayBadge extends StatelessWidget {
  final String label;
  final double days;
  final Color color;

  const _DayBadge({required this.label, required this.days, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
      child: Text('$label:${days.toStringAsFixed(days == days.roundToDouble() ? 0 : 1)}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
    );
  }
}

class PayrollProcessScreen extends ConsumerStatefulWidget {
  const PayrollProcessScreen({super.key});

  @override
  ConsumerState<PayrollProcessScreen> createState() => _PayrollProcessScreenState();
}

class _PayrollProcessScreenState extends ConsumerState<PayrollProcessScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<EmployeeModel> _employees = [];
  Set<String> _selectedEmployees = {};
  bool _isLoading = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final employees = await ref.read(employeeRepositoryProvider).getAll(status: 'active');
      setState(() {
        _employees = employees;
        _selectedEmployees = employees.map((e) => e.id).toSet();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processPayroll() async {
    if (_selectedEmployees.isEmpty) return;

    final confirm = await w.ConfirmDialog.show(
      context,
      title: 'Process Payroll?',
      message: 'Process payroll for ${_selectedEmployees.length} employees for ${DateFormat('MMMM yyyy').format(_selectedMonth)}?',
      confirmLabel: 'Process',
      confirmColor: AppColors.primary500,
    );
    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);
    int success = 0;
    List<String> errors = [];

    for (final id in _selectedEmployees) {
      try {
        await ref.read(payrollRepositoryProvider).processPayroll(id, _selectedMonth.month, _selectedMonth.year);
        success++;
      } catch (e) {
        errors.add(e.toString());
      }
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Processed $success/${_selectedEmployees.length} employees${errors.isNotEmpty ? ". ${errors.length} errors." : ""}'),
          backgroundColor: errors.isEmpty ? AppColors.success500 : AppColors.warning500,
        ),
      );
      if (errors.isEmpty) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Process Payroll'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _processPayroll,
            child: const Text('Process'),
          ),
        ],
      ),
      body: w.LoadingOverlay(
        isLoading: _isProcessing,
        child: Column(
          children: [
            _MonthSelector(
              selected: _selectedMonth,
              onChanged: (m) => setState(() => _selectedMonth = m),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('${_selectedEmployees.length}/${_employees.length} selected', style: Theme.of(context).textTheme.bodyMedium),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _selectedEmployees = _employees.map((e) => e.id).toSet()),
                    child: const Text('Select All'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedEmployees.clear()),
                    child: const Text('Deselect All'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _employees.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final emp = _employees[i];
                        return CheckboxListTile(
                          value: _selectedEmployees.contains(emp.id),
                          onChanged: (v) {
                            setState(() {
                              if (v == true) _selectedEmployees.add(emp.id);
                              else _selectedEmployees.remove(emp.id);
                            });
                          },
                          title: Text(emp.name, style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Text('${emp.employeeCode} • ₹${emp.dailyWageRate}/day', style: Theme.of(context).textTheme.bodySmall),
                          secondary: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary100,
                            child: Text(emp.name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary600, fontFamily: 'Inter', fontSize: 13)),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          tileColor: Theme.of(context).colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayroll,
                child: _isProcessing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Process ${_selectedEmployees.length} Employees'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PayrollDetailScreen extends ConsumerWidget {
  final String id;
  const PayrollDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<PayrollModel?>(
      future: _loadPayroll(ref),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final p = snapshot.data;
        if (p == null) return const Scaffold(body: Center(child: Text('Not found')));

        return Scaffold(
          appBar: AppBar(title: const Text('Payroll Details')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, p),
                const SizedBox(height: 16),
                _buildAttendanceSummary(context, p),
                const SizedBox(height: 16),
                _buildWageCalculation(context, p),
                if (p.status != 'paid') ...[
                  const SizedBox(height: 24),
                  _buildMarkPaidButton(context, ref, p),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<PayrollModel?> _loadPayroll(WidgetRef ref) async {
    final client = ref.read(supabaseProvider);
    final data = await client.from('payroll').select('*, employees(name, employee_code)').eq('id', id).maybeSingle();
    if (data == null) return null;
    return PayrollModel.fromJson(data as Map<String, dynamic>);
  }

  Widget _buildHeader(BuildContext context, PayrollModel p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary600, AppColors.primary400]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.employeeName ?? 'Employee', style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600)),
                    Text(p.employeeCode ?? '', style: const TextStyle(color: Color(0xCCFFFFFF), fontFamily: 'Inter', fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(DateFormat('MMMM yyyy').format(DateTime(p.payrollYear, p.payrollMonth)), style: const TextStyle(color: Color(0xBBFFFFFF), fontFamily: 'Inter', fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(CurrencyUtils.format(p.netWage), style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  w.StatusBadge(status: p.status),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary(BuildContext context, PayrollModel p) {
    final theme = Theme.of(context);
    return _Card(
      title: 'Attendance Summary',
      children: [
        _PayRow(label: 'Present Days', value: '${p.presentDays} days', bold: false),
        _PayRow(label: 'Half Days', value: '${p.halfDays} days', bold: false),
        _PayRow(label: 'Absent Days', value: '${p.absentDays} days', bold: false),
        _PayRow(label: 'Leave Days', value: '${p.leaveDays} days', bold: false),
        const Divider(),
        _PayRow(label: 'Effective Days', value: '${p.effectiveDays.toStringAsFixed(1)} days', bold: true),
        _PayRow(label: 'Daily Wage Rate', value: CurrencyUtils.format(p.dailyWageRate), bold: false),
      ],
    );
  }

  Widget _buildWageCalculation(BuildContext context, PayrollModel p) {
    return _Card(
      title: 'Wage Calculation',
      children: [
        _PayRow(label: 'Basic Wage', value: CurrencyUtils.format(p.effectiveDays * p.dailyWageRate)),
        if (p.overtimeAmount > 0) _PayRow(label: 'Overtime', value: '+ ${CurrencyUtils.format(p.overtimeAmount)}', valueColor: AppColors.success600),
        if (p.bonus > 0) _PayRow(label: 'Bonus', value: '+ ${CurrencyUtils.format(p.bonus)}', valueColor: AppColors.success600),
        if (p.advanceDeduction > 0) _PayRow(label: 'Advance Deduction', value: '- ${CurrencyUtils.format(p.advanceDeduction)}', valueColor: AppColors.error600),
        if (p.penaltyDeduction > 0) _PayRow(label: 'Penalty', value: '- ${CurrencyUtils.format(p.penaltyDeduction)}', valueColor: AppColors.error600),
        const Divider(),
        _PayRow(label: 'Gross Wage', value: CurrencyUtils.format(p.grossWage)),
        _PayRow(label: 'Net Wage', value: CurrencyUtils.format(p.netWage), bold: true, valueColor: AppColors.primary600),
      ],
    );
  }

  Widget _buildMarkPaidButton(BuildContext context, WidgetRef ref, PayrollModel p) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.payments_rounded, size: 18),
      label: const Text('Mark as Paid'),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success500),
      onPressed: () async {
        final confirm = await w.ConfirmDialog.show(
          context,
          title: 'Mark as Paid?',
          message: 'Mark ${p.employeeName}\'s salary of ${CurrencyUtils.format(p.netWage)} as paid?',
          confirmLabel: 'Mark Paid',
          confirmColor: AppColors.success500,
        );
        if (confirm != true || !context.mounted) return;

        try {
          await ref.read(payrollRepositoryProvider).markAsPaid(p.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as paid'), backgroundColor: AppColors.success500));
            context.pop();
          }
        } catch (e) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error500));
        }
      },
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          ...children,
        ],
      ),
    );
  }
}

class _PayRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _PayRow({required this.label, required this.value, this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: bold ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyMedium)),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: bold ? 15 : 14,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: valueColor ?? Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
