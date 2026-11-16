import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_orders_screen.dart';
import '../../features/admin/screens/manage_products_screen.dart';
import '../../features/admin/screens/manage_shops_screen.dart';
import '../../features/admin/screens/manage_users_screen.dart';
import '../../features/auth/screens/email_verification_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/orders/screens/order_history_screen.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../../features/seller/screens/add_edit_product_screen.dart';
import '../../features/seller/screens/create_shop_screen.dart';
import '../../features/seller/screens/seller_dashboard_screen.dart';
import '../../features/seller/screens/seller_orders_screen.dart';
import '../../features/shop/screens/shop_screen.dart';
import '../../models/product_model.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../constants/app_constants.dart';

/// Central navigation graph. Redirect logic here is what actually
/// enforces "must be logged in" / "must be verified" / "must be an
/// admin" — screens themselves stay dumb about routing.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _GoRouterRefreshStream(ref),
    redirect: (context, state) async {
      final loc = state.matchedLocation;

      // Splash always resolves to its real destination once auth
      // state is known.
      if (authState.isLoading && loc != '/splash') return null;

      if (loc == '/splash') {
        if (authState.isLoading) return null;
        final user = authState.value;
        if (user == null) {
          final prefs = await SharedPreferences.getInstance();
          final onboardingDone =
              prefs.getBool(OnboardingScreen.prefKeyDone) ?? false;
          return onboardingDone ? '/login' : '/onboarding';
        }
        return user.emailVerified ? '/' : '/verify-email';
      }

      final User? user = authState.value;
      final publicRoutes = {
        '/onboarding',
        '/login',
        '/register',
        '/forgot-password',
      };

      if (user == null) {
        return publicRoutes.contains(loc) ? null : '/login';
      }

      if (!user.emailVerified && loc != '/verify-email') {
        return '/verify-email';
      }

      if (user.emailVerified &&
          (publicRoutes.contains(loc) || loc == '/verify-email')) {
        return '/';
      }

      // Admin-only routes: block anyone whose profile role isn't
      // 'admin'. Reading the profile here (rather than trusting a
      // provider) keeps this check self-contained and synchronous
      // with the rest of the redirect logic.
      if (loc.startsWith('/admin')) {
        final profile = await ref.read(userProfileProvider.future);
        if (profile?.role != AppConstants.roleAdmin) {
          return '/';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (_, __) => const EmailVerificationScreen(),
      ),
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/shop/:id',
        builder: (context, state) => ShopScreen(
          shopId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: '/orders', builder: (_, __) => const OrderHistoryScreen()),
      GoRoute(
        path: '/orders/:id',
        builder: (context, state) => OrderDetailScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/seller/create-shop',
        builder: (_, __) => const CreateShopScreen(),
      ),
      GoRoute(
        path: '/seller/dashboard',
        builder: (_, __) => const SellerDashboardScreen(),
      ),
      GoRoute(
        path: '/seller/orders',
        builder: (_, __) => const SellerOrdersScreen(),
      ),
      GoRoute(
        path: '/seller/product/add',
        builder: (_, __) => const AddEditProductScreen(),
      ),
      GoRoute(
        path: '/seller/product/edit/:id',
        builder: (context, state) => AddEditProductScreen(
          existing: state.extra as ProductModel?,
        ),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/shops',
        builder: (_, __) => const ManageShopsScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (_, __) => const ManageUsersScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (_, __) => const ManageProductsScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (_, __) => const AdminOrdersScreen(),
      ),
    ],
  );
});

/// Bridges Riverpod's [authStateChangesProvider] stream into a
/// [Listenable] so GoRouter re-evaluates `redirect` whenever auth
/// state changes.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Ref ref) {
    ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
  }
}
