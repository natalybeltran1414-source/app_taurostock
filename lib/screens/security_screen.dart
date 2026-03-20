import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_widgets.dart' as custom;

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({Key? key}) : super(key: key);

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).loadAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final isAdmin = currentUser?.role == 'admin';

    return Scaffold(
      appBar: const custom.CustomAppBar(
        title: 'Seguridad y Roles',
        showBackButton: true,
      ),
      body: authProvider.isLoading
          ? const custom.CustomLoadingIndicator(message: 'Cargando configuración...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECCIÓN: MI PERFIL ---
                  custom.SectionHeader(title: 'Mi Perfil'),
                  const SizedBox(height: 12),
                  _buildMyProfileCard(currentUser),
                  
                  const SizedBox(height: 32),

                  // --- SECCIÓN: GESTIÓN DE EQUIPO ---
                  if (isAdmin) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        custom.SectionHeader(title: 'Gestión de Equipo'),
                        TextButton.icon(
                          onPressed: () => _showAddUserDialog(context),
                          icon: const Icon(Icons.person_add_outlined, size: 18),
                          label: const Text('Nuevo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildUserList(authProvider),
                  ] else ...[
                    const custom.EmptyState(
                      message: 'Solo los administradores pueden gestionar el equipo',
                      icon: Icons.lock_outline,
                    ),
                  ],
                ],
              ),
            ),
      floatingActionButton: isAdmin 
          ? FloatingActionButton(
              onPressed: () => _showAddUserDialog(context),
              backgroundColor: custom.primaryLilac,
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildMyProfileCard(User? user) {
    if (user == null) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: custom.primaryLilac.withOpacity(0.1),
                  child: Text(
                    user.fullName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: custom.primaryLilac,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (user.role == 'admin' ? Colors.amber : Colors.blue).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: user.role == 'admin' ? Colors.amber[800] : Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                // Implementar cambio de contraseña
                _showChangePasswordDialog(context, user);
              },
              icon: const Icon(Icons.vpn_key_outlined, size: 18),
              label: const Text('Cambiar mi contraseña'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(AuthProvider provider) {
    final users = provider.allUsers;
    
    if (users.isEmpty) {
      return const Center(child: Text('No hay otros usuarios registrados'));
    }

    return Column(
      children: users.map((user) {
        // No mostrar el usuario actual en la lista de gestión (ya está arriba)
        if (user.id == provider.currentUser?.id) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: custom.ListItemCard(
            title: user.fullName,
            subtitle: '${user.email} • Rol: ${user.role}',
            amount: '',
            icon: Icons.person_outline,
            color: user.isActive ? custom.primaryLilac : Colors.grey,
            status: user.isActive ? 'ACTIVO' : 'INACTIVO',
            onTap: () => _showEditUserDialog(context, user),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz),
              onSelected: (value) => _handleUserAction(value, user, provider),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit_role', child: Text('Cambiar Rol')),
                const PopupMenuItem(value: 'reset_pass', child: Text('Reiniciar Contraseña')),
                PopupMenuItem(
                  value: 'toggle_status', 
                  child: Text(user.isActive ? 'Desactivar' : 'Activar'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passController = TextEditingController();
    String role = 'empleado';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar Colaborador'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                custom.CustomTextField(label: 'Nombre Completo', controller: nameController),
                custom.CustomTextField(label: 'Email', controller: emailController, inputType: TextInputType.emailAddress),
                custom.CustomTextField(label: 'Contraseña Temporal', controller: passController, obscureText: true),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Rol de Usuario', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DropdownButton<String>(
                  value: (role == 'admin' || role == 'empleado') ? role : 'empleado',
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'empleado', child: Text('Empleado (Ventas/Inventario)')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrador (Acceso Total)')),
                  ],
                  onChanged: (val) => setDialogState(() => role = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || emailController.text.isEmpty || passController.text.isEmpty) return;
                
                final success = await Provider.of<AuthProvider>(context, listen: false).createUserByAdmin(
                  emailController.text.trim(),
                  passController.text,
                  nameController.text.trim(),
                  role,
                );

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario creado correctamente'), backgroundColor: Colors.green));
                }
              },
              child: const Text('CREAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, User user) {
    // Diálogo simplificado para editar rol o estado
    String role = (user.role == 'admin') ? 'admin' : 'empleado';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Gestionar: ${user.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(alignment: Alignment.centerLeft, child: Text('Cambiar Rol')),
              DropdownButton<String>(
                value: (role == 'admin' || role == 'empleado') ? role : 'empleado',
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'empleado', child: Text('Empleado')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                ],
                onChanged: (val) => setDialogState(() => role = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CERRAR')),
            ElevatedButton(
              onPressed: () async {
                final updatedUser = user.copyWith(role: role);
                final success = await Provider.of<AuthProvider>(context, listen: false).updateUserInfo(updatedUser);
                if (success && mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('APLICAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, User user) {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.id == Provider.of<AuthProvider>(context, listen: false).currentUser?.id 
            ? 'Cambiar mi contraseña' 
            : 'Reiniciar contraseña de ${user.fullName}'),
        content: custom.CustomTextField(
          label: 'Nueva Contraseña',
          controller: passController,
          obscureText: true,
          hint: 'Mínimo 6 caracteres',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              if (passController.text.length < 6) return;
              final updatedUser = user.copyWith(password: passController.text);
              final success = await Provider.of<AuthProvider>(context, listen: false).updateUserInfo(updatedUser);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada'), backgroundColor: Colors.green));
              }
            },
            child: const Text('CAMBIAR'),
          ),
        ],
      ),
    );
  }

  void _handleUserAction(String action, User user, AuthProvider provider) {
    switch (action) {
      case 'edit_role':
        _showEditUserDialog(context, user);
        break;
      case 'reset_pass':
        _showChangePasswordDialog(context, user);
        break;
      case 'toggle_status':
        final updatedUser = user.copyWith(isActive: !user.isActive);
        provider.updateUserInfo(updatedUser);
        break;
    }
  }
}
