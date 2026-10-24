// placeholder, real Payments screen is #9
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../providers/payment_provider.dart';
import '../widgets/status_chip.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final payments = context.watch<PaymentProvider>().payments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: AppColors.payments,
        foregroundColor: AppColors.paymentsDark,
      ),
      body: ListView.builder(
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          return ListTile(
            title: Text('${payment.month} - ${payment.roomId}'),
            subtitle: Text('PHP ${payment.total.toStringAsFixed(2)}'),
            trailing: StatusChip(status: payment.isPaid ? 'paid' : 'unpaid'),
          );
        },
      ),
    );
  }
}
