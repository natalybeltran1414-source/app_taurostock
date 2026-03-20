import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/provider.dart';
import '../providers/provider_model_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_widgets.dart' as custom; // ← MEJORADO: con alias

class ProviderFormScreen extends StatefulWidget {
  final ProviderModel? provider;

  const ProviderFormScreen({Key? key, this.provider}) : super(key: key);

  @override
  State<ProviderFormScreen> createState() => _ProviderFormScreenState();
}

class _ProviderFormScreenState extends State<ProviderFormScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _taxIdController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.provider?.name ?? '');
    _phoneController =
        TextEditingController(text: widget.provider?.phone ?? '');
    _emailController =
        TextEditingController(text: widget.provider?.email ?? '');
    _addressController =
        TextEditingController(text: widget.provider?.address ?? '');
    _cityController =
        TextEditingController(text: widget.provider?.city ?? '');
    _taxIdController =
        TextEditingController(text: widget.provider?.taxId ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.CustomAppBar( // ← MEJORADO: usar CustomAppBar con alias
        title: widget.provider == null ? 'Nuevo Proveedor' : 'Editar Proveedor',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ← MEJORADO: Usar CustomTextField con alias
            custom.CustomTextField(
              label: 'Nombre *',
              controller: _nameController,
              prefixIcon: Icons.person_outline,
            ),
            custom.CustomTextField(
              label: 'Teléfono',
              controller: _phoneController,
              inputType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            custom.CustomTextField(
              label: 'Correo electrónico',
              controller: _emailController,
              inputType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            custom.CustomTextField(
              label: 'Dirección',
              controller: _addressController,
              prefixIcon: Icons.location_on_outlined,
            ),
            custom.CustomTextField(
              label: 'Ciudad',
              controller: _cityController,
              prefixIcon: Icons.location_city,
            ),
            custom.CustomTextField(
              label: 'RFC / NIT',
              controller: _taxIdController,
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: 32),
            
            // ← MEJORADO: Usar CustomButton con alias
            custom.CustomButton(
              label: widget.provider == null ? 'Crear Proveedor' : 'Actualizar',
              onPressed: () async {
                if (_nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El nombre es obligatorio'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final businessRuc = Provider.of<AuthProvider>(context, listen: false).currentUser?.businessRuc ?? '0000000000';

                final provider = ProviderModel(
                  id: widget.provider?.id,
                  name: _nameController.text.trim(),
                  phone: _phoneController.text.trim(),
                  email: _emailController.text.trim(),
                  address: _addressController.text.trim(),
                  city: _cityController.text.trim(),
                  taxId: _taxIdController.text.trim(),
                  createdAt: widget.provider?.createdAt ?? DateTime.now(),
                  businessRuc: businessRuc,
                );

                final provProvider =
                    Provider.of<ProviderModelProvider>(context, listen: false);

                bool success;
                if (widget.provider == null) {
                  success = await provProvider.addProvider(provider, businessRuc);
                } else {
                  success = await provProvider.updateProvider(provider, businessRuc);
                }

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        widget.provider == null
                            ? '✅ Proveedor creado exitosamente'
                            : '✅ Proveedor actualizado exitosamente',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
