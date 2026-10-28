import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_screen.dart';
import 'customers_list_screen.dart';
import 'tenant_detail_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final String tenantId;
  const DashboardScreen({super.key, required this.tenantId});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0; // 0 = Analytics, 1 = Clientes, 2 = Detalles

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fondo oscuro
      body: Row(
        children: [
          // --- SIDEBAR (Menú Lateral) ---
          Container(
            width: 250,
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo / Título
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.card_giftcard, color: Colors.indigoAccent, size: 32),
                    SizedBox(width: 12),
                    Text(
                      'Loyalty Admin',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                
                // Opciones del menú
                _buildMenuItem(
                  icon: Icons.analytics,
                  title: 'Dashboard Corporativo',
                  index: 0,
                ),
                _buildMenuItem(
                  icon: Icons.people,
                  title: 'Directorio de Clientes',
                  index: 1,
                ),
                _buildMenuItem(
                  icon: Icons.settings,
                  title: 'Configuración Hotel',
                  index: 2,
                ),
                
                const Spacer(),
                // Botón de Salir
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.of(context).pushReplacementNamed('/'); // Ajusta según tu enrutamiento
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // --- ÁREA DE CONTENIDO PRINCIPAL ---
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                const AnalyticsScreen(), 
                CustomersListScreen(tenantId: widget.tenantId), 
                TenantDetailScreen(tenantId: widget.tenantId), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required int index}) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Material( // <-- ESTO ARREGLA EL ERROR VISUAL
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(icon, color: isSelected ? Colors.indigoAccent : Colors.white54),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          selectedTileColor: Colors.indigoAccent.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}
