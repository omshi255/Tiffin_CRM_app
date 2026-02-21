import 'package:flutter/material.dart';
import '../../../../core/widgets/empty_state.dart';

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.local_shipping_outlined,
      title: 'No deliveries today',
      subtitle: 'Delivery schedule will show here.',
    );
  }
}
