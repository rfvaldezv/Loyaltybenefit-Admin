import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'guest_portal_screen.dart';

class CustomersListScreen extends ConsumerStatefulWidget {
  final String tenantId;
  const CustomersListScreen({super.key, required this.tenantId});

  @override
  ConsumerState<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  bool _isLoading = true;
  List<dynamic> _clientes = [];

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getCustomers(widget.tenantId);

      if (mounted) {
        setState(() {
          _clientes = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar clientes: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _mostrarModalAjuste(dynamic cliente) {
    final pointsController = TextEditingController();
    final reasonController = TextEditingController();
    bool isAbono = true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: Text('Ajustar Puntos a ${cliente['firstName']}', style: const TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Abono (+)'),
                          selected: isAbono,
                          onSelected: (val) => setStateDialog(() => isAbono = true),
                          selectedColor: Colors.green.withValues(alpha: 0.3),
                          labelStyle: TextStyle(color: isAbono ? Colors.greenAccent : Colors.white54),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Cargo (-)'),
                          selected: !isAbono,
                          onSelected: (val) => setStateDialog(() => isAbono = false),
                          selectedColor: Colors.red.withValues(alpha: 0.3),
                          labelStyle: TextStyle(color: !isAbono ? Colors.redAccent : Colors.white54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pointsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad de puntos',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.indigoAccent)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Razón del ajuste',
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
                          final pointsStr = pointsController.text.trim();
                          final reason = reasonController.text.trim();

                          if (pointsStr.isEmpty || reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Llena todos los campos')),
                            );
                            return;
                          }

                          final amount = int.tryParse(pointsStr);
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ingresa una cantidad válida mayor a 0')),
                            );
                            return;
                          }

                          setStateDialog(() => isSaving = true);
                          final finalPoints = isAbono ? amount : -amount;

                          try {
                            final api = ref.read(apiClientProvider);
                            await api.adjustPoints(cliente['id'], widget.tenantId, finalPoints, reason);

                            // Si el modal sigue vivo, lo cerramos y mostramos mensaje
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(content: Text('✅ Ajuste realizado correctamente'), backgroundColor: Colors.green),
                              );
                              _cargarClientes();
                            }
                          } catch (e) {
                            setStateDialog(() => isSaving = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Guardar Ajuste'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fondo oscuro
      appBar: AppBar(
        title: const Text('Directorio de Clientes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard),
            tooltip: 'Portal del Huésped',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GuestPortalScreen(tenantId: widget.tenantId)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarClientes,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
          : _clientes.isEmpty
              ? const Center(
                  child: Text('No hay clientes registrados aún.', style: TextStyle(color: Colors.white54, fontSize: 18)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = _clientes[index];
                    return Card(
                      color: const Color(0xFF1E293B), // Fondo de tarjeta oscuro
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)), // Borde sutil
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GuestPortalScreen(
                                tenantId: widget.tenantId,
                                initialEmail: cliente['email'],
                              ),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigoAccent.withValues(alpha: 0.2),
                          child: Text(
                            cliente['firstName']?.substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text('${cliente['firstName']} ${cliente['lastName']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(cliente['email'], style: const TextStyle(color: Colors.white54)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.greenAccent),
                              tooltip: 'Ajustar Puntos',
                              onPressed: () => _mostrarModalAjuste(cliente),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white54),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
