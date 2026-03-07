import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../providers/client_provider.dart';
import '../widgets/custom_widgets.dart' as custom; // ← MEJORADO: con alias
import 'client_form_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({Key? key}) : super(key: key);

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientProvider>(context, listen: false).loadClients();
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
        title: 'Clientes',
        showBackButton: true,
        actions: [
          // ← MEJORADO: Botón de agregar en AppBar
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ClientFormScreen(),
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
              hintText: 'Buscar cliente...',
            ),
          ),
          
          Expanded(
            child: Consumer<ClientProvider>(
              builder: (context, clientProvider, _) {
                final clients = clientProvider.searchClients(
                  _searchController.text,
                );

                if (clientProvider.isLoading) {
                  return const custom.CustomLoadingIndicator( // ← MEJORADO
                    message: 'Cargando clientes...',
                  );
                }

                if (clients.isEmpty) {
                  return custom.EmptyState( // ← MEJORADO
                    message: 'No hay clientes registrados',
                    icon: Icons.people_outline,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    return _buildClientCard(context, client);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ← MEJORADO: Tarjeta de cliente usando ListItemCard
  Widget _buildClientCard(BuildContext context, Client client) {
    final hasDebt = client.hasDebt;
    final debtAmount = client.debt;
    
    // Construir subtítulo
    String subtitle = client.email.isNotEmpty ? client.email : client.phone;
    subtitle += '\nCompras: \$${client.totalPurchases.toStringAsFixed(2)}';
    
    return custom.ListItemCard(
      title: client.name,
      subtitle: subtitle,
      amount: hasDebt ? '\$${debtAmount.toStringAsFixed(2)}' : '',
      icon: Icons.person,
      color: hasDebt ? Colors.red : custom.secondaryPurple,
      status: hasDebt ? 'Debe \$${debtAmount.toStringAsFixed(2)}' : null,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClientFormScreen(client: client),
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
                builder: (context) => ClientFormScreen(client: client),
              ),
            );
          } else if (value == 'delete') {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Eliminar Cliente'),
                  content: Text('¿Eliminar a "${client.name}" permanentemente?'),
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
              final success = await Provider.of<ClientProvider>(
                context, 
                listen: false
              ).deleteClient(client.id!);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${client.name} eliminado'),
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