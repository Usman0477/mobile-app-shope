import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/shop_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/seller_provider.dart';

/// Any signed-in user can open exactly one shop from here — matches
/// the "Every registered user can create their own shop" requirement.
class CreateShopScreen extends ConsumerStatefulWidget {
  const CreateShopScreen({super.key});

  @override
  ConsumerState<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends ConsumerState<CreateShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _phoneController = TextEditingController();
  final _easyPaisaController = TextEditingController();
  final _jazzCashController = TextEditingController();
  final _deliveryChargesController = TextEditingController(text: '0');
  bool _deliveryAvailable = false;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      final shop = ShopModel(
        id: '', // assigned by Firestore
        ownerId: user.uid,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        whatsapp: _whatsappController.text.trim().isEmpty
            ? null
            : _whatsappController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        easyPaisaNumber: _easyPaisaController.text.trim().isEmpty
            ? null
            : _easyPaisaController.text.trim(),
        jazzCashNumber: _jazzCashController.text.trim().isEmpty
            ? null
            : _jazzCashController.text.trim(),
        deliveryAvailable: _deliveryAvailable,
        deliveryCharges:
            double.tryParse(_deliveryChargesController.text.trim()) ?? 0,
        status: 'approved', // Phase 4 admin approval flow will change this
        createdAt: DateTime.now(),
      );

      await ref.read(sellerRepositoryProvider).createShop(shop);
      ref.invalidate(userProfileProvider);
      ref.invalidate(myShopProvider);

      if (mounted) context.go('/seller/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create shop: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open Your Shop')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.storefront_rounded,
                    size: 56, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  'Set up your shop once — you can edit these details '
                  'any time from your seller dashboard.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'Shop Name',
                  controller: _nameController,
                  prefixIcon: Icons.storefront_outlined,
                  validator: (v) => Validators.required(v, field: 'Shop name'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Description',
                  controller: _descriptionController,
                  prefixIcon: Icons.notes_outlined,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Address',
                  controller: _addressController,
                  prefixIcon: Icons.location_on_outlined,
                  validator: (v) => Validators.required(v, field: 'Address'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'WhatsApp Number (with country code)',
                  controller: _whatsappController,
                  prefixIcon: Icons.chat_bubble_outline,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  prefixIcon: Icons.call_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'EasyPaisa Number (optional)',
                  controller: _easyPaisaController,
                  prefixIcon: Icons.account_balance_wallet_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'JazzCash Number (optional)',
                  controller: _jazzCashController,
                  prefixIcon: Icons.account_balance_wallet_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('I offer delivery'),
                  subtitle: const Text('Off = pickup only'),
                  value: _deliveryAvailable,
                  onChanged: (v) => setState(() => _deliveryAvailable = v),
                ),
                if (_deliveryAvailable) ...[
                  const SizedBox(height: 8),
                  CustomTextField(
                    label: 'Delivery Charges (Rs)',
                    controller: _deliveryChargesController,
                    prefixIcon: Icons.local_shipping_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Create Shop',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
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
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _whatsappController.dispose();
    _phoneController.dispose();
    _easyPaisaController.dispose();
    _jazzCashController.dispose();
    _deliveryChargesController.dispose();
    super.dispose();
  }
}
