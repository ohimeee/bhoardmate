import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/payment.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/electricity_solver.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_chip.dart';
import 'payment_form_screen.dart';

// boarder: their bills with the rent breakdown
// owner: every room's bills, paid/unpaid toggle, add/edit/delete
class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  // '2026-10' -> 'October 2026'
  String _monthName(String month) {
    final parts = month.split('-');
    final index = int.tryParse(parts.length == 2 ? parts[1] : '');
    if (index == null || index < 1 || index > 12) return month;
    return '${_months[index - 1]} ${parts[0]}';
  }

  void _reload(BuildContext context) {
    final auth = context.read<AuthProvider>();
    context.read<PaymentProvider>().loadPayments(
      roomId: auth.isOwner ? null : auth.currentRoomId,
    );
  }

  void _openForm(BuildContext context, [Payment? payment]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentFormScreen(payment: payment),
      ),
    );
  }

  void _openSolver(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Electricity solver'),
        content: const SingleChildScrollView(child: ElectricitySolver()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePaid(BuildContext context, Payment payment) async {
    final provider = context.read<PaymentProvider>();
    await provider.togglePaid(payment.id!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.errorMessage ??
              (payment.isPaid ? 'Marked unpaid.' : 'Marked paid.'),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Payment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove bill?'),
        content: Text(
          'Remove the ${_monthName(payment.month)} bill of ${payment.roomId}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final provider = context.read<PaymentProvider>();
    await provider.deletePayment(payment.id!);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.errorMessage ?? 'Bill removed.')),
    );
  }

  // one line of the rent breakdown: label on the left, amount on the right
  Widget _amountRow(String label, double amount, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('₱ ${amount.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }

  Widget _billCard(
    BuildContext context,
    Payment payment,
    bool isOwner,
    String? boarderName,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _monthName(payment.month),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StatusChip(status: payment.isPaid ? 'paid' : 'unpaid'),
              ],
            ),
            if (isOwner)
              Text(
                boarderName == null
                    ? payment.roomId
                    : '${payment.roomId} - $boarderName',
                style: const TextStyle(color: AppColors.textLight),
              ),
            const SizedBox(height: 12),
            _amountRow('Room rent', payment.roomRent),
            _amountRow('Electricity', payment.electricity),
            _amountRow('Water', payment.water),
            const Divider(),
            _amountRow('Total', payment.total, bold: true),
            const SizedBox(height: 4),
            Text(
              payment.isPaid
                  ? 'Paid on ${payment.paidDate ?? '-'}'
                  : 'Due on ${payment.dueDate}',
              style: const TextStyle(color: AppColors.textLight),
            ),
            if (isOwner) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _togglePaid(context, payment),
                    child: Text(payment.isPaid ? 'Mark unpaid' : 'Mark paid'),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Edit bill',
                    onPressed: () => _openForm(context, payment),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Remove bill',
                    onPressed: () => _delete(context, payment),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ); // Card
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<PaymentProvider>();
    final payments = provider.payments;

    // earliest due date that is still unpaid
    String? nextDue;
    for (final p in payments) {
      if (!p.isPaid && (nextDue == null || p.dueDate.compareTo(nextDue) < 0)) {
        nextDue = p.dueDate;
      }
    }

    Widget body;
    if (provider.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.errorMessage != null && payments.isEmpty) {
      body = EmptyState(
        icon: Icons.error_outline,
        title: provider.errorMessage!,
        buttonLabel: 'Retry',
        onPressed: () => _reload(context),
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          BalanceCard(
            title: auth.isOwner
                ? 'Unpaid total (all rooms)'
                : 'Outstanding balance',
            amount: provider.outstandingBalance,
            subtitle: nextDue == null ? 'All paid' : 'Next due: $nextDue',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openSolver(context),
            icon: const Icon(Icons.bolt),
            label: const Text('Electricity solver'),
          ),
          const SizedBox(height: 16),
          if (payments.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long,
              title: 'No bills yet',
              message: 'Monthly bills will appear here.',
            )
          else
            for (final payment in payments)
              _billCard(
                context,
                payment,
                auth.isOwner,
                auth.rooms
                    .where((r) => r.id == payment.roomId)
                    .map((r) => r.boarderName)
                    .firstOrNull,
              ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: AppColors.payments,
        foregroundColor: AppColors.paymentsDark,
        actions: [
          IconButton(
            tooltip: 'Refresh payments',
            onPressed: provider.isLoading ? null : () => _reload(context),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: auth.isOwner
          ? FloatingActionButton.extended(
              // the News tab's FAB is in the same IndexedStack,
              // two FABs with the default hero tag crash on navigation
              heroTag: null,
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Add bill'),
            )
          : null,
      body: body,
    ); // Scaffold
  }
}
