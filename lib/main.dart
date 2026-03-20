import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/client_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/provider_model_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/purchase_cart_provider.dart';
import 'providers/sale_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/cash_provider.dart';
import 'providers/category_provider.dart';
import 'providers/settings_provider.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/products_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/main_screen.dart';
import 'screens/providers_screen.dart';
import 'screens/provider_form_screen.dart';
import 'screens/purchases_screen.dart';
import 'screens/purchase_form_screen.dart';
import 'screens/sales_report_screen.dart';
import 'screens/accounts_receivable_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/transaction_form_screen.dart';
import 'screens/cash_session_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/expense_form_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 🧹 Solo cerramos la sesión previa para evitar auto-login en desarrollo.
  // No borramos la base de datos para conservar el usuario admin de arranque.
  await AuthService().logout(); // borra SharedPreferences de sesión
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProviderModelProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseCartProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => CashProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'TauroStock',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5A189A),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF5A189A),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B2CBF),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF7B2CBF), width: 2),
            ),
          ),
        ),
        home: const _HomeWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/products': (context) => const ProductsScreen(),
          '/clients': (context) => const ClientsScreen(),
          '/inventory': (context) => const InventoryScreen(),
          '/cart': (context) => const CartScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/providers': (context) => const ProvidersScreen(),
          '/provider_form': (context) => const ProviderFormScreen(),
          '/purchases': (context) => const PurchasesScreen(),
          '/purchase_form': (context) => const PurchaseFormScreen(),
          '/accounts_receivable': (context) => const AccountsReceivableScreen(),
          '/sales_report': (context) => const SalesReportScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/transactions': (context) => const TransactionsScreen(),
          '/transaction_form': (context) => const TransactionFormScreen(),
          '/cash_session': (context) => const CashSessionScreen(),
          '/categories': (context) => const CategoriesScreen(),
          '/expense_form': (context) => const ExpenseFormScreen(),
        },
      ),
    );
  }
}

/// Controla si se muestra el Login o el Dashboard
class _HomeWrapper extends StatelessWidget {
  const _HomeWrapper();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF5A189A))),
          );
        }

        return authProvider.isLoggedIn 
            ? const DashboardScreen() 
            : const LoginScreen();
      },
    );
  }
}

// Se elimina _MainWithBottomNav y sus clases relacionadas ya que DashboardScreen ahora maneja la navegación centralizada
