import 'package:flutter/material.dart';

import '../app_theme.dart';

// electricity share = kWh used x rate per kWh / boarders in the room
// used on the Payments screen (boarder checks the bill) and the bill form
class ElectricitySolver extends StatefulWidget {
  final double? initialKwh;
  // shows a "Use this amount" button when set (bill form)
  final ValueChanged<double>? onUse;

  const ElectricitySolver({super.key, this.initialKwh, this.onUse});

  @override
  State<ElectricitySolver> createState() => _ElectricitySolverState();
}

class _ElectricitySolverState extends State<ElectricitySolver> {
  late final TextEditingController _kwhController;
  late final TextEditingController _rateController;
  late final TextEditingController _boardersController;

  @override
  void initState() {
    super.initState();
    _kwhController = TextEditingController(
      text: widget.initialKwh?.toStringAsFixed(0) ?? '',
    );
    // current rate from the owner's announcement
    _rateController = TextEditingController(text: '12');
    _boardersController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _kwhController.dispose();
    _rateController.dispose();
    _boardersController.dispose();
    super.dispose();
  }

  // null until all three numbers make sense
  double? get _share {
    final kwh = double.tryParse(_kwhController.text.trim());
    final rate = double.tryParse(_rateController.text.trim());
    final boarders = int.tryParse(_boardersController.text.trim());
    if (kwh == null || rate == null || boarders == null) return null;
    // tryParse also accepts "NaN" and "Infinity"
    if (!kwh.isFinite || !rate.isFinite) return null;
    if (kwh < 0 || rate < 0 || boarders < 1) return null;
    final share = kwh * rate / boarders;
    // a huge kWh x rate can still overflow to Infinity
    return share.isFinite ? share : null;
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      // rebuild so the answer updates while typing
      onChanged: (_) => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final share = _share;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _numberField(_kwhController, 'kWh used this month'),
        const SizedBox(height: 8),
        _numberField(_rateController, 'Rate per kWh (₱)'),
        const SizedBox(height: 8),
        _numberField(_boardersController, 'Boarders in the room'),
        const SizedBox(height: 16),
        Text(
          share == null
              ? 'Enter kWh, rate and boarders'
              : 'Each boarder pays ₱ ${share.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.paymentsDark,
          ),
        ),
        if (widget.onUse != null) ...[
          const SizedBox(height: 12),
          FilledButton(
            onPressed: share == null
                ? null
                : () => widget.onUse!(double.parse(share.toStringAsFixed(2))),
            child: const Text('Use this amount'),
          ),
        ],
      ],
    );
  }
}
