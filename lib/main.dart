import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
import 'screens/all_modules_screen.dart';

void main() {
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
          '/all_modules': (context) => const AllModulesScreen(),
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
            ? const _MainWithBottomNav() 
            : const LoginScreen();
      },
    );
  }
}

/// Contenedor principal con BottomNavigationBar de UN SOLO ITEM
class _MainWithBottomNav extends StatefulWidget {
  const _MainWithBottomNav();

  @override
  State<_MainWithBottomNav> createState() => _MainWithBottomNavState();
}

class _MainWithBottomNavState extends State<_MainWithBottomNav> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            // Si ya estamos en MainScreen, no hacemos nada
            return;
          }
          // Si el índice es 1, navegamos a AllModulesScreen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AllModulesScreen(),
            ),
          );
          // Restablecemos el índice a 0 para que el bottom nav siempre muestre "Inicio" seleccionado
          setState(() {
            _currentIndex = 0;
          });
        },
        backgroundColor: const Color(0xFF5A189A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        items: const [
          // SOLO DOS ITEMS: Inicio y el botón para ver todos los módulos
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined), 
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apps), 
            label: 'Módulos',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Siempre mostramos MainScreen cuando el índice es 0
    return const MainScreen();
  }
}