import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart' as custom; // ← MEJORADO: con alias
import '../services/database_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String token; // Podría ser un código de verificación

  const ResetPasswordScreen({
    Key? key,
    required this.email,
    required this.token,
  }) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.CustomAppBar( // ← MEJORADO: usar CustomAppBar con alias
        title: 'Nueva Contraseña',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // ← MEJORADO: Icono con gradiente
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      custom.primaryLilac.withOpacity(0.1),
                      custom.secondaryLilac.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: custom.primaryLilac.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.password,
                  size: 50,
                  color: custom.primaryLilac,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // ← MEJORADO: Título
            Text(
              'Restablecer contraseña',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: custom.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            // Subtítulo
            Text(
              'Ingresa tu nueva contraseña para',
              style: TextStyle(
                fontSize: 14,
                color: custom.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: custom.primaryLilac.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.email,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: custom.primaryLilac,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // ← MEJORADO: Nueva contraseña
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nueva contraseña',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: custom.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: custom.primaryLilac,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: custom.backgroundGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // ← MEJORADO: Confirmar contraseña
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirmar contraseña',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: custom.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: custom.primaryLilac,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: custom.backgroundGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // ← MEJORADO: Botón de restablecer
            custom.CustomButton(
              label: 'Restablecer contraseña',
              isLoading: _isLoading,
              onPressed: () async {
                if (_newPasswordController.text.isEmpty ||
                    _confirmPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor completa todos los campos'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (_newPasswordController.text != 
                    _confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Las contraseñas no coinciden'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (_newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La contraseña debe tener al menos 6 caracteres'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setState(() => _isLoading = true);

                try {
                  final db = DatabaseService();
                  final user = await db.getUserByEmail(widget.email);

                  if (user == null) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('El usuario ya no existe'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    setState(() => _isLoading = false);
                    return;
                  }

                  final updatedUser = user.copyWith(
                    password: _newPasswordController.text.trim(),
                  );

                  final success = await db.updateUser(updatedUser);

                  setState(() => _isLoading = false);

                  if (!success) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo actualizar la contraseña'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '¡Contraseña actualizada!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tu contraseña se ha restablecido correctamente. '
                              'Ahora puedes iniciar sesión con tu nueva contraseña.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: custom.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: custom.primaryLilac,
                            ),
                            child: const Text('Iniciar sesión'),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => _isLoading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar la contraseña: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
