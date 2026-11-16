import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/shop_model.dart';
import '../providers/admin_provider.dart';

class ManageShopsScreen extends ConsumerWidget {
  const ManageShopsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(allShopsProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Shops'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
              Tab(text: 'Banned'),
            ],
          ),
        ),
        body: shopsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (shops) => TabBarView(
            children: [
              _ShopList(shops: shops.where((s) => s.status == 'pending').toList()),
              _ShopList(shops: shops.where((s) => s.status == 'approved').toList()),
              _ShopList(shops: shops.where((s) => s.status == 'rejected').toList()),
              _ShopList(shops: shops.where((s) => s.status == 'banned').toList()),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopList extends ConsumerWidget {
  const _ShopList({required this.shops});

  final List<ShopModel> shops;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (shops.isEmpty) {
      return const Center(
        child: Text('Nothing here', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    final repo = ref.read(adminRepositoryProvider);

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: shops.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final shop = shops[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(shop.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: () => context.push('/shop/${shop.id}'),
                    child: const Text('View'),
                  ),
                ],
              ),
              if (shop.address.isNotEmpty)
                Text(shop.address,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (shop.status != 'approved')
                    _ActionButton(
                      label: 'Approve',
                      color: AppColors.success,
                      onPressed: () => repo.setShopStatus(shop.id, 'approved'),
                    ),
                  if (shop.status != 'rejected')
                    _ActionButton(
                      label: 'Reject',
                      color: AppColors.warning,
                      onPressed: () => repo.setShopStatus(shop.id, 'rejected'),
                    ),
                  if (shop.status != 'banned')
                    _ActionButton(
                      label: 'Ban',
                      color: AppColors.error,
                      onPressed: () => repo.setShopStatus(shop.id, 'banned'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: Size.zero,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
