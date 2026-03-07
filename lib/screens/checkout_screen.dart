import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../models/sale.dart';
import '../providers/cart_provider.dart';
import '../providers/client_provider.dart';
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
  String _paymentMethod = 'efectivo';
  String _paymentStatus = 'pagado'; // 'pagado' o 'pendiente'
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

  // Calcular vuelto
  void _calculateChange(String value) {
    double received = double.tryParse(value) ?? 0;
    double total = Provider.of<CartProvider>(context, listen: false).total;
    setState(() {
      _cashReceived = received;
      _change = received - total;
      _changeController.text = _change >= 0 
          ? '\$${_change.toStringAsFixed(2)}' 
          : 'Faltan \$${(-_change).toStringAsFixed(2)}';
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
            
            // Métodos de pago (MEJORADO con StatusBadge)
            _buildPaymentMethods(),
            const SizedBox(height: 20),
            
            // Estado de pago (SOLO para crédito)
            if (_paymentMethod == 'credito') _buildPaymentStatus(),
            
            // Calculadora de vuelto (SOLO para efectivo)
            if (_paymentMethod == 'efectivo') _buildChangeCalculator(),
            
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
                  color: custom.secondaryPurple,
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
                custom.secondaryPurple.withOpacity(0.1),
                custom.secondaryPurple.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: custom.secondaryPurple.withOpacity(0.2)),
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
                      color: custom.secondaryPurple,
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
                  custom.secondaryPurple.withOpacity(0.1),
                  custom.secondaryPurple.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: custom.secondaryPurple),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: custom.secondaryPurple,
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
                            : custom.secondaryPurple.withOpacity(0.1),
                        child: Text(
                          client.name[0].toUpperCase(),
                          style: TextStyle(
                            color: hasDebt ? Colors.red : custom.secondaryPurple,
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

  // ← MEJORADO: Métodos de pago con StatusBadge
  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Método de pago',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPaymentChip('Efectivo', Icons.money, 'efectivo'),
            _buildPaymentChip('Tarjeta', Icons.credit_card, 'tarjeta'),
            _buildPaymentChip('Transferencia', Icons.swap_horiz, 'transferencia'),
            _buildPaymentChip('Crédito', Icons.receipt, 'credito'),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentChip(String label, IconData icon, String value) {
    final isSelected = _paymentMethod == value;
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 18, color: isSelected ? custom.secondaryPurple : Colors.grey),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _paymentMethod = value);
      },
      backgroundColor: Colors.grey[100],
      selectedColor: custom.secondaryPurple.withOpacity(0.2),
      checkmarkColor: custom.secondaryPurple,
      labelStyle: TextStyle(
        color: isSelected ? custom.secondaryPurple : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // ← MEJORADO: Estado de pago con StatusBadge
  Widget _buildPaymentStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado del pago',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Pagado'),
                selected: _paymentStatus == 'pagado',
                onSelected: (_) => setState(() => _paymentStatus = 'pagado'),
                selectedColor: Colors.green.withOpacity(0.2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('Pendiente'),
                selected: _paymentStatus == 'pendiente',
                onSelected: (_) => setState(() => _paymentStatus = 'pendiente'),
                selectedColor: Colors.orange.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ← MEJORADO: Calculadora de vuelto
  Widget _buildChangeCalculator() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final total = cartProvider.total;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cálculo de vuelto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cashReceivedController,
                    keyboardType: TextInputType.number,
                    onChanged: _calculateChange,
                    decoration: InputDecoration(
                      labelText: 'Recibido',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: _change >= 0 ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Vuelto:'),
                        Text(
                          _change >= 0 
                              ? '\$${_change.toStringAsFixed(2)}'
                              : 'Faltan \$${(-_change).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _change >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_cashReceived > 0 && _cashReceived < total)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '❌ Monto insuficiente: faltan \$${(total - _cashReceived).toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  // Diálogo de confirmación (SIN CAMBIOS)
  Future<void> _showConfirmDialog(CartProvider cartProvider) async {
    final total = cartProvider.total;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar venta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: \$${total.toStringAsFixed(2)}'),
            Text('Método de pago: ${_paymentMethod.capitalize()}'),
            if (_selectedClient != null) Text('Cliente: ${_selectedClient!.name}'),
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

    if (_paymentMethod == 'credito' && _selectedClient == null) {
      _showErrorDialog('Selecciona un cliente para ventas a crédito');
      return;
    }

    if (_paymentMethod == 'efectivo' && _cashReceived < total) {
      _showErrorDialog('El monto recibido es insuficiente');
      return;
    }

    try {
      final databaseService = DatabaseService();

      final sale = Sale(
        clientId: _selectedClient?.id ?? 0,
        total: cartProvider.subtotal,
        discount: 0,
        finalAmount: total,
        paymentMethod: _paymentMethod,
        saleDate: DateTime.now(),
        status: _paymentStatus == 'pendiente' ? 'pendiente' : 'completada',
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
            Text('Método: ${_paymentMethod.capitalize()}'),
            if (_change > 0 && _paymentMethod == 'efectivo') 
              Text('Vuelto: \$${_change.toStringAsFixed(2)}'),
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