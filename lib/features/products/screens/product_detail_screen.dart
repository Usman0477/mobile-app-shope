import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../cart/providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _imageIndex = 0;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget view count increment; not critical if it fails.
    ref.read(productRepositoryProvider).incrementViewCount(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Product not found'));
          }
          final related = ref.watch(relatedProductsProvider(
            (shopId: product.shopId, excludeProductId: product.id),
          ));

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 340,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: product.imageUrls.isEmpty
                      ? Container(
                          color: AppColors.lightBackground,
                          child: const Icon(Icons.shopping_bag_outlined,
                              size: 80, color: AppColors.textMuted),
                        )
                      : PageView.builder(
                          itemCount: product.imageUrls.length,
                          onPageChanged: (i) =>
                              setState(() => _imageIndex = i),
                          itemBuilder: (context, i) => CachedNetworkImage(
                            imageUrl: product.imageUrls[i],
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.lightBackground,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      // Share intent wiring comes with the full share
                      // feature later; placeholder for now.
                    },
                  ),
                ],
              ),
              if (product.imageUrls.length > 1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        product.imageUrls.length,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _imageIndex
                                ? AppColors.primary
                                : AppColors.lightBorder,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        Text(
                          'Rs ${product.effectivePrice.toStringAsFixed(0)}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: AppColors.primary),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 10),
                          Text(
                            'Rs ${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(product.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (product.rating > 0) ...[
                          const Icon(Icons.star_rounded,
                              size: 18, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text('${product.rating.toStringAsFixed(1)} '
                              '(${product.reviewCount} reviews)'),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          product.stockQuantity > 0
                              ? 'In stock'
                              : 'Out of stock',
                          style: TextStyle(
                            color: product.stockQuantity > 0
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => context.push('/shop/${product.shopId}'),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_outlined,
                              size: 18, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            product.shopName.isEmpty
                                ? 'View shop'
                                : product.shopName,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 18, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                    const Divider(height: 32),
                    Text('Description',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      product.description.isEmpty
                          ? 'No description provided.'
                          : product.description,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.local_shipping_outlined,
                          label: product.deliveryAvailable
                              ? 'Delivery available'
                              : 'Pickup only',
                        ),
                        const SizedBox(width: 8),
                        if (product.cashOnDeliveryAvailable)
                          const _InfoChip(
                            icon: Icons.payments_outlined,
                            label: 'Cash on delivery',
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    related.maybeWhen(
                      data: (items) => items.isEmpty
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('More from this shop',
                                    style:
                                        Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 230,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: items.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (context, i) => SizedBox(
                                      width: 150,
                                      child: ProductCard(
                                        product: items[i],
                                        onTap: () => context
                                            .push('/product/${items[i].id}'),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 100), // room for bottom bar
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: productAsync.maybeWhen(
        data: (product) => product == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _QuantityStepper(
                        quantity: _quantity,
                        onChanged: (q) => setState(() => _quantity = q),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: product.stockQuantity > 0
                              ? 'Add to Cart'
                              : 'Out of Stock',
                          icon: Icons.shopping_cart_outlined,
                          onPressed: product.stockQuantity > 0
                              ? () {
                                  ref.read(cartProvider.notifier).add(
                                        product,
                                        quantity: _quantity,
                                      );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${product.name} added to cart'),
                                      action: SnackBarAction(
                                        label: 'View Cart',
                                        onPressed: () => context.push('/cart'),
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        orElse: () => null,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}
