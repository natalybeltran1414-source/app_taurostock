import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/client.dart';
import '../providers/client_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_widgets.dart' as custom; // ← MEJORADO: con alias

class ClientFormScreen extends StatefulWidget {
  final Client? client;

  const ClientFormScreen({Key? key, this.client}) : super(key: key);

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _identificationController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.name ?? '');
    _phoneController =
        TextEditingController(text: widget.client?.phone ?? '');
    _emailController =
        TextEditingController(text: widget.client?.email ?? '');
    _addressController =
        TextEditingController(text: widget.client?.address ?? '');
    _identificationController = 
        TextEditingController(text: widget.client?.identification ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _identificationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.CustomAppBar( // ← MEJORADO: usar CustomAppBar con alias
        title: widget.client == null ? 'Nuevo Cliente' : 'Editar Cliente',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ← MEJORADO: Campos con CustomTextField y alias
            custom.CustomTextField(
              label: 'Nombre del Cliente *',
              hint: 'Ej: Juan Pérez',
              controller: _nameController,
              prefixIcon: Icons.person_outlined,
            ),
            
            custom.CustomTextField(
              label: 'Cédula / RUC',
              hint: '1234567890',
              controller: _identificationController,
              inputType: TextInputType.number,
              prefixIcon: Icons.badge_outlined,
            ),
            
            custom.CustomTextField(
              label: 'Teléfono',
              hint: '+1 234 567 8900',
              controller: _phoneController,
              inputType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            
            custom.CustomTextField(
              label: 'Email',
              hint: 'correo@ejemplo.com',
              controller: _emailController,
              inputType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            
            custom.CustomTextField(
              label: 'Dirección',
              hint: 'Calle 123, Apto 456',
              controller: _addressController,
              prefixIcon: Icons.location_on_outlined,
            ),
            
            const SizedBox(height: 32),
            
            // ← MEJORADO: Botón con CustomButton y alias
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : custom.CustomButton(
                    label: widget.client == null ? 'Crear Cliente' : 'Actualizar',
                    onPressed: () async {
                      // Validación
                      if (_nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('El nombre del cliente es requerido'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      
                      // Validar email
                      if (_emailController.text.isNotEmpty && 
                          !_emailController.text.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ingresa un email válido'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      
                      setState(() => _isLoading = true);
                      
                      try {
                        final businessRuc = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessRuc ?? '0000000000';
                        final client = Client(
                          id: widget.client?.id,
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          email: _emailController.text.trim(),
                          address: _addressController.text.trim(),
                          identification: _identificationController.text.trim(),
                          totalPurchases: widget.client?.totalPurchases ?? 0,
                          accountBalance: widget.client?.accountBalance ?? 0,
                          createdAt: widget.client?.createdAt ?? DateTime.now(),
                          businessRuc: businessRuc,
                        );
                        
                        final clientProvider =
                            Provider.of<ClientProvider>(context, listen: false);
                        
                        bool success;
                        if (widget.client == null) {
                          success = await clientProvider.addClient(client);
                        } else {
                          success = await clientProvider.updateClient(client);
                        }
                        
                        if (success && mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                widget.client == null
                                    ? '✅ Cliente creado exitosamente'
                                    : '✅ Cliente actualizado exitosamente',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                clientProvider.errorMessage.isNotEmpty
                                    ? clientProvider.errorMessage
                                    : 'Error al guardar el cliente',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error inesperado: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
