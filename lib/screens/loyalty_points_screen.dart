import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../providers/client_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_widgets.dart' as custom;

class LoyaltyPointsScreen extends StatefulWidget {
  const LoyaltyPointsScreen({Key? key}) : super(key: key);

  @override
  State<LoyaltyPointsScreen> createState() => _LoyaltyPointsScreenState();
}

class _LoyaltyPointsScreenState extends State<LoyaltyPointsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessRuc = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessRuc ?? '0000000000';
      Provider.of<ClientProvider>(context, listen: false).loadClients(businessRuc);
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
      appBar: const custom.CustomAppBar(
        title: 'Sistema de Puntos',
        showBackButton: true,
      ),
      body: Consumer<ClientProvider>(
        builder: (context, clientProvider, _) {
          final clients = clientProvider.searchClients(_searchQuery)
              .where((c) => c.isActive).toList();

          return Column(
            children: [
              // --- BUSCADOR ---
              Padding(
                padding: const EdgeInsets.all(16),
                child: custom.CustomTextField(
                  label: '',
                  hint: 'Buscar cliente por nombre o teléfono...',
                  controller: _searchController,
                  prefixIcon: Icons.search,
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              // --- RESUMEN RÁPIDO ---
              _buildSummaryHeader(clients),

              const SizedBox(height: 8),

              // --- LISTA DE CLIENTES CON PUNTOS ---
              Expanded(
                child: clients.isEmpty
                    ? const custom.EmptyState(
                        message: 'No se encontraron clientes activos',
                        icon: Icons.person_off_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: clients.length,
                        itemBuilder: (context, index) {
                          final client = clients[index];
                          return _buildClientPointsCard(context, client, clientProvider);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(List<Client> clients) {
    int totalPoints = clients.fold(0, (sum, c) => sum + c.loyaltyPoints);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [custom.primaryLilac, custom.primaryLilac.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: custom.primaryLilac.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Puntos Activos',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                'Fidelización de Clientes',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              totalPoints.toString(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientPointsCard(BuildContext context, Client client, ClientProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: custom.ListItemCard(
        title: client.name,
        subtitle: client.phone.isEmpty ? 'Sin teléfono' : client.phone,
        amount: '${client.loyaltyPoints} pts',
        icon: Icons.stars,
        color: client.loyaltyPoints > 0 ? Colors.amber : Colors.grey,
        status: client.loyaltyPoints > 100 ? 'VIP' : 'ESTÁNDAR',
        onTap: () => _showPointsActionDialog(context, client, provider),
      ),
    );
  }

  void _showPointsActionDialog(BuildContext context, Client client, ClientProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.stars, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(child: Text(client.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Puntos actuales: ${client.loyaltyPoints}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            const Text('¿Deseas canjear puntos para este cliente?', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              'El canje de puntos se registra como una nota en el historial del cliente.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          if (client.loyaltyPoints >= 50) 
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              onPressed: () => _confirmRedeem(context, client, 50, provider),
              child: const Text('CANJEAR 50 PTS'),
            ),
          if (client.loyaltyPoints >= 100)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: custom.primaryLilac, foregroundColor: Colors.white),
              onPressed: () => _confirmRedeem(context, client, 100, provider),
              child: const Text('CANJEAR 100 PTS'),
            ),
        ],
      ),
    );
  }

  void _confirmRedeem(BuildContext context, Client client, int points, ClientProvider provider) async {
    Navigator.pop(context); // Cerrar primer diálogo
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Canje'),
        content: Text('¿Confirmas el canje de $points puntos para ${client.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('NO')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('SÍ, CANJEAR')),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.redeemPoints(client, points);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Canje exitoso: -$points puntos'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
