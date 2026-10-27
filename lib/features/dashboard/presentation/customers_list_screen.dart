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
  List<dynamic> _clientes = []; // Dejamos el warning de final (no rompe nada)

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
          SnackBar(content: Text('Error al cargar clientes: $e')),
        );
      }
    }
  }

  // Modal para ajustar puntos
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
              title: Text('Ajustar Puntos a ${cliente['firstName']}'),
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
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Cargo (-)'),
                          selected: !isAbono,
                          onSelected: (val) => setStateDialog(() => isAbono = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pointsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad de puntos',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Razón del ajuste',
                      prefixIcon: Icon(Icons.comment),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
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
                            // AQUÍ ESTÁ EL AJUSTE CORRECTO: pasamos el tenantId
                            await api.adjustPoints(cliente['id'], widget.tenantId, finalPoints, reason);

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Ajuste realizado correctamente'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _cargarClientes();
                            }
                          } catch (e) {
                            setStateDialog(() => isSaving = false);
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
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
      appBar: AppBar(
        title: const Text('Directorio de Clientes'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard),
            tooltip: 'Portal del Huésped',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GuestPortalScreen(tenantId: widget.tenantId),
                ),
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
          ? const Center(child: CircularProgressIndicator())
          : _clientes.isEmpty
              ? const Center(
                  child: Text('No hay clientes registrados aún.', style: TextStyle(color: Colors.grey, fontSize: 18)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = _clientes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
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
                          backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                          child: Text(
                            cliente['firstName']?.substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text('${cliente['firstName']} ${cliente['lastName']}'),
                        subtitle: Text(cliente['email']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.indigo),
                              tooltip: 'Ajustar Puntos',
                              onPressed: () => _mostrarModalAjuste(cliente),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.indigo),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
