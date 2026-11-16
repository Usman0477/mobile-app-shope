import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/order_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../orders/providers/order_provider.dart';
import '../../shop/providers/shop_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _paymentRefController = TextEditingController();

  String _deliveryOption = 'delivery'; // delivery | pickup
  String _paymentMethod = 'cod'; // cod | easypaisa | jazzcash
  bool _isSubmitting = false;

  Future<void> _placeOrder() async {
    if (_deliveryOption == 'delivery' && !_formKey.currentState!.validate()) {
      return;
    }

    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) return;

    final user = ref.read(authRepositoryProvider).currentUser;
    final profile = await ref.read(userProfileProvider.future);
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      // Multi-vendor cart: split into one order per shop so each
      // seller only sees and manages their own order.
      final byShop = <String, List<dynamic>>{};
      for (final item in cartItems) {
        byShop.putIfAbsent(item.product.shopId, () => []).add(item);
      }

      final orderRepo = ref.read(orderRepositoryProvider);
      final createdOrderIds = <String>[];

      for (final entry in byShop.entries) {
        final shopId = entry.key;
        final items = entry.value;
        final shop = await ref.read(shopDetailProvider(shopId).future);

        final orderItems = items
            .map((item) => OrderItem(
                  productId: item.product.id,
                  name: item.product.name,
                  price: item.product.effectivePrice,
                  quantity: item.quantity,
                  imageUrl: item.product.imageUrls.isNotEmpty
                      ? item.product.imageUrls.first
                      : null,
                ))
            .toList();

        final subtotal =
            orderItems.fold<double>(0, (sum, i) => sum + i.lineTotal);
        final deliveryCharges = _deliveryOption == 'delivery'
            ? (shop?.deliveryCharges ?? 0)
            : 0.0;

        final order = OrderModel(
          id: '',
          buyerId: user.uid,
          buyerName: profile?.fullName ?? '',
          sellerId: items.first.product.sellerId,
          shopId: shopId,
          shopName: shop?.name ?? items.first.product.shopName,
          items: orderItems,
          deliveryOption: _deliveryOption,
          addressLine: _deliveryOption == 'delivery'
              ? _addressController.text.trim()
              : null,
          city: _deliveryOption == 'delivery' ? _cityController.text.trim() : null,
          phone: _deliveryOption == 'delivery' ? _phoneController.text.trim() : null,
          specialInstructions: _instructionsController.text.trim().isEmpty
              ? null
              : _instructionsController.text.trim(),
          paymentMethod: _paymentMethod,
          paymentReference: _paymentRefController.text.trim().isEmpty
              ? null
              : _paymentRefController.text.trim(),
          status: 'pending',
          subtotal: subtotal,
          deliveryCharges: deliveryCharges,
          total: subtotal + deliveryCharges,
          createdAt: DateTime.now(),
        );

        final id = await orderRepo.createOrder(order);
        createdOrderIds.add(id);
      }

      ref.read(cartProvider.notifier).clear();

      if (mounted) {
        context.go('/orders');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              createdOrderIds.length > 1
                  ? '${createdOrderIds.length} orders placed!'
                  : 'Order placed!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not place order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Delivery Option',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'delivery',
                      label: Text('Delivery'),
                      icon: Icon(Icons.local_shipping_outlined),
                    ),
                    ButtonSegment(
                      value: 'pickup',
                      label: Text('Pickup'),
                      icon: Icon(Icons.store_outlined),
                    ),
                  ],
                  selected: {_deliveryOption},
                  onSelectionChanged: (v) =>
                      setState(() => _deliveryOption = v.first),
                ),
                if (_deliveryOption == 'delivery') ...[
                  const SizedBox(height: 20),
                  Text('Delivery Address',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'House / Street / Area',
                    controller: _addressController,
                    prefixIcon: Icons.home_outlined,
                    validator: (v) =>
                        Validators.required(v, field: 'Address'),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'City',
                    controller: _cityController,
                    prefixIcon: Icons.location_city_outlined,
                    validator: (v) => Validators.required(v, field: 'City'),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    prefixIcon: Icons.call_outlined,
                    keyboardType: TextInputType.phone,
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Special Instructions (optional)',
                    controller: _instructionsController,
                    prefixIcon: Icons.notes_outlined,
                  ),
                ],
                const SizedBox(height: 24),
                Text('Payment Method',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cash on Delivery'),
                  value: 'cod',
                  groupValue: _paymentMethod,
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('EasyPaisa'),
                  value: 'easypaisa',
                  groupValue: _paymentMethod,
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('JazzCash'),
                  value: 'jazzcash',
                  groupValue: _paymentMethod,
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                if (_paymentMethod != 'cod') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'After placing the order, open the shop page for '
                      'its EasyPaisa/JazzCash number, send payment, then '
                      'message the seller on WhatsApp with your '
                      'transaction ID so they can confirm the order.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Transaction ID (add after paying, optional now)',
                    controller: _paymentRefController,
                    prefixIcon: Icons.receipt_long_outlined,
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lightBorder),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(
                          label: 'Items (${cartItems.length})',
                          value: 'Rs ${subtotal.toStringAsFixed(0)}'),
                      const SizedBox(height: 6),
                      Text(
                        _deliveryOption == 'delivery'
                            ? 'Delivery charges are calculated per shop and added at order creation.'
                            : 'No delivery charges — pickup selected.',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Place Order',
                  isLoading: _isSubmitting,
                  onPressed: cartItems.isEmpty ? null : _placeOrder,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    _paymentRefController.dispose();
    super.dispose();
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
