import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/purchase.dart';
import '../providers/purchase_provider.dart';
import '../widgets/custom_widgets.dart' as custom; // ← MEJORADO: con alias
import 'debts_overview_screen.dart';
import 'purchase_form_screen.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({Key? key}) : super(key: key);

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PurchaseProvider>(context, listen: false).loadPurchases();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.CustomAppBar( // ← MEJORADO: usar CustomAppBar con alias
        title: 'Compras',
        showBackButton: true,
        actions: [
          // ← MEJORADO: Botones en AppBar
          IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PurchaseFormScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.attach_money, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DebtsOverviewScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ← MEJORADO: Búsqueda con SearchBar
          Padding(
            padding: const EdgeInsets.all(16),
            child: custom.SearchBar(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              hintText: 'Buscar compra por ID o estado...',
            ),
          ),
          
          Expanded(
            child: Consumer<PurchaseProvider>(
              builder: (context, purchaseProv, _) {
                final purchases = purchaseProv.searchPurchases(
                  _searchController.text,
                );

                if (purchaseProv.isLoading) {
                  return const custom.CustomLoadingIndicator( // ← MEJORADO
                    message: 'Cargando compras...',
                  );
                }

                if (purchases.isEmpty) {
                  return custom.EmptyState( // ← MEJORADO
                    message: 'No hay compras registradas',
                    icon: Icons.shopping_bag_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: purchases.length,
                  itemBuilder: (context, index) {
                    final purchase = purchases[index];
                    return _buildPurchaseCard(context, purchase);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ← MEJORADO: Tarjeta de compra usando ListItemCard
  Widget _buildPurchaseCard(BuildContext context, Purchase purchase) {
    final isPending = purchase.paymentStatus == 'pendiente';
    final statusColor = isPending ? Colors.orange : Colors.green;
    final statusText = isPending ? 'Pendiente' : 'Pagado';
    
    // Formatear fecha
    final dateStr = '${purchase.purchaseDate.day}/${purchase.purchaseDate.month}/${purchase.purchaseDate.year}';
    
    return custom.ListItemCard(
      title: 'Compra #${purchase.id}',
      subtitle: '$dateStr • ${purchase.items.length} producto${purchase.items.length != 1 ? 's' : ''}',
      amount: '\$${purchase.finalAmount.toStringAsFixed(2)}',
      icon: Icons.shopping_cart,
      color: statusColor,
      status: statusText,
      onTap: isPending ? () => _showPaymentDialog(context, purchase) : null,
      trailing: isPending
          ? IconButton(
              icon: const Icon(Icons.payment, color: Colors.green),
              onPressed: () => _showPaymentDialog(context, purchase),
            )
          : null,
    );
  }

  // ← MEJORADO: Diálogo de pago
  void _showPaymentDialog(BuildContext context, Purchase purchase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marcar como pagado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: custom.secondaryPurple.withOpacity(0.1),
                child: const Icon(Icons.shopping_cart, color: custom.secondaryPurple),
              ),
              title: Text('Compra #${purchase.id}'),
              subtitle: Text('Total: \$${purchase.finalAmount.toStringAsFixed(2)}'),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Confirmar que esta compra ha sido pagada?',
              textAlign: TextAlign.center,
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
              final provider = Provider.of<PurchaseProvider>(
                context, 
                listen: false
              );
              
              final success = await provider.markAsPaid(purchase.id!);
              
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Compra marcada como pagada'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Confirmar pago'),
          ),
        ],
      ),
    );
  }
}