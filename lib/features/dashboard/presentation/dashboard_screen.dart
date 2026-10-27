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
      final response = await api.get('/api/customers');
      
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
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                          child: Text(
                            cliente['firstName']?.substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text('${cliente['firstName']} ${cliente['lastName']}'),
                        subtitle: Text(cliente['email']),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    );
                  },
                ),
    );
  }
}
