import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';

// Importar todas las pantallas
import 'inventory_screen.dart';
import 'purchases_screen.dart';
import 'products_screen.dart';
import 'clients_screen.dart';
import 'providers_screen.dart';
import 'debts_overview_screen.dart';
import 'transactions_screen.dart';
import 'sales_report_screen.dart';
import 'profile_screen.dart';


class AllModulesScreen extends StatelessWidget {
  const AllModulesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Todos los Módulos',
        showBackButton: true,
      ),
      // ← CORREGIDO: Envolver en SingleChildScrollView para evitar overflow
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true, // ← NUEVO: Para que el grid ocupe solo su espacio
              physics: const NeverScrollableScrollPhysics(), // ← NUEVO: Deshabilitar scroll interno
              crossAxisCount: 2, // ← CAMBIADO: De 3 a 2 columnas
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1, // ← AJUSTADO: Un poco más alto para mejor visualización
              children: [
                _buildModuleCard(
                  context,
                  'Ventas',
                  Icons.shopping_cart,
                  Colors.purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InventoryScreen()),
                  ),
                ),
                _buildModuleCard(
                  context,
                  'Compras',
                  Icons.inventory,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PurchasesScreen()),
                  ),
                ),
                _buildModuleCard(
                  context,
                  'Productos',
                  Icons.category,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductsScreen()),
                  ),
                ),
                _buildModuleCard(
                  context,
                  'Clientes',
                  Icons.people,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClientsScreen()),
                  ),
                ),
                _buildModuleCard(
                  context,
                  'Proveedores',
                  Icons.local_shipping,
                  Colors.teal,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProvidersScreen()),
                  ),
                ),
                _buildModuleCard(
                  context,
                  'Deudas',
                  Icons.account_balance_wallet,
                  Colors.red,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DebtsOverviewScreen()),
                  ),
                ),
                _buildModuleCard(
                  context,
                  'Ingresos/Gastos',
                  Icons.receipt_long,
                  Colors.brown,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                  ),
                ),
                _buildModuleCard(
                  context,
                  'Reportes',
                  Icons.assessment,
                  Colors.indigo,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalesReportScreen()),
                  ),
                ),
                _buildModuleCard(
                  context,
                  'Perfil',
                  Icons.person,
                  Colors.pink,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                ),
               
              ],
            ),
            const SizedBox(height: 20), // ← NUEVO: Espacio extra al final
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 3, // ← MEJORADO: Sombra más pronunciada
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // ← MEJORADO: Bordes más redondeados
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16), // ← AUMENTADO: Ícono más grande
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32), // ← AUMENTADO: Tamaño de ícono
              ),
              const SizedBox(height: 12), // ← AUMENTADO: Más espacio
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14, // ← AUMENTADO: Texto más grande
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}