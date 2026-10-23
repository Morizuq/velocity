import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/sample_data_seeder.dart';
import '../../../core/storage/shared_prefs_storage.dart';
import '../../../core/theme/velocity_tokens.dart';
import '../../../features/clearance/domain/entities/debt_entity.dart';
import '../../../features/clearance/presentation/controllers/clearance_controller.dart';
import '../../../features/expenses/domain/entities/recurring_cashflow_entity.dart';
import '../../../features/expenses/presentation/controllers/recurring_cashflow_controller.dart';
import '../../../features/milestones/domain/entities/milestone_entity.dart';
import '../../../features/milestones/presentation/controllers/milestones_controller.dart';
import '../../../features/receivables/domain/entities/receivable_entity.dart';
import '../../../features/receivables/presentation/controllers/receivables_controller.dart';
import '../buttons/velocity_button.dart';
import '../tokens/app_border_radius.dart';
import '../tokens/app_spacing.dart';

/// Modal bottom sheet providing JSON & CSV export as well as JSON import.
class VelocityDataExportImportSheet extends ConsumerStatefulWidget {
  const VelocityDataExportImportSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const VelocityDataExportImportSheet(),
    );
  }

  @override
  ConsumerState<VelocityDataExportImportSheet> createState() =>
      _VelocityDataExportImportSheetState();
}

class _VelocityDataExportImportSheetState
    extends ConsumerState<VelocityDataExportImportSheet> {
  final _importController = TextEditingController();
  String? _statusMessage;
  bool _isSuccess = true;

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _dumpAllData() {
    final cashflows = ref.read(recurringCashflowControllerProvider);
    final debts = ref.read(clearanceControllerProvider);
    final receivables = ref.read(receivablesControllerProvider);
    final milestones = ref.read(milestonesControllerProvider);

    return {
      'version': 'velocity-redesign-v1',
      'exportedAt': DateTime.now().toIso8601String(),
      'cashflows': cashflows.map((c) => c.toMap()).toList(),
      'debts': debts.map((d) => d.toMap()).toList(),
      'receivables': receivables.map((r) => r.toMap()).toList(),
      'milestones': milestones.map((m) => m.toMap()).toList(),
    };
  }

  void _exportJson() {
    final data = _dumpAllData();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    Clipboard.setData(ClipboardData(text: jsonStr));

    setState(() {
      _statusMessage = 'Complete JSON backup copied to clipboard!';
      _isSuccess = true;
    });
  }

  void _exportCsv() {
    final cashflows = ref.read(recurringCashflowControllerProvider);
    final debts = ref.read(clearanceControllerProvider);
    final receivables = ref.read(receivablesControllerProvider);
    final milestones = ref.read(milestonesControllerProvider);

    final buffer = StringBuffer();
    buffer.writeln(
      'Type,Name,Amount/Target,Paid/Received,MonthlyPayment,DueDate',
    );

    for (final c in cashflows) {
      buffer.writeln(
        '${c.direction.name},"${c.title}",${c.amount},0,0,Day ${c.dayOfMonth}',
      );
    }
    for (final d in debts) {
      buffer.writeln(
        'Debt,"${d.creditor}",${d.totalOwed},${d.amountPaid},${d.monthlyPayment},${d.dueDate?.toIso8601String().substring(0, 10) ?? ""}',
      );
    }
    for (final r in receivables) {
      buffer.writeln(
        'Receivable,"${r.debtor}",${r.totalAmount},${r.amountReceived},0,${r.dueDate?.toIso8601String().substring(0, 10) ?? ""}',
      );
    }
    for (final m in milestones) {
      buffer.writeln(
        'Goal,"${m.title}",${m.targetAmount},${m.currentAmount},0,',
      );
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    setState(() {
      _statusMessage = 'CSV data copied to clipboard!';
      _isSuccess = true;
    });
  }

  void _importJson() {
    final raw = _importController.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _statusMessage = 'Please paste JSON data to import.';
        _isSuccess = false;
      });
      return;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      if (decoded.containsKey('cashflows')) {
        final list = (decoded['cashflows'] as List<dynamic>)
            .map(
              (e) => RecurringCashflowEntity.fromMap(e as Map<String, dynamic>),
            )
            .toList();
        for (final item in list) {
          ref
              .read(recurringCashflowControllerProvider.notifier)
              .updateCashflow(item);
        }
      }

      if (decoded.containsKey('debts')) {
        final list = (decoded['debts'] as List<dynamic>)
            .map((e) => DebtEntity.fromMap(e as Map<String, dynamic>))
            .toList();
        for (final item in list) {
          ref.read(clearanceControllerProvider.notifier).updateDebt(item);
        }
      }

      if (decoded.containsKey('receivables')) {
        final list = (decoded['receivables'] as List<dynamic>)
            .map((e) => ReceivableEntity.fromMap(e as Map<String, dynamic>))
            .toList();
        for (final item in list) {
          ref
              .read(receivablesControllerProvider.notifier)
              .updateReceivable(item);
        }
      }

      if (decoded.containsKey('milestones')) {
        final list = (decoded['milestones'] as List<dynamic>)
            .map((e) => MilestoneEntity.fromMap(e as Map<String, dynamic>))
            .toList();
        for (final item in list) {
          ref.read(milestonesControllerProvider.notifier).updateMilestone(item);
        }
      }

      setState(() {
        _statusMessage = 'Data successfully imported!';
        _isSuccess = true;
      });
      _importController.clear();
    } catch (e) {
      setState(() {
        _statusMessage = 'Invalid JSON: $e';
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.l,
        AppSpacing.l,
        AppSpacing.l + bottomInset,
      ),
      decoration: BoxDecoration(
        color: tokens.surfaceColor,
        borderRadius: AppBorderRadius.topSheet,
        border: Border(top: BorderSide(color: tokens.lineColor)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Backup & Transfer Data',
                  style: tokens.bricolage(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: tokens.muteColor),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                ),
              ],
            ),
            AppSpacing.vS,
            Text(
              'Export all your records as portable JSON or CSV, or restore from a JSON backup.',
              style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
            ),
            AppSpacing.vM,

            // Export Actions
            Row(
              children: [
                Expanded(
                  child: VelocityButton.ghost(
                    onPressed: _exportJson,
                    icon: Icons.copy_rounded,
                    label: 'Export JSON',
                    isFullWidth: true,
                  ),
                ),
                AppSpacing.hXS,
                Expanded(
                  child: VelocityButton.ghost(
                    onPressed: _exportCsv,
                    icon: Icons.table_chart_outlined,
                    label: 'Export CSV',
                    isFullWidth: true,
                  ),
                ),
              ],
            ),
            AppSpacing.vL,

            // Import Section
            Text(
              'Import JSON Backup',
              style: tokens.bricolage(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            AppSpacing.vXS,
            TextField(
              controller: _importController,
              maxLines: 4,
              style: tokens.figtree(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Paste valid Velocity JSON backup here...',
                filled: true,
                fillColor: tokens.bgColor,
                border: const OutlineInputBorder(
                  borderRadius: AppBorderRadius.allInput,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.allInput,
                  borderSide: BorderSide(color: tokens.lineColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.allInput,
                  borderSide: BorderSide(color: tokens.accentColor, width: 2),
                ),
              ),
            ),
            AppSpacing.vXS,
            VelocityButton.primary(
              onPressed: _importJson,
              label: 'Import Data',
              isFullWidth: true,
            ),

            AppSpacing.vM,
            Divider(color: tokens.lineColor, height: 1),
            AppSpacing.vM,

            // Clear All Data
            VelocityButton.danger(
              onPressed: _confirmAndClearAllData,
              icon: Icons.delete_sweep_outlined,
              label: 'Clear All Data',
              isFullWidth: true,
            ),

            if (_statusMessage != null) ...[
              AppSpacing.vS,
              Text(
                _statusMessage!,
                style: tokens.figtree(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isSuccess ? tokens.inColor : tokens.outColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndClearAllData() async {
    final tokens = context.tokens;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surfaceColor,
        shape: const RoundedRectangleBorder(borderRadius: AppBorderRadius.allCard),
        title: Text(
          'Clear all records?',
          style: tokens.bricolage(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will purge all income, recurring expenses, debts, receivables, and goals from local storage.',
          style: tokens.figtree(fontSize: 14, color: tokens.muteColor),
        ),
        actions: [
          VelocityButton.subtle(
            onPressed: () => Navigator.of(ctx).pop(false),
            label: 'Cancel',
          ),
          VelocityButton.danger(
            onPressed: () => Navigator.of(ctx).pop(true),
            label: 'Clear all',
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(recurringCashflowControllerProvider.notifier).clearAll();
      ref.read(clearanceControllerProvider.notifier).clearAll();
      ref.read(receivablesControllerProvider.notifier).clearAll();
      ref.read(milestonesControllerProvider.notifier).clearAll();

      final prefs = ref.read(sharedPreferencesProvider);
      await SampleDataSeeder.resetData(prefs);

      if (mounted) {
        setState(() {
          _statusMessage = 'All records successfully cleared.';
          _isSuccess = true;
        });
      }
    }
  }
}
