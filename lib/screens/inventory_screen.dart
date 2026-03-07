import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/custom_widgets.dart' as custom; // ← MEJORADO: con alias
import 'cart_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
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
        title: 'Inventario',
        showBackButton: true,
      ),
      body: Column(
        children: [
          // ← MEJORADO: Barra de búsqueda con SearchBar
          Padding(
            padding: const EdgeInsets.all(16),
            child: custom.SearchBar(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              hintText: 'Buscar productos...',
            ),
          ),
          
          // Grid de productos
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, _) {
                final products = productProvider.searchProducts(_searchController.text);

                if (productProvider.isLoading) {
                  return const custom.CustomLoadingIndicator( // ← MEJORADO
                    message: 'Cargando productos...',
                  );
                }

                if (products.isEmpty) {
                  return custom.EmptyState( // ← MEJORADO
                    message: 'No hay productos',
                    icon: Icons.inventory_2_outlined,
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) =>
                      _buildProductCard(products[index]),
                );
              },
            ),
          ),
        ],
      ),
      // Botón flotante inferior para ir al carrito
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) return const SizedBox.shrink();
          
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ),
              );
            },
            backgroundColor: custom.secondaryPurple, // ← MEJORADO: usar color institucional
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            label: Text(
              'Ver Carrito (${cart.itemCount})',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ← MEJORADO: Tarjeta de producto con mejor diseño
  Widget _buildProductCard(Product product) {
    final isOutOfStock = product.quantity <= 0;
    final displayQuantity = product.quantity < 0 ? 0 : product.quantity; // ← CORREGIDO: evitar stock negativo
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono del producto
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: custom.secondaryPurple.withOpacity(0.1), // ← MEJORADO
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 40,
                        color: isOutOfStock 
                            ? Colors.grey[400] 
                            : custom.secondaryPurple, // ← MEJORADO
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Nombre
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Precio
                Text(
                  '\$${product.salePrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: custom.secondaryPurple, // ← MEJORADO
                  ),
                ),
                const SizedBox(height: 4),
                
                // Stock
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOutOfStock
                            ? Colors.red
                            : displayQuantity < 5
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stock: $displayQuantity', // ← CORREGIDO: usar displayQuantity
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                // ← MEJORADO: Badge de estado si es necesario
                if (isOutOfStock)
                  const SizedBox(height: 4),
                if (isOutOfStock)
                  custom.StatusBadge(
                    label: 'AGOTADO',
                    color: Colors.red,
                  ),
              ],
            ),
          ),
          
          // Botón de agregar (solo si hay stock)
          if (!isOutOfStock)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  Provider.of<CartProvider>(context, listen: false)
                      .addItem(product, 1);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ ${product.name} agregado'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: custom.secondaryPurple, // ← MEJORADO
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          
          
        ],
      ),
    );
  }
}