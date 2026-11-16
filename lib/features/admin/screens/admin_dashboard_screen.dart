import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final shopsAsync = ref.watch(allShopsProvider);
    final ordersAsync = ref.watch(allOrdersAdminProvider);

    final userCount = usersAsync.value?.length ?? 0;
    final shops = shopsAsync.value ?? [];
    final pendingShops = shops.where((s) => s.status == 'pending').length;
    final orders = ordersAsync.value ?? [];
    final revenue = orders
        .where((o) => o.status == 'completed')
        .fold<double>(0, (sum, o) => sum + o.total);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatTile(
                icon: Icons.people_outline,
                label: 'Total Users',
                value: '$userCount',
                color: AppColors.primary,
              ),
              _StatTile(
                icon: Icons.storefront_outlined,
                label: 'Total Shops',
                value: '${shops.length}',
                color: AppColors.secondary,
              ),
              _StatTile(
                icon: Icons.pending_actions_outlined,
                label: 'Pending Approval',
                value: '$pendingShops',
                color: pendingShops > 0 ? AppColors.warning : AppColors.success,
              ),
              _StatTile(
                icon: Icons.payments_outlined,
                label: 'Completed Revenue',
                value: 'Rs ${revenue.toStringAsFixed(0)}',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _MenuTile(
            icon: Icons.storefront_outlined,
            title: 'Manage Shops',
            subtitle: 'Approve, reject, or ban shops',
            badge: pendingShops > 0 ? pendingShops : null,
            onTap: () => context.push('/admin/shops'),
          ),
          _MenuTile(
            icon: Icons.people_outline,
            title: 'Manage Users',
            subtitle: 'Ban or unban accounts',
            onTap: () => context.push('/admin/users'),
          ),
          _MenuTile(
            icon: Icons.inventory_2_outlined,
            title: 'Manage Products',
            subtitle: 'Moderate listings marketplace-wide',
            onTap: () => context.push('/admin/products'),
          ),
          _MenuTile(
            icon: Icons.receipt_long_outlined,
            title: 'All Orders',
            subtitle: 'View every order across the marketplace',
            onTap: () => context.push('/admin/orders'),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: badge != null
            ? CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.warning,
                child: Text('$badge',
                    style: const TextStyle(fontSize: 11, color: Colors.white)),
              )
            : const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
