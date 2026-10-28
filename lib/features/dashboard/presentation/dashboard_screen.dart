import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'analytics_screen.dart';
import 'customers_list_screen.dart';
import 'tenant_detail_screen.dart';
import 'properties_screen.dart';
import 'users_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final String tenantId;
  const DashboardScreen({super.key, required this.tenantId});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final api = ref.read(apiClientProvider);
    final isSuperAdmin = api.userRole == 'SuperAdmin';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Row(
        children: [
          // --- SIDEBAR ---
          Container(
            width: 260,
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                const SizedBox(height: 32),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.card_giftcard, color: Colors.indigoAccent, size: 32),
                    SizedBox(width: 12),
                    Text('Loyalty Admin', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 32),

                // Info del Usuario
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: isSuperAdmin ? Colors.indigoAccent : Colors.greenAccent,
                          child: Icon(Icons.person, size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(api.userEmail ?? 'Usuario', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                              Text(isSuperAdmin ? 'SuperAdmin' : 'Admin de Hotel', style: TextStyle(color: isSuperAdmin ? Colors.indigoAccent : Colors.greenAccent, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Opciones del menú
                _buildMenuItem(icon: Icons.analytics, title: isSuperAdmin ? 'Dashboard Corporativo' : 'Mi Hotel', index: 0),
                
                // Solo SuperAdmin ve Clientes, Configuración, Propiedades y Usuarios
                if (isSuperAdmin) ...[
                  _buildMenuItem(icon: Icons.people, title: 'Clientes', index: 1),
                  _buildMenuItem(icon: Icons.settings, title: 'Configuración Hotel', index: 2),
                  _buildMenuItem(icon: Icons.hotel, title: 'Propiedades', index: 3),
                  _buildMenuItem(icon: Icons.manage_accounts, title: 'Usuarios', index: 4),
                ] else ...[
                  // Si es TenantAdmin, le mostramos su propia configuración de hotel (opcional)
                  _buildMenuItem(icon: Icons.settings, title: 'Mi Configuración', index: 2),
                ],
                
                const Spacer(),
                // Botón de Salir
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    api.clearToken();
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // --- ÁREA DE CONTENIDO PRINCIPAL ---
          Expanded(
            child: _buildCurrentScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0: return AnalyticsScreen(key: UniqueKey()); // Forzamos recarga visual
      case 1: return CustomersListScreen(key: UniqueKey(), tenantId: widget.tenantId);
      case 2: return TenantDetailScreen(key: UniqueKey(), tenantId: widget.tenantId);
      case 3: return PropertiesScreen(key: UniqueKey());
      case 4: return UsersScreen(key: UniqueKey());
      default: return const AnalyticsScreen();
    }
  }

  Widget _buildMenuItem({required IconData icon, required String title, required int index}) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(icon, color: isSelected ? Colors.indigoAccent : Colors.white54),
          title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          selected: isSelected,
          selectedTileColor: Colors.indigoAccent.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: () => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}
