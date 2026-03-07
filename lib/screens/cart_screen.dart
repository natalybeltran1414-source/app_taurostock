import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_widgets.dart' as custom; // ← MEJORADO: con alias
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.CustomAppBar( // ← MEJORADO: usar CustomAppBar con alias
        title: 'Carrito de Compras',
        showBackButton: true,
        actions: [
          // Botón para vaciar carrito
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              if (cart.isEmpty) return const SizedBox.shrink();
              
              return IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.white),
                onPressed: () => _showClearCartDialog(cart),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return const custom.EmptyState( // ← MEJORADO: usar EmptyState con alias
              message: 'Carrito vacío',
              icon: Icons.shopping_cart_outlined,
            );
          }

          return Column(
            children: [
              // Lista de productos
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _buildCartItemCard(item, cart);
                  },
                ),
              ),
              
              // Resumen y totales
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Subtotal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '\$${cart.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Descuento
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Descuento:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '\$${cart.discount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: cart.discount > 0 ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    
                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${cart.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: custom.secondaryPurple, // ← MEJORADO: usar color institucional
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Botón continuar
                    custom.CustomButton( // ← MEJORADO: usar CustomButton con alias
                      label: 'CONTINUAR AL PAGO',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CheckoutScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ← MEJORADO: Tarjeta de item en carrito usando ListItemCard
  Widget _buildCartItemCard(CartItem item, CartProvider cart) {
    return custom.ListItemCard(
      title: item.product.name,
      subtitle: '\$${item.product.salePrice.toStringAsFixed(2)} c/u',
      amount: '\$${item.totalPrice.toStringAsFixed(2)}',
      icon: Icons.inventory_2_outlined,
      color: custom.secondaryPurple,
      status: '${item.quantity} unidad(es)',
      onTap: null, // No necesario
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Controles de cantidad
          _buildQuantityControl(item, cart),
          const SizedBox(width: 8),
          
          // Botón eliminar
          GestureDetector(
            onTap: () => _showRemoveItemDialog(item, cart),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close,
                size: 18,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ← NUEVO: Control de cantidad separado para mejor organización
  Widget _buildQuantityControl(CartItem item, CartProvider cart) {
    return Row(
      children: [
        // Botón disminuir
        GestureDetector(
          onTap: () {
            if (item.quantity > 1) {
              cart.updateQuantity(
                item.product.id!,
                item.quantity - 1,
              );
            } else {
              _showRemoveItemDialog(item, cart);
            }
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.remove,
              size: 18,
              color: Colors.black54,
            ),
          ),
        ),
        
        // Cantidad
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text(
            '${item.quantity}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Botón aumentar
        GestureDetector(
          onTap: () {
            if (item.quantity < item.product.quantity) {
              cart.updateQuantity(
                item.product.id!,
                item.quantity + 1,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Stock máximo: ${item.product.quantity}'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: custom.secondaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.add,
              size: 18,
              color: custom.secondaryPurple,
            ),
          ),
        ),
      ],
    );
  }

  // Diálogo para eliminar item
  void _showRemoveItemDialog(CartItem item, CartProvider cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar ${item.product.name} del carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              cart.removeItem(item.product.id!);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Diálogo para vaciar carrito
  void _showClearCartDialog(CartProvider cart) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Eliminar todos los productos del carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
  }
}