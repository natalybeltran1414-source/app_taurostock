import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/provider.dart';
import '../providers/provider_model_provider.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../widgets/custom_widgets.dart' as custom; // ← MEJORADO: con alias
import 'provider_form_screen.dart';
import 'purchases_screen.dart';

class ProvidersScreen extends StatefulWidget {
  const ProvidersScreen({Key? key}) : super(key: key);

  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessRuc = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessRuc ?? '0000000000';
      Provider.of<ProviderModelProvider>(context, listen: false).loadProviders(businessRuc);
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
        title: 'Proveedores',
        showBackButton: true,
        actions: [
          // ← MEJORADO: Botones en AppBar
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProviderFormScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PurchasesScreen(),
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
              hintText: 'Buscar proveedor...',
            ),
          ),
          
          Expanded(
            child: Consumer<ProviderModelProvider>(
              builder: (context, providerData, _) {
                final providers = providerData.searchProviders(
                  _searchController.text,
                );

                if (providerData.isLoading) {
                  return const custom.CustomLoadingIndicator( // ← MEJORADO
                    message: 'Cargando proveedores...',
                  );
                }

                if (providers.isEmpty) {
                  return custom.EmptyState( // ← MEJORADO
                    message: 'No hay proveedores registrados',
                    icon: Icons.local_shipping_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return _buildProviderCard(context, provider);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ← MEJORADO: Tarjeta de proveedor usando componentes
  Widget _buildProviderCard(BuildContext context, ProviderModel provider) {
    final hasDebt = provider.accountBalance > 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasDebt 
            ? BorderSide(color: Colors.red.shade200, width: 2)
            : BorderSide.none,
      ),
      elevation: hasDebt ? 4 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información principal
            Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        custom.primaryLilac.withOpacity(0.2),
                        custom.secondaryLilac.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      provider.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: custom.primaryLilac,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Nombre y contacto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.email.isNotEmpty ? provider.email : provider.phone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Badge de deuda
                if (hasDebt)
                  custom.StatusBadge(
                    label: '\$${provider.accountBalance.toStringAsFixed(0)}',
                    color: Colors.red,
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Estadísticas
            Row(
              children: [
                Expanded(
                  child: custom.SummaryCard(
                    title: 'Compras',
                    value: '\$${provider.totalPurchases.toStringAsFixed(0)}',
                    icon: Icons.shopping_cart,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: custom.SummaryCard(
                    title: hasDebt ? 'Deuda' : 'Estado',
                    value: hasDebt
                        ? '\$${provider.accountBalance.toStringAsFixed(0)}'
                        : 'OK',
                    icon: hasDebt ? Icons.warning : Icons.check_circle,
                    color: hasDebt ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Acciones
            Row(
              children: [
                // Botón Editar
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Editar'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ProviderFormScreen(provider: provider),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: custom.primaryLilac,
                      side: BorderSide(color: custom.primaryLilac),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Botón Pagar (solo si hay deuda)
                if (hasDebt)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Pagar'),
                      onPressed: () => _showPaymentDialog(context, provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                
                if (hasDebt) const SizedBox(width: 8),
                
                // Menú de opciones
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (BuildContext context) {
                      return [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('Eliminar', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ];
                    },
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Eliminar Proveedor'),
                              content: Text('¿Eliminar a "${provider.name}" permanentemente?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            );
                          },
                        );
                        
                        if (confirm == true) {
                          final businessRuc = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessRuc ?? '0000000000';
                          final success = await Provider.of<ProviderModelProvider>(
                            context, 
                            listen: false
                          ).deleteProvider(provider.id!, businessRuc);
                          
                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${provider.name} eliminado'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ← MEJORADO: Diálogo de pago
  void _showPaymentDialog(BuildContext context, ProviderModel provider) {
    final paymentController = TextEditingController();
    final debtAmount = provider.accountBalance;

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
                  backgroundColor: custom.primaryLilac.withOpacity(0.1),
                  child: Text(
                    provider.name[0].toUpperCase(),
                    style: TextStyle(color: custom.primaryLilac),
                  ),
              ),
              title: Text(provider.name),
              subtitle: Text('Deuda: \$${debtAmount.toStringAsFixed(2)}'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: paymentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monto a pagar',
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

              // Aquí iría la lógica de pago
              final businessRuc = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessRuc ?? '0000000000';
              await DatabaseService()
                  .updatePurchasePaymentStatus(provider.id!, 'pagado', businessRuc);

              if (context.mounted) {
                Provider.of<ProviderModelProvider>(context, listen: false)
                    .loadProviders(businessRuc);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pago de \$${payment.toStringAsFixed(2)} registrado'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Pagar'),
          ),
        ],
      ),
    );
  }
}
