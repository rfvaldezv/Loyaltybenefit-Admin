import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tenant_model.dart';
import 'customer_form_screen.dart';
import 'rule_config_screen.dart';
import 'customers_list_screen.dart'; // 👈 Importamos la nueva lista
import 'guest_portal_screen.dart';  // 👈 Importamos el portal

class TenantDetailScreen extends ConsumerWidget {
  final TenantModel tenant;

  const TenantDetailScreen({super.key, required this.tenant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tenant.name),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // 👇 BOTÓN DEL PORTAL DEL HUÉSPED EN LA PARTE SUPERIOR
          IconButton(
            icon: const Icon(Icons.card_giftcard),
            tooltip: 'Portal del Huésped',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GuestPortalScreen(tenantId: tenant.id),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TARJETA DE INFORMACIÓN DEL HOTEL
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Información de la Empresa', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    _buildInfoRow('Nombre:', tenant.name),
                    _buildInfoRow('Código:', tenant.code),
                    _buildInfoRow('ID:', tenant.id),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // BOTÓN PARA CONFIGURAR REGLAS
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RuleConfigScreen(
                      tenantId: tenant.id,
                      tenantName: tenant.name,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('Configurar Regla de Puntos'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.indigo.shade50,
                foregroundColor: Colors.indigo,
              ),
            ),
            
            const SizedBox(height: 24),
            Text('Lista de Clientes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            
            // 👇 AQUÍ REEMPLAZAMOS EL TEXTO DE "PRÓXIMAMENTE" POR LA LISTA REAL
            Expanded(
              child: CustomersListScreen(tenantId: tenant.id),
            ),
          ],
        ),
      ),
      // BOTÓN FLOTANTE PARA AGREGAR CLIENTE
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerFormScreen(
                tenantId: tenant.id,
              ),
            ),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Cliente'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
