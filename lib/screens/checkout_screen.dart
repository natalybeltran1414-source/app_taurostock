import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../models/sale.dart';
import '../models/kardex.dart';
import '../providers/cart_provider.dart';
import '../providers/client_provider.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../widgets/custom_widgets.dart' as custom; // ← MEJORADO: con alias

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Controladores
  late TextEditingController _clientSearchController;
  late TextEditingController _cashReceivedController;
  late TextEditingController _changeController;
  
  // Variables de estado
  Client? _selectedClient;
  List<SalePayment> _payments = []; // ← NUEVO: Lista de pagos
  bool _showClientResults = false;
  final FocusNode _clientSearchFocus = FocusNode();
  
  // Calculadora de vuelto
  double _cashReceived = 0;
  double _change = 0;

  @override
  void initState() {
    super.initState();
    _clientSearchController = TextEditingController();
    _cashReceivedController = TextEditingController();
    _changeController = TextEditingController();
    
    _clientSearchFocus.addListener(() {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_clientSearchFocus.hasFocus) {
          setState(() => _showClientResults = false);
        }
      });
    });
  }

  @override
  void dispose() {
    _clientSearchController.dispose();
    _cashReceivedController.dispose();
    _changeController.dispose();
    _clientSearchFocus.dispose();
    super.dispose();
  }

  // Calcular total pagado
  double get _totalPaid => _payments.fold(0, (sum, p) => sum + p.amount);

  // Calcular vuelto (solo si el último pago es efectivo y supera el total)
  void _calculateChange(String value) {
    // Esta lógica cambiará para ser más dinámica por cada pago de efectivo
  }

  void _addPayment(String method, double amount) {
    setState(() {
      _payments.add(SalePayment(saleId: 0, method: method, amount: amount));
    });
  }

  void _removePayment(int index) {
    setState(() {
      _payments.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.CustomAppBar( // ← MEJORADO: usar CustomAppBar con alias
        title: 'Finalizar Venta',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de productos (MEJORADO)
            _buildProductsSummary(),
            const Divider(height: 32),
            
            // Totales (MEJORADO)
            _buildTotals(),
            const SizedBox(height: 24),
            
            // Buscador de cliente (MEJORADO con componentes)
            _buildClientSearch(),
            const SizedBox(height: 20),
            
            // Gestión de Pagos Mixtos (NUEVO)
            Consumer<CartProvider>(
              builder: (context, cartProvider, _) => _buildMixedPaymentSection(cartProvider),
            ),
            
            const SizedBox(height: 30),
            
            // Botón completar (MEJORADO con CustomButton)
            Consumer<CartProvider>(
              builder: (context, cartProvider, _) {
                return custom.CustomButton( // ← MEJORADO
                  label: 'COMPLETAR VENTA (\$${cartProvider.total.toStringAsFixed(2)})',
                  onPressed: () => _showConfirmDialog(cartProvider),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ← MEJORADO: Resumen de productos usando ListItemCard
  Widget _buildProductsSummary() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            custom.SectionHeader( // ← MEJORADO
              title: 'Productos seleccionados',
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cartProvider.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = cartProvider.items[index];
                return custom.ListItemCard(
                  title: item.product.name,
                  subtitle: '${item.quantity} x \$${item.product.salePrice.toStringAsFixed(2)}',
                  amount: '\$${item.totalPrice.toStringAsFixed(2)}',
                  icon: Icons.shopping_cart,
                  color: custom.primaryLilac,
                  status: '${item.quantity} unidad(es)',
                  onTap: null,
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ← MEJORADO: Totales con diseño unificado
  Widget _buildTotals() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                custom.primaryLilac.withOpacity(0.1),
                custom.primaryLilac.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: custom.primaryLilac.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                  Text(
                    '\$${cartProvider.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Descuento:', style: TextStyle(fontSize: 16)),
                  Text(
                    '\$${cartProvider.discount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: cartProvider.discount > 0 ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(
                    '\$${cartProvider.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: custom.primaryLilac,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ← MEJORADO: Buscador de cliente con SearchBar
  Widget _buildClientSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cliente (opcional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        custom.SearchBar(
          controller: _clientSearchController,
          onChanged: (value) => setState(() => _showClientResults = value.isNotEmpty),
          hintText: 'Buscar por nombre, cédula o teléfono...',
        ),
        
        // Cliente seleccionado
        if (_selectedClient != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  custom.primaryLilac.withOpacity(0.1),
                  custom.primaryLilac.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: custom.primaryLilac),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: custom.primaryLilac,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedClient!.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          if (_selectedClient!.identification != null &&
                              _selectedClient!.identification!.isNotEmpty) ...[
                            Icon(Icons.badge, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              _selectedClient!.identification!,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _selectedClient!.phone,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_selectedClient!.accountBalance < 0)
                  custom.StatusBadge(
                    label: 'Debe \$${_selectedClient!.accountBalance.abs().toStringAsFixed(2)}',
                    color: Colors.red,
                  ),
              ],
            ),
          ),
        
        // Resultados de búsqueda
        if (_showClientResults && _selectedClient == null)
          Consumer<ClientProvider>(
            builder: (context, clientProvider, _) {
              final results = clientProvider.searchClients(_clientSearchController.text);
              
              if (results.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.person_off, size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No se encontraron clientes',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final client = results[index];
                    final hasDebt = client.accountBalance < 0;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: hasDebt
                            ? Colors.red.withOpacity(0.1)
                            : custom.primaryLilac.withOpacity(0.1),
                        child: Text(
                          client.name[0].toUpperCase(),
                          style: TextStyle(
                            color: hasDebt ? Colors.red : custom.primaryLilac,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(client.name),
                      subtitle: Text(
                        '${client.identification ?? ''} • ${client.phone}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: hasDebt
                          ? custom.StatusBadge(
                              label: 'Debe \$${client.accountBalance.abs().toStringAsFixed(0)}',
                              color: Colors.red,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedClient = client;
                          _clientSearchController.clear();
                          _showClientResults = false;
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  // ← NUEVO: Sección de pagos mixtos rediseñada
  Widget _buildMixedPaymentSection(CartProvider cartProvider) {
    final total = cartProvider.total;
    final remaining = total - _totalPaid;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        custom.SectionHeader(title: 'Pagos Registrados'),
        const SizedBox(height: 12),
        
        // Lista de pagos realizados
        if (_payments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Center(
              child: Text('No hay pagos registrados', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _payments.length,
            itemBuilder: (context, index) {
              final payment = _payments[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: custom.primaryLilac.withOpacity(0.1),
                    child: Icon(_getPaymentIcon(payment.method), color: custom.primaryLilac, size: 20),
                  ),
                  title: Text(payment.method.capitalize()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$${payment.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removePayment(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
        const SizedBox(height: 20),
        
        // Resumen de saldo
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: remaining <= 0 ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pendiente:', style: TextStyle(color: Colors.grey[700])),
                  Text(
                    remaining > 0 ? '\$${remaining.toStringAsFixed(2)}' : '\$0.00',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: remaining > 0 ? Colors.orange[800] : Colors.green[800],
                    ),
                  ),
                ],
              ),
              if (remaining < 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Vuelto:', style: TextStyle(color: Colors.grey[700])),
                    Text(
                      '\$${remaining.abs().toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Selector de nuevo pago
        if (remaining > 0) ...[
          const Text('Añadir Pago', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAddPaymentChip('Efectivo', Icons.money, 'efectivo', remaining),
              _buildAddPaymentChip('Tarjeta', Icons.credit_card, 'tarjeta', remaining),
              _buildAddPaymentChip('Transfer', Icons.swap_horiz, 'transferencia', remaining),
              _buildAddPaymentChip('Crédito', Icons.receipt, 'credito', remaining),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAddPaymentChip(String label, IconData icon, String method, double remaining) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: custom.primaryLilac),
      label: Text(label),
      onPressed: () => _showAddPaymentDialog(method, remaining),
      backgroundColor: Colors.white,
      side: BorderSide(color: custom.primaryLilac.withOpacity(0.3)),
    );
  }

  void _showAddPaymentDialog(String method, double remaining) {
    final controller = TextEditingController(text: remaining.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Añadir Pago: ${method.capitalize()}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Monto',
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          custom.CustomButton(
            label: 'AGREGAR',
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                if (method == 'credito' && _selectedClient == null) {
                  _showErrorDialog('Debe seleccionar un cliente para pagos a crédito');
                  return;
                }
                _addPayment(method, amount);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'efectivo': return Icons.money;
      case 'tarjeta': return Icons.credit_card;
      case 'transferencia': return Icons.swap_horiz;
      case 'credito': return Icons.receipt;
      default: return Icons.help_outline;
    }
  }

  // Diálogo de confirmación actualizado
  Future<void> _showConfirmDialog(CartProvider cartProvider) async {
    final total = cartProvider.total;
    final remaining = total - _totalPaid;
    
    if (remaining > 0) {
      _showErrorDialog('Aún falta cubrir \$${remaining.toStringAsFixed(2)} del total.');
      return;
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar venta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: \$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Pagos:'),
            ..._payments.map((p) => Text('• ${p.method.capitalize()}: \$${p.amount.toStringAsFixed(2)}')),
            if (_selectedClient != null) ...[
              const SizedBox(height: 8),
              Text('Cliente: ${_selectedClient!.name}'),
            ],
            const SizedBox(height: 16),
            const Text('¿Confirmar la venta?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processSale(cartProvider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // Validar y completar venta (SIN CAMBIOS)
  Future<void> _processSale(CartProvider cartProvider) async {
    final total = cartProvider.total;

    if (cartProvider.isEmpty) {
      _showErrorDialog('No hay productos seleccionados');
      return;
    }

    if (_payments.isEmpty) {
      _showErrorDialog('No se han registrado pagos');
      return;
    }

    final remaining = total - _totalPaid;
    if (remaining > 0) {
      _showErrorDialog('El monto pagado es insuficiente');
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final businessRuc = authProvider.currentUser?.businessRuc ?? '0000000000';
      final userId = authProvider.currentUser?.id;
      final databaseService = DatabaseService();
      
      // Determinar método de pago principal o "mixto"
      String finalMethod = _payments.length == 1 ? _payments.first.method : 'mixto';
      bool hasCredit = _payments.any((p) => p.method == 'credito');

      final sale = Sale(
        clientId: _selectedClient?.id ?? 0,
        total: cartProvider.subtotal,
        discount: 0,
        finalAmount: total,
        paymentMethod: finalMethod,
        saleDate: DateTime.now(),
        businessRuc: businessRuc,
        status: hasCredit ? 'pendiente' : 'completada',
        items: cartProvider.items
            .map(
              (item) => SaleItem(
                saleId: 0,
                productId: item.product.id!,
                productName: item.product.name,
                quantity: item.quantity,
                unitPrice: item.product.salePrice,
                totalPrice: item.totalPrice,
              ),
            )
            .toList(),
        payments: _payments,
      );

      final saleId = await databaseService.createSale(sale);

      for (var item in cartProvider.items) {
        final saleItem = SaleItem(
          saleId: saleId,
          productId: item.product.id!,
          productName: item.product.name,
          quantity: item.quantity,
          unitPrice: item.product.salePrice,
          totalPrice: item.totalPrice,
        );
        await databaseService.createSaleItem(saleItem);

        final updatedProduct = item.product.copyWith(
          quantity: item.product.quantity - item.quantity,
        );
        await databaseService.updateProduct(updatedProduct);

        // ← NUEVO: Registrar movimiento en Kardex
        final kardexMovement = KardexMovement(
          productId: item.product.id!,
          productName: item.product.name,
          date: DateTime.now(),
          type: 'salida',
          description: 'Venta #${saleId}',
          quantity: item.quantity,
          previousStock: item.product.quantity,
          newStock: updatedProduct.quantity,
          businessRuc: businessRuc,
          userId: userId,
        );
        await databaseService.createKardexMovement(kardexMovement);
      }

      cartProvider.clear();

      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
        _showSuccessDialog(total);
      }
    } catch (e) {
      _showErrorDialog('Error al procesar la venta: $e');
    }
  }

  // Diálogo de error (SIN CAMBIOS)
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  // Diálogo de éxito (SIN CAMBIOS)
  void _showSuccessDialog(double total) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Venta completada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            Text('Total: \$${total.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            const Text('Pagos recibidos:'),
            ..._payments.map((p) => Text('• ${p.method.capitalize()}: \$${p.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12))),
            if (_totalPaid > total)
              Text('Vuelto: \$${(_totalPaid - total).toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Nueva venta'),
          ),
        ],
      ),
    );
  }
}

// Extensión para capitalizar strings (SIN CAMBIOS)
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
