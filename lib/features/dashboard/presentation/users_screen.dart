import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  bool _isLoading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getUsers();
      if (mounted) setState(() => _users = response.data);
    } catch (e) {
      // Error handling
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- CREAR USUARIO ---
  void _mostrarModalCrear() {
    _mostrarModalFormulario();
  }

  // --- EDITAR USUARIO ---
  void _mostrarModalEditar(dynamic user) {
    _mostrarModalFormulario(usuario: user);
  }

  // --- FORMULARIO (SRP: Una sola función para crear y editar) ---
  void _mostrarModalFormulario({dynamic usuario}) {
    final emailCtrl = TextEditingController(text: usuario != null ? usuario['email'] : '');
    final passCtrl = TextEditingController();
    String selectedRole = usuario != null ? usuario['role'] : 'TenantAdmin';
    bool isEditing = usuario != null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSaving = false;
        
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: Text(isEditing ? 'Editar Usuario' : 'Nuevo Usuario', style: const TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailCtrl,
                    readOnly: isEditing, // El correo no se edita
                    style: TextStyle(color: isEditing ? Colors.white54 : Colors.white),
                    decoration: const InputDecoration(labelText: 'Correo', labelStyle: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: isEditing ? 'Nueva Contraseña (Opcional)' : 'Contraseña', 
                      labelStyle: const TextStyle(color: Colors.white54)
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownMenu<String>(
                    initialSelection: selectedRole,
                    width: 300,
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: 'SuperAdmin', label: 'SuperAdmin (Ve todo)'),
                      DropdownMenuEntry(value: 'TenantAdmin', label: 'Admin de Hotel'),
                    ],
                    onSelected: (val) {
                      if (val != null) setStateDialog(() => selectedRole = val);
                    },
                    textStyle: const TextStyle(color: Colors.white),
                    inputDecorationTheme: const InputDecorationTheme(
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.indigoAccent)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (emailCtrl.text.isEmpty || (!isEditing && passCtrl.text.isEmpty)) return;
                          setStateDialog(() => isSaving = true);
                          
                          try {
                            final api = ref.read(apiClientProvider);
                            if (isEditing) {
                              await api.updateUser(
                                id: usuario['id'], 
                                role: selectedRole, 
                                isActive: true,
                                password: passCtrl.text.isNotEmpty ? passCtrl.text : null,
                              );
                            } else {
                              await api.createUser(email: emailCtrl.text.trim(), password: passCtrl.text.trim(), role: selectedRole);
                            }
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                            _cargarUsuarios();
                          } catch (e) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- ELIMINAR USUARIO ---
  Future<void> _eliminarUsuario(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('¿Eliminar Usuario?', style: TextStyle(color: Colors.white)),
        content: const Text('El usuario ya no podrá acceder al sistema.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final api = ref.read(apiClientProvider);
        await api.deleteUser(id);
        setState(() {
          _users.removeWhere((u) => u['id'] == id); // Lo quitamos visualmente
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Usuarios Administradores'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Colors.indigoAccent), onPressed: _mostrarModalCrear),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  color: const Color(0xFF1E293B),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigoAccent.withValues(alpha: 0.2),
                      child: const Icon(Icons.person, color: Colors.indigoAccent),
                    ),
                    title: Text(user['email'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(user['role'], style: const TextStyle(color: Colors.white54)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                          onPressed: () => _mostrarModalEditar(user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                          onPressed: () => _eliminarUsuario(user['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
