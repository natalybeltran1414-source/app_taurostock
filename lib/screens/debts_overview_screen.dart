import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../models/purchase.dart';
import '../providers/client_provider.dart';
import '../providers/provider_model_provider.dart';
import '../services/database_service.dart';
import '../widgets/custom_widgets.dart';
import 'accounts_receivable_screen.dart';
import 'purchases_screen.dart'; // ← CAMBIADO: antes era accounts_payable_screen.dart

class DebtsOverviewScreen extends StatefulWidget {
  const DebtsOverviewScreen({Key? key}) : super(key: key);

  @override
  State<DebtsOverviewScreen> createState() => _DebtsOverviewScreenState();
}

class _DebtsOverviewScreenState extends State<DebtsOverviewScreen> {
  List<Purchase> _pendingPurchases = [];
  bool _loadingPurchases = true;

  @override
  void initState() {
    super.initState();
    _loadPendingPurchases();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      Provider.of<ClientProvider>(context, listen: false).loadClients(),
      Provider.of<ProviderModelProvider>(context, listen: false).loadProviders(),
    ]);
  }

  Future<void> _loadPendingPurchases() async {
    setState(() => _loadingPurchases = true);
    _pendingPurchases = await DatabaseService().getPendingPayments();
    setState(() => _loadingPurchases = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gestión de Deudas',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              Provider.of<ClientProvider>(context, listen: false).loadClients();
              Provider.of<ProviderModelProvider>(context, listen: false).loadProviders();
              _loadPendingPurchases();
            },
          ),
        ],
      ),
      body: Consumer2<ClientProvider, ProviderModelProvider>(
        builder: (context, clientProvider, providerProvider, _) {
          // Filtrar clientes con deuda
          final clientsWithDebt = clientProvider.clients
              .where((client) => client.accountBalance < 0)
              .toList();
          
          // Calcular totales
          final totalReceivable = clientsWithDebt.fold<double>(
            0, (sum, client) => sum + client.accountBalance.abs()
          );
          
          final totalPayable = providerProvider.totalDebt;
          final netBalance = totalReceivable - totalPayable;

          // Separar deudas por urgencia
          final urgentDebts = clientsWithDebt.where((client) {
            // Simular deudas urgentes (las primeras 3)
            return client.accountBalance.abs() > 1000;
          }).take(3).toList();

          final upcomingDebts = clientsWithDebt
              .where((client) => !urgentDebts.contains(client))
              .take(3).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                clientProvider.loadClients(),
                providerProvider.loadProviders(),
                _loadPendingPurchases(),
              ]);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resumen financiero
                  _buildFinancialSummary(totalReceivable, totalPayable, netBalance),
                  const SizedBox(height: 24),

                  // Deudas urgentes (rojo)
                  if (urgentDebts.isNotEmpty) ...[
                    _buildSectionHeader(
                      '🔴 Deudas por Cobrar Urgentes',
                      'Ver todas',
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AccountsReceivableScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...urgentDebts.map((client) => _buildClientDebtCard(client, urgent: true)),
                    const SizedBox(height: 20),
                  ],

                  // Próximos vencimientos (amarillo)
                  if (upcomingDebts.isNotEmpty) ...[
                    _buildSectionHeader(
                      '🟡 Próximos Vencimientos',
                      'Ver todas',
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AccountsReceivableScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...upcomingDebts.map((client) => _buildClientDebtCard(client, urgent: false)),
                    const SizedBox(height: 20),
                  ],

                  // Deudas por pagar
                  if (_pendingPurchases.isNotEmpty) ...[
                    _buildSectionHeader(
                      '🔵 Deudas por Pagar',
                      'Ver todas',
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PurchasesScreen(), // ← CAMBIADO
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._pendingPurchases.take(3).map((purchase) => _buildPayableCard(purchase)),
                    const SizedBox(height: 20),
                  ],

                  // Si no hay deudas
                  if (clientsWithDebt.isEmpty && _pendingPurchases.isEmpty)
                    const Center(
                      child: EmptyState(
                        message: 'No hay deudas pendientes',
                        icon: Icons.check_circle_outline,
                      ),
                    ),

                  // Botones de acceso rápido
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          'Cuentas por Cobrar',
                          Icons.receipt_outlined,
                          Colors.red,
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AccountsReceivableScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionButton(
                          'Cuentas por Pagar',
                          Icons.payment_outlined,
                          Colors.blue,
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PurchasesScreen(), // ← CAMBIADO
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinancialSummary(double receivable, double payable, double net) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[800]!, Colors.purple[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Por Cobrar', receivable, Colors.green[200]!),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildSummaryItem('Por Pagar', payable, Colors.red[200]!),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white30),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Balance Neto',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              Text(
                '\$${net.toStringAsFixed(2)}',
                style: TextStyle(
                  color: net >= 0 ? Colors.green[200] : Colors.red[200],
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String actionLabel, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(actionLabel),
        ),
      ],
    );
  }

  Widget _buildClientDebtCard(Client client, {required bool urgent}) {
    final debtAmount = client.accountBalance.abs();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: urgent ? Colors.red[200]! : Colors.orange[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: urgent ? Colors.red[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.person,
              color: urgent ? Colors.red : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  client.phone,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${debtAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: urgent ? Colors.red : Colors.orange,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: urgent ? Colors.red[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  urgent ? 'Vencida' : 'Próximo',
                  style: TextStyle(
                    fontSize: 10,
                    color: urgent ? Colors.red[700] : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayableCard(Purchase purchase) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shopping_cart,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compra #${purchase.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${purchase.items.length} productos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${purchase.finalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Pendiente',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}