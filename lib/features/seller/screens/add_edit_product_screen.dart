import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/product_model.dart';
import '../../products/providers/product_provider.dart';
import '../providers/seller_provider.dart';

/// Handles both "add new product" (existing == null) and
/// "edit product" (existing != null) in one screen, since the form
/// fields are identical either way.
class AddEditProductScreen extends ConsumerStatefulWidget {
  const AddEditProductScreen({super.key, this.existing});

  final ProductModel? existing;

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.existing?.name ?? '');
  late final _descriptionController =
      TextEditingController(text: widget.existing?.description ?? '');
  late final _priceController = TextEditingController(
      text: widget.existing?.price.toStringAsFixed(0) ?? '');
  late final _discountController = TextEditingController(
      text: widget.existing?.discountPrice?.toStringAsFixed(0) ?? '');
  late final _stockController = TextEditingController(
      text: widget.existing?.stockQuantity.toString() ?? '');
  late final _skuController =
      TextEditingController(text: widget.existing?.sku ?? '');
  late final _imageUrlController = TextEditingController(
      text: widget.existing?.imageUrls.isNotEmpty == true
          ? widget.existing!.imageUrls.first
          : '');
  String _category = productCategories.length > 1
      ? productCategories[1]
      : productCategories.first;
  bool _deliveryAvailable = false;
  bool _cashOnDelivery = true;
  bool _onlinePayment = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _deliveryAvailable = widget.existing!.deliveryAvailable;
      _cashOnDelivery = widget.existing!.cashOnDeliveryAvailable;
      _onlinePayment = widget.existing!.onlinePaymentAvailable;
      if (productCategories.contains(widget.existing!.category)) {
        _category = widget.existing!.category;
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final myShop = await ref.read(myShopProvider.future);
      if (myShop == null) {
        throw Exception('No shop found for this account');
      }

      final imageUrl = _imageUrlController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final discount = _discountController.text.trim().isEmpty
          ? null
          : double.tryParse(_discountController.text.trim());

      final repo = ref.read(sellerRepositoryProvider);

      if (widget.existing == null) {
        final product = ProductModel(
          id: '',
          sellerId: myShop.ownerId,
          shopId: myShop.id,
          shopName: myShop.name,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          discountPrice: discount,
          stockQuantity: int.tryParse(_stockController.text.trim()) ?? 0,
          sku: _skuController.text.trim().isEmpty
              ? null
              : _skuController.text.trim(),
          category: _category,
          imageUrls: imageUrl.isEmpty ? [] : [imageUrl],
          deliveryAvailable: _deliveryAvailable,
          cashOnDeliveryAvailable: _cashOnDelivery,
          onlinePaymentAvailable: _onlinePayment,
          status: 'active',
          createdAt: DateTime.now(),
        );
        await repo.addProduct(product);
      } else {
        await repo.updateProduct(widget.existing!.id, {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': price,
          'discountPrice': discount,
          'stockQuantity': int.tryParse(_stockController.text.trim()) ?? 0,
          'sku': _skuController.text.trim().isEmpty
              ? null
              : _skuController.text.trim(),
          'category': _category,
          'imageUrls': imageUrl.isEmpty ? [] : [imageUrl],
          'deliveryAvailable': _deliveryAvailable,
          'cashOnDeliveryAvailable': _cashOnDelivery,
          'onlinePaymentAvailable': _onlinePayment,
        });
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save product: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  label: 'Product Name',
                  controller: _nameController,
                  validator: (v) => Validators.required(v, field: 'Name'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Description',
                  controller: _descriptionController,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Price (Rs)',
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(v.trim()) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Discount Price (optional)',
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Stock Quantity',
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.required(v, field: 'Stock'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'SKU (optional)',
                        controller: _skuController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: productCategories
                      .where((c) => c != 'All')
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Image URL (paste a link to a product photo)',
                  controller: _imageUrlController,
                  prefixIcon: Icons.image_outlined,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    'Paste a direct image link (e.g. from a photo host). '
                    'Multi-image upload arrives once Storage is enabled.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Delivery available for this product'),
                  value: _deliveryAvailable,
                  onChanged: (v) => setState(() => _deliveryAvailable = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cash on delivery accepted'),
                  value: _cashOnDelivery,
                  onChanged: (v) => setState(() => _cashOnDelivery = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Online payment accepted'),
                  subtitle: const Text('EasyPaisa / JazzCash'),
                  value: _onlinePayment,
                  onChanged: (v) => setState(() => _onlinePayment = v),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: isEditing ? 'Save Changes' : 'Add Product',
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
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
}
