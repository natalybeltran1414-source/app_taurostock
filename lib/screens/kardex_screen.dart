import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/kardex.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_widgets.dart' as custom;

class KardexScreen extends StatefulWidget {
  final Product product;

  const KardexScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<KardexScreen> createState() => _KardexScreenState();
}

class _KardexScreenState extends State<KardexScreen> {
  late Future<List<KardexMovement>> _kardexFuture;
  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    _refreshKardex();
  }

  void _refreshKardex() {
    final businessRuc = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessRuc ?? '0000000000';
    setState(() {
      _kardexFuture = _db.getKardexByProduct(widget.product.id!, businessRuc);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.CustomAppBar(
        title: 'Kardex: ${widget.product.name}',
        showBackButton: true,
      ),
      body: Column(
        children: [
          _buildProductHeader(),
          const custom.SectionHeader(title: 'Historial de Movimientos'),
          Expanded(
            child: FutureBuilder<List<KardexMovement>>(
              future: _kardexFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const custom.CustomLoadingIndicator();
                }
                if (snapshot.hasError) {
                  return custom.EmptyState(
                    message: 'Error al cargar el Kardex',
                    icon: Icons.error_outline,
                  );
                }
                final movements = snapshot.data ?? [];
                if (movements.isEmpty) {
                  return custom.EmptyState(
                    message: 'No hay movimientos registrados',
                    icon: Icons.history,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: movements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final move = movements[index];
                    return _buildKardexItem(move);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: custom.primaryLilac.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock Actual',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.product.quantity} unidades',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'SKU/Código',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                widget.product.barcode ?? 'N/A',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKardexItem(KardexMovement move) {
    final isEntry = move.type == 'entrada';
    final isExit = move.type == 'salida';
    
    Color typeColor = Colors.blue;
    IconData typeIcon = Icons.swap_horiz;
    
    if (isEntry) {
      typeColor = Colors.green;
      typeIcon = Icons.add_circle_outline;
    } else if (isExit) {
      typeColor = Colors.red;
      typeIcon = Icons.remove_circle_outline;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        move.description,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(move.date),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isEntry ? '+' : isExit ? '-' : ''}${move.quantity}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: typeColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStockInfo('Anterior', move.previousStock),
                const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                _buildStockInfo('Nuevo', move.newStock),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockInfo(String label, int value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}
