import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart' as custom; // ← MEJORADO: con alias
import '../services/database_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late TextEditingController _emailController;
  bool _isLoading = false;
  bool _emailSent = false;
  String? _resetToken;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: custom.CustomAppBar( // ← MEJORADO: usar CustomAppBar con alias
        title: 'Recuperar Contraseña',
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
                  Icons.lock_reset,
                  size: 50,
                  color: custom.primaryLilac,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // ← MEJORADO: Título
            Text(
              '¿Olvidaste tu contraseña?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: custom.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            // Subtítulo
            Text(
              'Ingresa tu correo electrónico y te enviaremos instrucciones para restablecer tu contraseña.',
              style: TextStyle(
                fontSize: 14,
                color: custom.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            if (_emailSent) ...[
              // ← MEJORADO: Mensaje de éxito
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '¡Correo enviado!',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hemos enviado instrucciones a:',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _emailController.text,
                        style: TextStyle(
                          color: custom.primaryLilac,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Revisa tu bandeja de entrada y sigue las instrucciones para restablecer tu contraseña.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_resetToken != null)
                custom.CustomButton(
                  label: 'Restablecer contraseña ahora',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ResetPasswordScreen(
                          email: _emailController.text.trim(),
                          token: _resetToken!,
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),
              custom.CustomButton(
                label: 'Volver al inicio de sesión',
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ] else ...[
              // ← MEJORADO: Campo de email
              custom.CustomTextField(
                label: 'Correo electrónico',
                hint: 'correo@ejemplo.com',
                controller: _emailController,
                inputType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 24),
              // ← MEJORADO: Botón de enviar
              custom.CustomButton(
                label: 'Enviar instrucciones',
                isLoading: _isLoading,
                onPressed: () async {
                  final email = _emailController.text.trim();

                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor ingresa tu correo electrónico'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  try {
                    final user = await DatabaseService().getUserByEmail(email);

                    if (user == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('El correo no está registrado'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }

                    setState(() {
                      _resetToken = DateTime.now().millisecondsSinceEpoch.toString();
                      _emailSent = true;
                    });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hemos generado un enlace de restablecimiento para $email'),
                          backgroundColor: Colors.green[700],
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al procesar la solicitud: '),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              // ← MEJORADO: Link para volver al login
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: custom.primaryLilac,
                  ),
                  child: const Text(
                    'Volver al inicio de sesión',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
