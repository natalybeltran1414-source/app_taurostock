import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_widgets.dart' as custom; // ← MEJORADO: con alias

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _fullNameController;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _selectedRole = 'operador';

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _fullNameController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.CustomAppBar( // ← MEJORADO: usar CustomAppBar con alias
        title: 'Registro',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ← MEJORADO: Campos con CustomTextField
            custom.CustomTextField(
              label: 'Nombre Completo',
              hint: 'Tu nombre',
              controller: _fullNameController,
              prefixIcon: Icons.person_outlined,
            ),
            custom.CustomTextField(
              label: 'Email',
              hint: 'correo@ejemplo.com',
              controller: _emailController,
              inputType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            custom.CustomTextField(
              label: 'Contraseña',
              hint: '••••••••',
              controller: _passwordController,
              obscureText: _obscurePassword,
              prefixIcon: Icons.lock_outlined,
            ),
            custom.CustomTextField(
              label: 'Confirmar Contraseña',
              hint: '••••••••',
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              prefixIcon: Icons.lock_outlined,
            ),
            const SizedBox(height: 12),
            
            // ← MEJORADO: Selector de rol con mejor diseño
            const Text(
              'Rol de Usuario',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: custom.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _selectedRole,
                isExpanded: true,
                underline: const SizedBox(),
                icon: Icon(Icons.arrow_drop_down, color: custom.secondaryPurple),
                items: const [
                  DropdownMenuItem(
                    value: 'operador',
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Operador'),
                        ],
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings, size: 18),
                          SizedBox(width: 8),
                          Text('Administrador'),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value ?? 'operador';
                  });
                },
              ),
            ),
            const SizedBox(height: 32),
            
            // ← MEJORADO: Botón de registro con manejo de errores
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return Column(
                  children: [
                    if (authProvider.errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[800], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                authProvider.errorMessage,
                                style: TextStyle(
                                  color: Colors.red[800],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    custom.CustomButton(
                      label: 'Crear Cuenta',
                      isLoading: authProvider.isLoading,
                      onPressed: () async {
                        // Validaciones
                        if (_fullNameController.text.isEmpty ||
                            _emailController.text.isEmpty ||
                            _passwordController.text.isEmpty ||
                            _confirmPasswordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Por favor completa todos los campos'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        if (_passwordController.text !=
                            _confirmPasswordController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Las contraseñas no coinciden'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (_passwordController.text.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('La contraseña debe tener al menos 6 caracteres'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final success = await authProvider.register(
                          _emailController.text.trim(),
                          _passwordController.text,
                          _fullNameController.text.trim(),
                          _selectedRole,
                        );

                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Cuenta creada exitosamente'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.of(context).pushReplacementNamed('/dashboard');
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}