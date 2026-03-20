
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_widgets.dart' as custom; // ← CORREGIDO: con alias
import 'product_form_screen.dart';
import 'kardex_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessRuc = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessRuc ?? '0000000000';
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
    return Scaffold(
      appBar: custom.CustomAppBar( // ← Usar alias
        title: 'Productos',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProductFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumen de inventario - Fila 1
          Consumer<ProductProvider>(
            builder: (context, productProvider, _) {
              final activeProducts = productProvider.products
                  .where((p) => p.isActive)
                  .toList();
              
              final totalCost = activeProducts.fold<double>(
                0,
                (sum, p) => sum + (p.costPrice * (p.quantity < 0 ? 0 : p.quantity)),
              );
              final totalSale = activeProducts.fold<double>(
                0,
                (sum, p) => sum + (p.salePrice * (p.quantity < 0 ? 0 : p.quantity)),
              );

              return Container(
                padding: const EdgeInsets.all(16),
                color: custom.primaryLilac.withOpacity(0.05),
                child: Row(
                  children: [
                    Expanded(
                      child: custom.SummaryCard( // ← Usar alias
                        title: 'Productos',
                        value: activeProducts.length.toString(),
                        icon: Icons.inventory_2_outlined,
                        color: custom.primaryLilac, // ← Usar alias
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: custom.SummaryCard(
                        title: 'Costo Total',
                        value: '\$${totalCost.toStringAsFixed(2)}',
                        icon: Icons.shopping_cart_outlined,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Resumen de inventario - Fila 2
          Consumer<ProductProvider>(
            builder: (context, productProvider, _) {
              final activeProducts = productProvider.products
                  .where((p) => p.isActive)
                  .toList();
              
              final totalSale = activeProducts.fold<double>(
                0,
                (sum, p) => sum + (p.salePrice * (p.quantity < 0 ? 0 : p.quantity)),
              );
              final totalCost = activeProducts.fold<double>(
                0,
                (sum, p) => sum + (p.costPrice * (p.quantity < 0 ? 0 : p.quantity)),
              );
              final totalProfit = totalSale - totalCost;

              return Container(
                padding: const EdgeInsets.all(16),
                color: custom.primaryLilac.withOpacity(0.05),
                child: Row(
                  children: [
                    Expanded(
                      child: custom.SummaryCard(
                        title: 'Precio Venta',
                        value: '\$${totalSale.toStringAsFixed(2)}',
                        icon: Icons.attach_money,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: custom.SummaryCard(
                        title: 'Ganancia',
                        value: '\$${totalProfit.toStringAsFixed(2)}',
                        icon: Icons.trending_up,
                        color: totalProfit >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 8),
          
          // ← CORREGIDO: SearchBar con alias
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: custom.SearchBar(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              hintText: 'Buscar producto...',
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Lista de productos
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, _) {
                final products = productProvider.searchProducts(
                  _searchController.text,
                ).where((p) => p.isActive).toList();

                if (productProvider.isLoading) {
                  return const custom.CustomLoadingIndicator( // ← Usar alias
                    message: 'Cargando productos...',
                  );
                }

                if (products.isEmpty) {
                  return const custom.EmptyState( // ← Usar alias
                    message: 'No hay productos registrados',
                    icon: Icons.shopping_bag_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(context, product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta de producto
  Widget _buildProductCard(BuildContext context, Product product) {
    final displayQuantity = product.quantity < 0 ? 0 : product.quantity;
    final isLowStock = displayQuantity <= product.minStock;
    final stockColor = isLowStock ? Colors.red : Colors.green;
    final stockStatus = isLowStock ? 'Stock bajo' : 'Stock OK';
    
    return custom.ListItemCard( // ← Usar alias
      title: product.name,
      subtitle: 'Código: ${product.barcode.isNotEmpty ? product.barcode : "Sin código"} • Stock: $displayQuantity',
      amount: '\$${product.salePrice.toStringAsFixed(2)}',
      icon: Icons.inventory_2_outlined,
      color: stockColor,
      status: stockStatus,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductFormScreen(product: product),
          ),
        );
      },
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        itemBuilder: (BuildContext context) {
          return [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'kardex',
              child: Row(
                children: [
                  Icon(Icons.history, size: 18, color: custom.primaryLilac),
                  SizedBox(width: 8),
                  Text('Ver Kardex'),
                ],
              ),
            ),
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
          if (value == 'edit') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProductFormScreen(product: product),
              ),
            );
          } else if (value == 'kardex') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => KardexScreen(product: product),
              ),
            );
          } else if (value == 'delete') {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Eliminar Producto'),
                  content: Text('¿Eliminar "${product.name}" permanentemente?'),
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
              final success = await Provider.of<ProductProvider>(
                context, 
                listen: false
              ).deleteProduct(product.id!, businessRuc);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} eliminado'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }
}
