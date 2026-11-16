import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../products/widgets/product_card.dart';
import '../providers/shop_provider.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key, required this.shopId});

  final String shopId;

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopDetailProvider(shopId));
    final productsAsync = ref.watch(shopProductsProvider(shopId));

    return Scaffold(
      body: shopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (shop) {
          if (shop == null) {
            return const Center(child: Text('Shop not found'));
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 180,
                flexibleSpace: FlexibleSpaceBar(
                  background: shop.bannerUrl != null
                      ? CachedNetworkImage(
                          imageUrl: shop.bannerUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(color: AppColors.primary),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.lightBackground,
                            backgroundImage: shop.logoUrl != null
                                ? CachedNetworkImageProvider(shop.logoUrl!)
                                : null,
                            child: shop.logoUrl == null
                                ? const Icon(Icons.storefront_outlined,
                                    color: AppColors.primary)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(shop.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge),
                                if (shop.rating > 0)
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          size: 16,
                                          color: AppColors.secondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${shop.rating.toStringAsFixed(1)} '
                                        '(${shop.reviewCount}) · '
                                        '${shop.followerCount} followers',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (shop.description.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(shop.description,
                            style:
                                const TextStyle(color: AppColors.textMuted)),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (shop.whatsapp != null)
                            OutlinedButton.icon(
                              onPressed: () => _launch(
                                  'https://wa.me/${shop.whatsapp}'),
                              icon: const Icon(Icons.chat_bubble_outline,
                                  size: 18),
                              label: const Text('WhatsApp'),
                            ),
                          if (shop.phone != null)
                            OutlinedButton.icon(
                              onPressed: () => _launch('tel:${shop.phone}'),
                              icon: const Icon(Icons.call_outlined, size: 18),
                              label: const Text('Call'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            shop.deliveryAvailable
                                ? Icons.local_shipping_outlined
                                : Icons.store_outlined,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            shop.deliveryAvailable
                                ? 'Delivery available'
                                : 'Pickup only',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Text('Products',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
              productsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $err')),
                ),
                data: (products) {
                  if (products.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No products yet')),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.62,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => ProductCard(
                          product: products[i],
                          onTap: () =>
                              context.push('/product/${products[i].id}'),
                        ),
                        childCount: products.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
