import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product_model.dart';
import '../providers/seller_provider.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(myShopProvider);
    final productsAsync = ref.watch(myProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Orders',
            onPressed: () => context.push('/seller/orders'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/seller/product/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: shopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (shop) {
          if (shop == null) {
            return const Center(child: Text('No shop found'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myShopProvider);
              ref.invalidate(myProductsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.storefront_outlined,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(shop.name,
                                  style: Theme.of(context).textTheme.titleMedium),
                              Text(
                                shop.status == 'approved'
                                    ? 'Live on marketplace'
                                    : 'Status: ${shop.status}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: shop.status == 'approved'
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/shop/${shop.id}'),
                          child: const Text('View'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                productsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error: $err'),
                  data: (products) => _DashboardStats(products: products),
                ),
                const SizedBox(height: 20),
                Text('Products',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                productsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (err, _) => Text('Error: $err'),
                  data: (products) {
                    if (products.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No products yet — tap "Add Product" to list your first item.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: products
                          .map((p) => _SellerProductTile(product: p))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 80), // room for FAB
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardStats extends StatelessWidget {
  const _DashboardStats({required this.products});

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final active = products.where((p) => p.status == 'active').length;
    final outOfStock = products.where((p) => p.stockQuantity == 0).length;
    final totalSales =
        products.fold<int>(0, (sum, p) => sum + p.salesCount);

    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Active', value: '$active')),
        const SizedBox(width: 10),
        Expanded(
            child: _StatCard(
                label: 'Out of stock',
                value: '$outOfStock',
                isWarning: outOfStock > 0)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(label: 'Total sales', value: '$totalSales')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  final String label;
  final String value;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isWarning
            ? AppColors.warning.withValues(alpha: 0.1)
            : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isWarning ? AppColors.warning : null,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _SellerProductTile extends ConsumerWidget {
  const _SellerProductTile({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHidden = product.status == 'hidden';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 56,
              height: 56,
              child: product.imageUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrls.first, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.lightBackground,
                      child: const Icon(Icons.shopping_bag_outlined,
                          color: AppColors.textMuted),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isHidden ? AppColors.textMuted : null,
                    decoration: isHidden ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  'Rs ${product.effectivePrice.toStringAsFixed(0)} · '
                  '${product.stockQuantity} in stock',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) async {
              final repo = ref.read(sellerRepositoryProvider);
              switch (action) {
                case 'edit':
                  context.push('/seller/product/edit/${product.id}',
                      extra: product);
                  break;
                case 'hide':
                  await repo.toggleHidden(product.id, !isHidden);
                  break;
                case 'delete':
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete product?'),
                      content: Text('This will permanently remove '
                          '"${product.name}".'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await repo.deleteProduct(product.id);
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'hide',
                child: Text(isHidden ? 'Unhide' : 'Hide'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
