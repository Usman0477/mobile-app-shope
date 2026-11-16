import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/order_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  static const _statusSteps = ['pending', 'confirmed', 'completed'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final currentUid = ref.watch(authStateChangesProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }
          final isSeller = currentUid == order.sellerId;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (order.status != 'cancelled')
                _StatusStepper(currentStatus: order.status),
              if (order.status == 'cancelled')
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: AppColors.error),
                      SizedBox(width: 10),
                      Text('This order was cancelled',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Text(isSeller ? 'Buyer' : 'Shop',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(isSeller
                  ? (order.buyerName.isEmpty ? 'Unknown' : order.buyerName)
                  : order.shopName),
              const Divider(height: 32),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item.name} x${item.quantity}'),
                        ),
                        Text('Rs ${item.lineTotal.toStringAsFixed(0)}'),
                      ],
                    ),
                  )),
              const Divider(height: 32),
              _SummaryRow(label: 'Subtotal', value: order.subtotal),
              const SizedBox(height: 6),
              _SummaryRow(label: 'Delivery', value: order.deliveryCharges),
              const SizedBox(height: 6),
              _SummaryRow(label: 'Total', value: order.total, bold: true),
              const Divider(height: 32),
              Text('Delivery', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                order.deliveryOption == 'delivery'
                    ? '${order.addressLine ?? ''}, ${order.city ?? ''}\n'
                        'Phone: ${order.phone ?? ''}'
                    : 'Pickup from shop',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              if (order.specialInstructions != null) ...[
                const SizedBox(height: 8),
                Text('Note: ${order.specialInstructions}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontStyle: FontStyle.italic)),
              ],
              const Divider(height: 32),
              Text('Payment', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_paymentLabel(order.paymentMethod)),
              if (order.paymentReference != null) ...[
                const SizedBox(height: 4),
                Text('Reference: ${order.paymentReference}',
                    style: const TextStyle(color: AppColors.textMuted)),
              ],
              const SizedBox(height: 32),
              if (isSeller) _SellerActions(order: order),
            ],
          );
        },
      ),
    );
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'easypaisa':
        return 'EasyPaisa';
      case 'jazzcash':
        return 'JazzCash';
      default:
        return 'Cash on Delivery';
    }
  }
}

class _StatusStepper extends StatelessWidget {
  const _StatusStepper({required this.currentStatus});

  final String currentStatus;

  @override
  Widget build(BuildContext context) {
    final steps = OrderDetailScreen._statusSteps;
    final currentIndex = steps.indexOf(currentStatus);

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final passed = (i ~/ 2) < currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: passed ? AppColors.primary : AppColors.lightBorder,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final reached = stepIndex <= currentIndex;
        return Column(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor:
                  reached ? AppColors.primary : AppColors.lightBorder,
              child: Icon(
                reached ? Icons.check : Icons.circle,
                size: 14,
                color: reached ? Colors.white : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIndex][0].toUpperCase() + steps[stepIndex].substring(1),
              style: const TextStyle(fontSize: 10),
            ),
          ],
        );
      }),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.bold = false});

  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      fontSize: bold ? 16 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('Rs ${value.toStringAsFixed(0)}', style: style),
      ],
    );
  }
}

class _SellerActions extends ConsumerWidget {
  const _SellerActions({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(orderRepositoryProvider);

    if (order.status == 'completed' || order.status == 'cancelled') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (order.status == 'pending')
          PrimaryButton(
            label: 'Confirm Order',
            icon: Icons.check_circle_outline,
            onPressed: () => repo.updateStatus(order.id, 'confirmed'),
          ),
        if (order.status == 'confirmed') ...[
          PrimaryButton(
            label: 'Mark Completed',
            icon: Icons.done_all,
            onPressed: () => repo.updateStatus(order.id, 'completed'),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton(
          onPressed: () => repo.updateStatus(order.id, 'cancelled'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          child: const Text('Cancel Order'),
        ),
      ],
    );
  }
}
