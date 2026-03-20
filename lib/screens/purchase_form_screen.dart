import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../models/kardex.dart';
import '../models/provider.dart';
import '../providers/purchase_cart_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/provider_model_provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../widgets/custom_widgets.dart' as custom; // ← MEJORADO: con alias

class PurchaseFormScreen extends StatefulWidget {
  const PurchaseFormScreen({Key? key}) : super(key: key);

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  late TextEditingController _searchController;
  String _paymentStatus = 'pendiente';
  ProviderModel? _selectedProvider;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessRuc = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessRuc ?? '0000000000';
      Provider.of<ProviderModelProvider>(context, listen: false).loadProviders(businessRuc);
      Provider.of<PurchaseProvider>(context, listen: false).loadPurchases(businessRuc);
      Provider.of<ProductProvider>(context, listen: false).loadProducts(businessRuc);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchaseCart = Provider.of<PurchaseCartProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final providerProvider = Provider.of<ProviderModelProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: custom.CustomAppBar( // ← MEJORADO: usar CustomAppBar con alias
        title: 'Registrar Compra',
        showBackButton: true,
      ),
      body: isMobile
          ? _buildMobileLayout(context, purchaseCart, productProvider, providerProvider)
          : _buildDesktopLayout(context, purchaseCart, productProvider, providerProvider),
    );
  }

  // Layout para móvil (vertical)
  Widget _buildMobileLayout(
    BuildContext context,
    PurchaseCartProvider purchaseCart,
    ProductProvider productProvider,
    ProviderModelProvider providerProvider,
  ) {
    return Column(
      children: [
        // ← MEJORADO: Selector de proveedor con estilo
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<ProviderModel>(
            decoration: InputDecoration(
              labelText: 'Proveedor',
              prefixIcon: const Icon(Icons.local_shipping, color: custom.primaryLilac),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: providerProvider.providers
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedProvider = value;
              });
            },
            value: _selectedProvider,
          ),
        ),
        // ← MEJORADO: Búsqueda con SearchBar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: custom.SearchBar(
            controller: _searchController,
            onChanged: (value) => setState(() {}),
            hintText: 'Buscar producto...',
          ),
        ),
        const SizedBox(height: 12),
        // Grid de productos
        Expanded(
          child: productProvider.isLoading
              ? const custom.CustomLoadingIndicator(message: 'Cargando productos...')
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 4 / 3,
                  ),
                  itemCount: productProvider
                      .searchProducts(_searchController.text)
                      .length,
                  itemBuilder: (context, index) {
                    final product = productProvider
                        .searchProducts(_searchController.text)[index];
                    return _buildProductCard(context, product);
                  },
                ),
        ),
        // Resumen y botón
        Container(
          color: Colors.grey[50],
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ← MEJORADO: Totales con estilo
              _buildTotalRow('Subtotal:', purchaseCart.subtotal),
              const SizedBox(height: 8),
              _buildTotalRow('Descuento:', purchaseCart.discount, isDiscount: true),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    '\$${purchaseCart.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: custom.primaryLilac,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ← MEJORADO: Estado de pago con StatusBadge
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Estado de pago',
                  prefixIcon: Icon(
                    _paymentStatus == 'pendiente' ? Icons.pending : Icons.check_circle,
                    color: _paymentStatus == 'pendiente' ? Colors.orange : Colors.green,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                  DropdownMenuItem(value: 'pagado', child: Text('Pagado')),
                ],
                onChanged: (v) {
                  setState(() {
                    _paymentStatus = v!;
                  });
                },
                value: _paymentStatus,
              ),
              const SizedBox(height: 16),
              custom.CustomButton(
                label: 'Registrar Compra',
                onPressed: () => _savePurchase(context, purchaseCart),
              ),
            ],
          ),
        ),
        // Carrito
        if (purchaseCart.items.isNotEmpty)
          Container(
            height: 200,
            color: Colors.white,
            child: Column(
              children: [
                custom.SectionHeader( // ← MEJORADO
                  title: 'Carrito',
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: purchaseCart.items.length,
                    itemBuilder: (context, index) {
                      final item = purchaseCart.items[index];
                      return custom.ListItemCard(
                        title: item.product.name,
                        subtitle: 'Cant: ${item.quantity} x \$${item.product.costPrice.toStringAsFixed(2)}',
                        amount: '\$${item.totalPrice.toStringAsFixed(2)}',
                        icon: Icons.shopping_cart,
                        color: custom.primaryLilac,
                        onTap: null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            purchaseCart.updateQuantity(item.product.id!, 0);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Layout para desktop (horizontal)
  Widget _buildDesktopLayout(
    BuildContext context,
    PurchaseCartProvider purchaseCart,
    ProductProvider productProvider,
    ProviderModelProvider providerProvider,
  ) {
    return Row(
      children: [
        // Panel izquierdo - productos
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: custom.SearchBar( // ← MEJORADO
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  hintText: 'Buscar producto...',
                ),
              ),
              Expanded(
                child: productProvider.isLoading
                    ? const custom.CustomLoadingIndicator(message: 'Cargando productos...')
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 4 / 3,
                        ),
                        itemCount: productProvider
                            .searchProducts(_searchController.text)
                            .length,
                        itemBuilder: (context, index) {
                          final product = productProvider
                              .searchProducts(_searchController.text)[index];
                          return _buildProductCard(context, product);
                        },
                      ),
              ),
            ],
          ),
        ),
        // Panel derecho - carrito y opciones
        Container(
          width: 380,
          color: Colors.grey[50],
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<ProviderModel>(
                  decoration: InputDecoration(
                    labelText: 'Proveedor',
                    prefixIcon: const Icon(Icons.local_shipping, color: custom.primaryLilac),
                  ),
                  items: providerProvider.providers
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvider = value;
                    });
                  },
                  value: _selectedProvider,
                ),
              ),
              Expanded(
                child: purchaseCart.isEmpty
                    ? custom.EmptyState(
                        message: 'Agrega productos',
                        icon: Icons.shopping_cart_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: purchaseCart.items.length,
                        itemBuilder: (context, index) {
                          final item = purchaseCart.items[index];
                          return custom.ListItemCard(
                            title: item.product.name,
                            subtitle: 'Cant: ${item.quantity} • Unit: \$${item.product.costPrice.toStringAsFixed(2)}',
                            amount: '\$${item.totalPrice.toStringAsFixed(2)}',
                            icon: Icons.shopping_cart,
                            color: custom.primaryLilac,
                            onTap: null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    purchaseCart.updateQuantity(
                                        item.product.id!, item.quantity - 1);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    purchaseCart.updateQuantity(
                                        item.product.id!, item.quantity + 1);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTotalRow('Subtotal:', purchaseCart.subtotal),
                    const SizedBox(height: 4),
                    _buildTotalRow('Descuento:', purchaseCart.discount, isDiscount: true),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '\$${purchaseCart.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: custom.primaryLilac,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Estado de pago',
                        prefixIcon: Icon(
                          _paymentStatus == 'pendiente' ? Icons.pending : Icons.check_circle,
                          color: _paymentStatus == 'pendiente' ? Colors.orange : Colors.green,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                        DropdownMenuItem(value: 'pagado', child: Text('Pagado')),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _paymentStatus = v!;
                        });
                      },
                      value: _paymentStatus,
                    ),
                    const SizedBox(height: 16),
                    custom.CustomButton(
                      label: 'Registrar Compra',
                      onPressed: () => _savePurchase(context, purchaseCart),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ← NUEVO: Widget para fila de totales
  Widget _buildTotalRow(String label, double amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          '${isDiscount ? '-' : ''}\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDiscount && amount > 0 ? Colors.green : null,
          ),
        ),
      ],
    );
  }

  // ← MEJORADO: Tarjeta de producto
  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        _showQuantityDialog(context, product);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Costo: \$${product.costPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: custom.primaryLilac,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.inventory, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 2),
                    Text(
                      'Stock: ${product.quantity}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePurchase(
    BuildContext context,
    PurchaseCartProvider purchaseCart,
  ) async {
    if (_selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un proveedor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (purchaseCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un producto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final businessRuc = authProvider.currentUser?.businessRuc ?? '0000000000';
    final userId = authProvider.currentUser?.id;

    final purchase = Purchase(
      providerId: _selectedProvider!.id!,
      total: purchaseCart.subtotal,
      discount: purchaseCart.discount,
      finalAmount: purchaseCart.total,
      paymentStatus: _paymentStatus,
      purchaseDate: DateTime.now(),
      items: purchaseCart.items
          .map((i) => PurchaseItem(
                purchaseId: 0,
                productId: i.product.id!,
                productName: i.product.name,
                quantity: i.quantity,
                unitPrice: i.product.costPrice,
                totalPrice: i.totalPrice,
              ))
          .toList(),
      businessRuc: businessRuc,
    );

    final db = DatabaseService();
    final purchaseId = await db.createPurchase(purchase);

    for (var item in purchaseCart.items) {
      final itemRecord = PurchaseItem(
        purchaseId: purchaseId,
        productId: item.product.id!,
        productName: item.product.name,
        quantity: item.quantity,
        unitPrice: item.product.costPrice,
        totalPrice: item.totalPrice,
      );
      await db.createPurchaseItem(itemRecord);

      final updatedProduct = item.product.copyWith(
          quantity: item.product.quantity + item.quantity);
      await db.updateProduct(updatedProduct);

      // ← NUEVO: Registrar movimiento en Kardex
      final kardexMovement = KardexMovement(
        productId: item.product.id!,
        productName: item.product.name,
        date: DateTime.now(),
        type: 'entrada',
        description: 'Compra #${purchaseId}',
        quantity: item.quantity,
        previousStock: item.product.quantity,
        newStock: updatedProduct.quantity,
        businessRuc: businessRuc,
        userId: userId,
      );
      await db.createKardexMovement(kardexMovement);
    }

    purchaseCart.clear();
    Provider.of<PurchaseProvider>(context, listen: false).loadPurchases(businessRuc);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Compra registrada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showQuantityDialog(BuildContext context, Product product) {
    final TextEditingController qtyController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cantidad para ${product.name}'),
          content: TextField(
            controller: qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Ingrese cantidad',
              prefixIcon: Icon(Icons.add_shopping_cart),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(qtyController.text) ?? 0;
                if (qty > 0) {
                  Provider.of<PurchaseCartProvider>(context, listen: false)
                      .addItem(product, qty);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: custom.primaryLilac,
              ),
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }
}
