import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../providers/client_provider.dart';
import '../services/database_service.dart';
import '../widgets/custom_widgets.dart' as custom; // ← MEJORADO: con alias

class AccountsReceivableScreen extends StatefulWidget {
  const AccountsReceivableScreen({Key? key}) : super(key: key);

  @override
  State<AccountsReceivableScreen> createState() =>
      _AccountsReceivableScreenState();
}

class _AccountsReceivableScreenState extends State<AccountsReceivableScreen> {
  late DatabaseService _db;

  @override
  void initState() {
    super.initState();
    _db = DatabaseService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientProvider>(context, listen: false).loadClients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.CustomAppBar( // ← MEJORADO: usar CustomAppBar con alias
        title: 'Cuentas por Cobrar',
        showBackButton: true,
      ),
      body: Consumer<ClientProvider>(
        builder: (context, clientProvider, _) {
          if (clientProvider.isLoading) {
            return const custom.CustomLoadingIndicator( // ← MEJORADO
              message: 'Cargando deudas...',
            );
          }

          // Filtrar solo clientes con deuda
          final clientsWithDebt = clientProvider.clients
              .where((client) => client.accountBalance < 0)
              .toList();

          if (clientsWithDebt.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: custom.EmptyState( // ← MEJORADO
                message: 'No hay cuentas por cobrar',
                icon: Icons.check_circle_outline,
              ),
            );
          }

          // Calcular totales
          final totalDebt = clientsWithDebt.fold<double>(
              0, (sum, client) => sum + (client.accountBalance.abs()));
          final avgDebt = totalDebt / clientsWithDebt.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ← MEJORADO: Tarjetas de resumen con SummaryCard
                Row(
                  children: [
                    Expanded(
                      child: custom.SummaryCard(
                        title: 'Total por Cobrar',
                        value: '\$${totalDebt.toStringAsFixed(2)}',
                        icon: Icons.money_off,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: custom.SummaryCard(
                        title: 'Promedio',
                        value: '\$${avgDebt.toStringAsFixed(2)}',
                        icon: Icons.trending_down,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: custom.SummaryCard(
                        title: 'Clientes',
                        value: clientsWithDebt.length.toString(),
                        icon: Icons.people,
                        color: custom.secondaryPurple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox()), // Espacio vacío para mantener proporción
                  ],
                ),
                const SizedBox(height: 24),
                
                // ← MEJORADO: Título con SectionHeader
                custom.SectionHeader(
                  title: 'Detalle de Deudas',
                ),
                const SizedBox(height: 12),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: clientsWithDebt.length,
                  itemBuilder: (context, index) {
                    final client = clientsWithDebt[index];
                    return _buildDebtCard(context, client);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ← MEJORADO: Tarjeta de deuda usando ListItemCard
  Widget _buildDebtCard(BuildContext context, Client client) {
    final debtAmount = client.accountBalance.abs();
    
    return custom.ListItemCard(
      title: client.name,
      subtitle: '${client.phone} • Compras: \$${client.totalPurchases.toStringAsFixed(2)}',
      amount: '\$${debtAmount.toStringAsFixed(2)}',
      icon: Icons.person,
      color: Colors.red,
      status: 'Vencida',
      onTap: () => _showClientDetailsDialog(context, client),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón de pago
          Container(
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.payment, color: Colors.white, size: 20),
              onPressed: () => _showPaymentDialog(context, client),
            ),
          ),
          const SizedBox(width: 4),
          // Botón de detalles
          Container(
            decoration: BoxDecoration(
              color: custom.secondaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.info_outline, color: custom.secondaryPurple, size: 20),
              onPressed: () => _showClientDetailsDialog(context, client),
            ),
          ),
        ],
      ),
    );
  }

  // ← MEJORADO: Diálogo de pago
  void _showPaymentDialog(BuildContext context, Client client) {
    final paymentController = TextEditingController();
    final debtAmount = client.accountBalance.abs();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: custom.secondaryPurple.withOpacity(0.1),
                child: Text(
                  client.name[0].toUpperCase(),
                  style: TextStyle(color: custom.secondaryPurple),
                ),
              ),
              title: Text(client.name),
              subtitle: Text('Deuda: \$${debtAmount.toStringAsFixed(2)}'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: paymentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monto del Pago',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final payment = double.tryParse(paymentController.text) ?? 0;
              if (payment <= 0 || payment > debtAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Monto inválido'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              await _db.recordClientPayment(client.id!, payment);

              if (context.mounted) {
                Provider.of<ClientProvider>(context, listen: false)
                    .loadClients();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Pago de \$${payment.toStringAsFixed(2)} registrado'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Registrar Pago'),
          ),
        ],
      ),
    );
  }

  // ← MEJORADO: Diálogo de detalles
  void _showClientDetailsDialog(BuildContext context, Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: custom.secondaryPurple.withOpacity(0.1),
              child: Text(
                client.name[0].toUpperCase(),
                style: TextStyle(color: custom.secondaryPurple),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(client.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Teléfono', client.phone),
            _buildDetailRow('Email', client.email),
            _buildDetailRow('Dirección', client.address),
            const Divider(),
            _buildDetailRow(
              'Deuda Total',
              '\$${client.accountBalance.abs().toStringAsFixed(2)}',
              isHighlight: true,
            ),
            _buildDetailRow(
              'Total Compras',
              '\$${client.totalPurchases.toStringAsFixed(2)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}