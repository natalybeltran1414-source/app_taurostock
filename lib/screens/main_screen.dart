import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_widgets.dart' as custom;

class MainScreen extends StatelessWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final userName = user?.fullName ?? 'Usuario';
    final businessName = user?.businessName ?? 'Mi Negocio';
    final businessRuc = user?.businessRuc ?? '0000000000';
    final isAdmin = user?.role == 'admin';

    return SelectionContainer.disabled(
      child: Container(
        color: custom.softBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Saludo
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        custom.primaryLilac.withOpacity(0.1),
                        custom.secondaryLilac.withOpacity(0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: custom.primaryLilac.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [custom.primaryLilac, custom.secondaryLilac],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          userName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bienvenido de nuevo a $businessName,', style: TextStyle(fontSize: 12, color: custom.textSecondary)),
                          Text(userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: custom.textPrimary)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Accesos rápidos
                custom.SectionHeader(title: 'Accesos Rápidos'),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    _buildQuickAccessBtn(context, 'Nueva Venta', Icons.add_shopping_cart, Colors.purple, () => Navigator.pushNamed(context, '/inventory')),
                    if (isAdmin)
                      _buildQuickAccessBtn(context, 'Nuevo Gasto', Icons.money_off, Colors.red, () => Navigator.pushNamed(context, '/expense_form')),
                    if (isAdmin)
                      _buildQuickAccessBtn(context, 'Cierre Caja', Icons.account_balance_wallet, Colors.teal, () => Navigator.pushNamed(context, '/cash_session')),
                    _buildQuickAccessBtn(context, 'Inventario', Icons.inventory_2, Colors.blue, () => Navigator.pushNamed(context, '/products')),
                  ],
                ),
                const SizedBox(height: 24),

                // Resumen financiero
                Consumer3<SaleProvider, PurchaseProvider, TransactionProvider>(
                  builder: (context, saleProvider, purchaseProvider, transactionProvider, _) {
                    final totalVentas = saleProvider.totalSales;
                    final totalCompras = purchaseProvider.totalPurchases;
                    final totalIngresosExtras = transactionProvider.totalIncome;
                    final totalGastosExtras = transactionProvider.totalExpense;
                    final ingresosTotales = totalVentas + totalIngresosExtras;
                    final gastosTotales = totalCompras + totalGastosExtras;
                    final utilidad = ingresosTotales - gastosTotales;

                    return Column(
                      children: [
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.15,
                          children: [
                            custom.SummaryCard(
                              title: 'Ventas',
                              value: '\$${totalVentas.toStringAsFixed(2)}',
                              icon: Icons.trending_up,
                              color: Colors.green,
                            ),
                            custom.SummaryCard(
                              title: 'Ingresos Extras',
                              value: '\$${totalIngresosExtras.toStringAsFixed(2)}',
                              icon: Icons.add_circle_outline,
                              color: Colors.teal,
                            ),
                            custom.SummaryCard(
                              title: 'Compras',
                              value: '\$${totalCompras.toStringAsFixed(2)}',
                              icon: Icons.shopping_bag_outlined,
                              color: Colors.orange,
                            ),
                            custom.SummaryCard(
                              title: 'Gastos Extras',
                              value: '\$${totalGastosExtras.toStringAsFixed(2)}',
                              icon: Icons.money_off,
                              color: Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                utilidad >= 0 ? Colors.green[700]! : Colors.red[700]!,
                                utilidad >= 0 ? Colors.green[400]! : Colors.red[400]!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (utilidad >= 0 ? Colors.green : Colors.red).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'UTILIDAD NETA',
                                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Rendimiento Real',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(
                                '\$${utilidad.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),

                // Ventas últimas 7 días
                Consumer<SaleProvider>(
                  builder: (context, saleProvider, _) {
                    if (saleProvider.sales.isEmpty && !saleProvider.isLoading) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => saleProvider.loadSales(businessRuc));
                      return const SizedBox.shrink();
                    }
                    if (saleProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final salesByDay = saleProvider.salesByDay;
                    final todaySales = saleProvider.todaySales;
                    final changePercentage = saleProvider.changePercentage;
                    final todayProducts = saleProvider.todayProductsCount;
                    final topProducts = saleProvider.topProducts;
                    final maxValue = salesByDay.values.isNotEmpty ? salesByDay.values.reduce((a, b) => a > b ? a : b) : 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7B2CBF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.trending_up, color: Color(0xFF7B2CBF), size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Resumen de ventas (últimos 7 días)',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _kpiCard('Hoy', '\$${todaySales.toStringAsFixed(2)}', Icons.flash_on, Colors.green),
                              _kpiCard('Cambio', '${changePercentage.toStringAsFixed(1)}%', Icons.trending_up, Colors.blue),
                              _kpiCard('Productos', '$todayProducts', Icons.inventory_2, Colors.deepPurple),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: salesByDay.entries.map((entry) {
                                final value = entry.value;
                                final barHeight = maxValue == 0 ? 0 : (value / maxValue) * 120;
                                return Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        height: barHeight,
                                        width: 16,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7B2CBF).withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(entry.key, style: const TextStyle(fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text('\$${value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Text('Top productos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: List.generate(topProducts.length, (index) {
                                final product = topProducts[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF7B2CBF).withOpacity(0.1),
                                    child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF7B2CBF))),
                                  ),
                                  title: Text(product['name']),
                                  subtitle: Text('Unidades: ${product['quantity']}'),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7B2CBF).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '\$${product['total'].toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7B2CBF), fontSize: 13),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Consumer<ProductProvider>(
                            builder: (context, productProvider, _) {
                              final lowStockProducts = productProvider.products.where((p) => p.isLowStock).take(3).toList();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Stock Bajo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: lowStockProducts.isEmpty ? Colors.grey.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                                      ),
                                    ),
                                    child: lowStockProducts.isEmpty
                                        ? Center(
                                            child: Column(
                                              children: [
                                                Icon(Icons.check_circle_outline, size: 40, color: Colors.grey[400]),
                                                const SizedBox(height: 8),
                                                Text('No hay productos con stock bajo', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                              ],
                                            ),
                                          )
                                        : Column(
                                            children: lowStockProducts.map((product) {
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 12),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 36,
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                        color: Colors.orange.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Icon(Icons.inventory_2_outlined, color: Colors.orange, size: 20),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            'Stock: ${product.quantity} (Mín: ${product.minStock})',
                                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.orange.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        '${product.quantity}',
                                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helpers
  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: custom.textSecondary)),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessBtn(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.08),
        highlightColor: color.withOpacity(0.04),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: custom.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

