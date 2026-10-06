// placeholder, real Payments screen is #9
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/payment_provider.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final payments = context.watch<PaymentProvider>().payments;

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: ListView.builder(
        itemCount: payments.length,
        itemBuilder: (context, index) {
          final payment = payments[index];
          return ListTile(
            title: Text('${payment.month} - ${payment.roomId}'),
            subtitle: Text('PHP ${payment.total.toStringAsFixed(2)}'),
            trailing: Text(
              payment.isPaid ? 'Paid' : 'Unpaid',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: payment.isPaid ? Colors.green : Colors.red,
              ),
            ),
          );
        },
      ),
    );
  }
}
