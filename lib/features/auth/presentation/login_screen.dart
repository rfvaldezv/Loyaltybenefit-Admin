import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../dashboard/presentation/tenant_detail_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ref.read(apiClientProvider);
      
      // Hacemos login a la API (Ajusta la ruta si es diferente)
      final response = await api.post('/api/auth/login', data: {
        'email': _emailController.text,
        'password': _passwordController.text,
      });

      if (response.statusCode == 200) {
        // Guardamos el token si es necesario
        final token = response.data['token'];
        if (token != null) api.setToken(token);

        // Navegamos al detalle del tenant.
        // ⚠️ NOTA: Aquí estamos usando un ID fijo para que compile. 
        // Si tu API devuelve el ID del usuario, cámbialo por response.data['tenantId'] o similar.
        const tenantIdTemporal = 'D8D6CB00-2600-4A83-9C4E-02F76065210D'; // Cambia esto por el GUID real o el del response
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              // AQUÍ ESTÁ LA LÍNEA QUE DABA ERROR, YA BIEN CERRADA
              builder: (_) => const TenantDetailScreen(tenantId: tenantIdTemporal),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fondo oscuro
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings, size: 80, color: Colors.indigoAccent),
                const SizedBox(height: 24),
                const Text(
                  'Loyalty Benefit',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text(
                  'Panel de Administración',
                  style: TextStyle(fontSize: 16, color: Colors.white54),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.email, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Iniciar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
