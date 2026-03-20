import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/client_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/custom_widgets.dart' as custom;
import 'main_screen.dart';
import 'inventory_screen.dart';
import 'products_screen.dart';
import 'clients_screen.dart';
import 'purchases_screen.dart';
import 'providers_screen.dart';
import 'transactions_screen.dart';
import 'sales_report_screen.dart';
import 'profile_screen.dart';
import 'debts_overview_screen.dart';
import 'categories_screen.dart';
import 'loyalty_points_screen.dart';
import 'security_screen.dart';
import 'settings_screen.dart';
import 'expense_form_screen.dart';
import 'cash_session_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MainScreen(),
    const InventoryScreen(), // POS rápido
    const ProductsScreen(),
    const ClientsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final businessRuc = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessRuc ?? '0000000000';
    await Future.wait([
      Provider.of<ProductProvider>(context, listen: false).loadProducts(businessRuc),
      Provider.of<ClientProvider>(context, listen: false).loadClients(businessRuc),
      Provider.of<SaleProvider>(context, listen: false).loadSales(businessRuc),
      Provider.of<PurchaseProvider>(context, listen: false).loadPurchases(businessRuc),
      Provider.of<TransactionProvider>(context, listen: false).loadTransactions(businessRuc),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.currentUser?.role == 'admin';
    return Scaffold(
      appBar: custom.CustomAppBar(
        title: 'TauroStock',
        showBackButton: false, // El Dashboard es la raíz
        onBackPressed: null,
      ),
      drawer: _buildDrawer(context, isAdmin),
      body: _screens[_currentIndex],
    );
  }

  // ← MEJORADO: Widget de navegación unificado
  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? custom.primaryLilac.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? custom.primaryLilac : custom.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? custom.primaryLilac : custom.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== SIDEBAR PROFESIONAL (DRAWER) ==========
  Widget _buildDrawer(BuildContext context, bool isAdmin) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Drawer(
      backgroundColor: custom.sidebarBackground,
      child: Column(
        children: [
          // Header Estilo Premium (Alineado con el sidebar oscuro)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 24),
            decoration: BoxDecoration(
              color: custom.sidebarBackground,
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: custom.primaryLilac,
                  child: Text(
                    (user?.fullName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Usuario',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user?.email ?? 'vendedor@taurostock.com',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _sidebarItem(context, 'Panel Principal', Icons.grid_view_outlined, const MainScreen(), isSelected: _currentIndex == 0),
                
                // Botón destacado: Punto de Venta
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Material(
                    color: custom.sidebarSelection,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()));
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt, color: Colors.white, size: 22),
                            const SizedBox(width: 12),
                            const Text(
                              'Punto de Venta',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                _sidebarCategory(
                  title: 'Operaciones',
                  icon: Icons.sync_alt,
                  children: [
                    _sidebarSubItem(context, 'Historial Ventas', const SalesReportScreen()),
                    if (isAdmin) _sidebarSubItem(context, 'Compras e Insumos', const PurchasesScreen()),
                  ],
                ),

                _sidebarCategory(
                  title: 'Catálogo',
                  icon: Icons.inventory_2_outlined,
                  children: [
                    _sidebarSubItem(context, 'Gestión Productos', const ProductsScreen()),
                    if (isAdmin) _sidebarSubItem(context, 'Categorías', const CategoriesScreen()),
                  ],
                ),

                _sidebarCategory(
                  title: 'CRM y Fidelización',
                  icon: Icons.people_outline,
                  children: [
                    _sidebarSubItem(context, 'Clientes', const ClientsScreen()),
                    _sidebarSubItem(context, 'Proveedores', const ProvidersScreen()),
                    if (isAdmin) _sidebarSubItem(context, 'Puntos (Pronto)', const LoyaltyPointsScreen()),
                  ],
                ),

                _sidebarCategory(
                  title: 'Finanzas',
                  icon: Icons.account_balance_wallet_outlined,
                  children: [
                    if (isAdmin) _sidebarSubItem(context, 'Cuentas x Cobrar', const DebtsOverviewScreen()),
                    if (isAdmin) _sidebarSubItem(context, 'Cuentas x Pagar', const ProvidersScreen()), // Filtrado por deuda ideally
                    if (isAdmin) _sidebarSubItem(context, 'Gastos Operativos', const TransactionsScreen()),
                    if (isAdmin) _sidebarSubItem(context, 'Cierre de Caja', const CashSessionScreen()),
                    if (isAdmin) _sidebarSubItem(context, 'Movimientos', const TransactionsScreen()),
                  ],
                ),

                if (isAdmin) _sidebarItem(context, 'Reportes y Análisis', Icons.pie_chart_outline, const SalesReportScreen()),

                _sidebarCategory(
                  title: 'Administración',
                  icon: Icons.admin_panel_settings_outlined,
                  children: [
                    _sidebarSubItem(context, 'Seguridad', const SecurityScreen()),
                    if (isAdmin) _sidebarSubItem(context, 'Ajustes', const SettingsScreen()),
                  ],
                ),

                const Divider(color: Colors.white10, indent: 16, endIndent: 16),
                _sidebarItem(context, 'Cerrar Sesión', Icons.logout, null, isLogout: true),
              ],
            ),
          ),
          
          // Versión al pie
          Container(
            padding: const EdgeInsets.all(20),
            child: Text(
              'TauroStock v1.0.0',
              style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(BuildContext context, String title, IconData icon, Widget? screen, {bool isSelected = false, bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.redAccent : (isSelected ? custom.sidebarSelection : custom.sidebarText.withOpacity(0.7)), size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: isLogout ? Colors.redAccent : (isSelected ? Colors.white : custom.sidebarText.withOpacity(0.9)),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      dense: true,
      onTap: () {
        Navigator.pop(context);
        if (isLogout) {
          _confirmLogout(context);
        } else if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
      },
    );
  }

  Widget _sidebarCategory({required String title, required IconData icon, required List<Widget> children}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: custom.sidebarText.withOpacity(0.7), size: 22),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: custom.sidebarText.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        iconColor: custom.sidebarText.withOpacity(0.5),
        collapsedIconColor: custom.sidebarText.withOpacity(0.5),
        children: children,
      ),
    );
  }

  Widget _sidebarSubItem(BuildContext context, String title, Widget? screen) {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: custom.sidebarText.withOpacity(0.7),
          ),
        ),
        dense: true,
        onTap: () {
          Navigator.pop(context);
          if (screen != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
          }
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
