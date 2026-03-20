import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/company_settings.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_widgets.dart' as custom;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _taxIdController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _currencyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _taxIdController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _currencyController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final businessRuc = authProvider.currentUser?.businessRuc ?? '0000000000';
      final provider = Provider.of<SettingsProvider>(context, listen: false);
      await provider.loadSettings(businessRuc);
      if (provider.settings != null) {
        final s = provider.settings!;
        _nameController.text = s.companyName;
        _taxIdController.text = s.taxId;
        _addressController.text = s.address;
        _phoneController.text = s.phone;
        _emailController.text = s.email;
        _currencyController.text = s.currencySymbol;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const custom.CustomAppBar(
        title: 'Ajustes del Sistema',
        showBackButton: true,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const custom.CustomLoadingIndicator(message: 'Cargando ajustes...');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PERFIL DEL NEGOCIO ---
                  custom.SectionHeader(title: 'Perfil del Negocio'),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          custom.CustomTextField(
                            label: 'Nombre de la Empresa',
                            controller: _nameController,
                            prefixIcon: Icons.business,
                          ),
                          custom.CustomTextField(
                            label: 'Identificación Tributaria (RUC/NIT)',
                            controller: _taxIdController,
                            prefixIcon: Icons.badge_outlined,
                          ),
                          custom.CustomTextField(
                            label: 'Dirección',
                            controller: _addressController,
                            prefixIcon: Icons.location_on_outlined,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: custom.CustomTextField(
                                  label: 'Teléfono',
                                  controller: _phoneController,
                                  prefixIcon: Icons.phone_outlined,
                                  inputType: TextInputType.phone,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: custom.CustomTextField(
                                  label: 'Email de Contacto',
                                  controller: _emailController,
                                  prefixIcon: Icons.email_outlined,
                                  inputType: TextInputType.emailAddress,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- PREFERENCIAS DEL SISTEMA ---
                  custom.SectionHeader(title: 'Preferencias'),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          custom.CustomTextField(
                            label: 'Símbolo de Moneda',
                            controller: _currencyController,
                            hint: '\$, €, S/, etc.',
                            prefixIcon: Icons.attach_money,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- INFORMACIÓN TÉCNICA ---
                  custom.SectionHeader(title: 'Información del Sistema'),
                  const SizedBox(height: 12),
                  _buildInfoTile('Versión del Software', '1.2.0 (Premium)'),
                  _buildInfoTile('Base de Datos', 'SQLite v3.x'),
                  _buildInfoTile('Última Sincronización', 'Local - Siempre conectado'),

                  const SizedBox(height: 40),

                  // --- BOTÓN GUARDAR ---
                  custom.CustomButton(
                    label: 'GUARDAR AJUSTES',
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final businessRuc = authProvider.currentUser?.businessRuc ?? '0000000000';

                        final newSettings = CompanySettings(
                          id: provider.settings?.id,
                          companyName: _nameController.text,
                          taxId: _taxIdController.text,
                          address: _addressController.text,
                          phone: _phoneController.text,
                          email: _emailController.text,
                          currencySymbol: _currencyController.text,
                          logoPath: provider.settings?.logoPath,
                          businessRuc: businessRuc,
                        );

                        final success = await provider.updateSettings(newSettings, businessRuc);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Ajustes guardados correctamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
