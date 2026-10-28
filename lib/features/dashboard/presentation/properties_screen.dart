import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class PropertiesScreen extends ConsumerStatefulWidget {
  const PropertiesScreen({super.key});

  @override
  ConsumerState<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends ConsumerState<PropertiesScreen> {
  bool _isLoading = true;
  List<dynamic> _properties = [];

  @override
  void initState() {
    super.initState();
    _cargarPropiedades();
  }

  Future<void> _cargarPropiedades() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getProperties();
      if (mounted) {
        setState(() {
          // Forzamos una nueva lista y filtramos los inactivos (borrados)
          _properties = List<dynamic>.from(response.data).where((p) => p['isActive'] == true).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _mostrarModal({dynamic propiedad}) async {
    final nameCtrl = TextEditingController(text: propiedad != null ? propiedad['name'] : '');
    final codeCtrl = TextEditingController(text: propiedad != null ? propiedad['code'] : '');
    
    final bool? resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSaving = false;
        
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: Text(propiedad != null ? 'Editar Propiedad' : 'Nueva Propiedad', style: const TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Nombre', labelStyle: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Código', labelStyle: TextStyle(color: Colors.white54)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) return;
                          setStateDialog(() => isSaving = true);
                          
                          try {
                            final api = ref.read(apiClientProvider);
                            if (propiedad != null) {
                              await api.updateProperty(id: propiedad['id'], name: nameCtrl.text.trim(), code: codeCtrl.text.trim());
                            } else {
                              await api.createProperty(name: nameCtrl.text.trim(), code: codeCtrl.text.trim());
                            }
                            
                            if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                            
                          } catch (e) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.redAccent),
                              );
                              setStateDialog(() => isSaving = false);
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

    // REFRESCAMOS LA LISTA AQUÍ AFUERA DEL MODAL SI SE GUARDÓ
    if (resultado == true) {
      await _cargarPropiedades();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Guardado correctamente'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _eliminarPropiedad(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('¿Eliminar Propiedad?', style: TextStyle(color: Colors.white)),
        content: const Text('El hotel se desactivará del sistema.', style: TextStyle(color: Colors.white70)),
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
        await api.deleteProperty(id);
        await _cargarPropiedades(); // Recargamos la lista desde el servidor
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🗑️ Propiedad eliminada'), backgroundColor: Colors.green),
          );
        }
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
        title: const Text('Gestión de Propiedades'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.indigoAccent),
            onPressed: () => _mostrarModal(),
          )
        ],
      ),
      body: _isLoading && _properties.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
          : _properties.isEmpty
              ? const Center(child: Text('No hay propiedades activas.', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _properties.length,
                  itemBuilder: (context, index) {
                    final prop = _properties[index];
                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigoAccent.withValues(alpha: 0.2),
                          child: const Icon(Icons.hotel, color: Colors.indigoAccent),
                        ),
                        title: Text(prop['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(prop['code'], style: const TextStyle(color: Colors.white54)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                              onPressed: () => _mostrarModal(propiedad: prop),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                              onPressed: () => _eliminarPropiedad(prop['id']),
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
