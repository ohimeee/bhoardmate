import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/payment.dart';
import '../providers/auth_provider.dart';
import '../providers/payment_provider.dart';
import '../widgets/electricity_solver.dart';

// owner only: add a new bill, or edit one when payment is passed
class PaymentFormScreen extends StatefulWidget {
  final Payment? payment;

  const PaymentFormScreen({super.key, this.payment});

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _monthController;
  late final TextEditingController _rentController;
  late final TextEditingController _electricityController;
  late final TextEditingController _waterController;
  String? _roomId;
  late String _dueDate;
  bool _saving = false;

  bool get _isEdit => widget.payment != null;

  @override
  void initState() {
    super.initState();
    final p = widget.payment;
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _roomId = p?.roomId;
    _monthController = TextEditingController(text: p?.month ?? month);
    _rentController = TextEditingController(
      text: p?.roomRent.toStringAsFixed(0) ?? '',
    );
    _electricityController = TextEditingController(
      text: p?.electricity.toStringAsFixed(2) ?? '',
    );
    _waterController = TextEditingController(
      text: p?.water.toStringAsFixed(0) ?? '',
    );
    // rent is due on the 10th by default
    _dueDate = p?.dueDate ?? '$month-10';
  }

  @override
  void dispose() {
    _monthController.dispose();
    _rentController.dispose();
    _electricityController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  String? _amountValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    final amount = double.tryParse(value.trim());
    if (amount == null || amount < 0) return 'Enter a valid amount';
    return null;
  }

  // picking a room fills in its monthly rent
  void _pickRoom(String? roomId) {
    final rooms = context.read<AuthProvider>().rooms;
    final room = rooms.where((r) => r.id == roomId);
    setState(() {
      _roomId = roomId;
      if (room.isNotEmpty) {
        _rentController.text = room.first.monthlyRent.toStringAsFixed(0);
      }
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dueDate) ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      _dueDate = picked.toIso8601String().substring(0, 10);
    });
  }

  Future<void> _openSolver() async {
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Electricity solver'),
        content: SingleChildScrollView(
          child: ElectricitySolver(
            onUse: (amount) => Navigator.pop(dialogContext, amount),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (amount == null) return;
    _electricityController.text = amount.toStringAsFixed(2);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payment = Payment(
      id: widget.payment?.id,
      roomId: _roomId!,
      month: _monthController.text.trim(),
      roomRent: double.parse(_rentController.text.trim()),
      electricity: double.parse(_electricityController.text.trim()),
      water: double.parse(_waterController.text.trim()),
      dueDate: _dueDate,
      // editing keeps the paid status, a new bill starts unpaid
      isPaid: widget.payment?.isPaid ?? false,
      paidDate: widget.payment?.paidDate,
    );

    final provider = context.read<PaymentProvider>();
    if (_isEdit) {
      await provider.updatePayment(payment);
    } else {
      await provider.addPayment(payment);
    }
    if (!mounted) return;
    setState(() => _saving = false);

    if (provider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEdit ? 'Bill saved.' : 'Bill added.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<AuthProvider>().rooms;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit bill' : 'Add bill'),
        backgroundColor: AppColors.payments,
        foregroundColor: AppColors.paymentsDark,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _roomId,
              decoration: const InputDecoration(labelText: 'Room'),
              items: rooms
                  .map(
                    (room) => DropdownMenuItem(
                      value: room.id,
                      child: Text(
                        room.boarderName == null
                            ? '${room.id} (vacant)'
                            : '${room.id} - ${room.boarderName}',
                      ),
                    ),
                  )
                  .toList(),
              // the room can't change when editing a bill
              onChanged: _isEdit || _saving ? null : _pickRoom,
              validator: (value) => value == null ? 'Room is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _monthController,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Month',
                hintText: 'YYYY-MM',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Month is required';
                }
                if (!RegExp(
                  r'^\d{4}-(0[1-9]|1[0-2])$',
                ).hasMatch(value.trim())) {
                  return 'Use YYYY-MM, like 2026-10';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rentController,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Room rent (₱)'),
              keyboardType: TextInputType.number,
              validator: (value) => _amountValidator(value, 'Room rent'),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _electricityController,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Electricity (₱)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) =>
                        _amountValidator(value, 'Electricity'),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton(
                    onPressed: _saving ? null : _openSolver,
                    child: const Text('Solve'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _waterController,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Water (₱)'),
              keyboardType: TextInputType.number,
              validator: (value) => _amountValidator(value, 'Water'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event, color: AppColors.icon),
              title: const Text('Due date'),
              subtitle: Text(_dueDate),
              trailing: TextButton(
                onPressed: _saving ? null : _pickDueDate,
                child: const Text('Change'),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save bill'),
            ),
          ],
        ),
      ),
    );
  }
}
