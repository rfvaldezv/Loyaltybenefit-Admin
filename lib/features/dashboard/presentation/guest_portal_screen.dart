import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class GuestPortalScreen extends ConsumerStatefulWidget {
  final String tenantId;
  final String? initialEmail; 

  const GuestPortalScreen({super.key, required this.tenantId, this.initialEmail});

  @override
  ConsumerState<GuestPortalScreen> createState() => _GuestPortalScreenState();
}

class _GuestPortalScreenState extends ConsumerState<GuestPortalScreen> {
  late TextEditingController _emailController;
  bool _isLoading = false;
  Map<String, dynamic>? _accountData;

  final List<Map<String, dynamic>> _catalogo = [
    {'nombre': 'Café Gratis', 'puntos': 50, 'icono': Icons.coffee},
    {'nombre': 'Postre de Cortesía', 'puntos': 150, 'icono': Icons.cake},
    {'nombre': 'Upgrade de Habitación', 'puntos': 500, 'icono': Icons.king_bed},
    {'nombre': 'Noche Gratis', 'puntos': 2000, 'icono': Icons.hotel},
  ];

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _isLoading = true;
      Future.microtask(() => _consultarSaldo());
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _consultarSaldo() async {
    if (_emailController.text.isEmpty) return;
    if (!_isLoading) setState(() { _isLoading = true; _accountData = null; });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/api/portal/balance?email=${_emailController.text}&tenantId=${widget.tenantId}');
      
      if (mounted) {
        final data = response.data;
        setState(() {
          _accountData = {
            'cliente': data['cliente'] ?? 'Huésped',
            'puntos': data['puntos'] ?? 0,
            'saldoMonetario': data['saldoMonetario'] ?? 0.0,
            'nivel': data['nivel'] ?? 'Miembro',
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Cliente no encontrado o error de red')),
        );
      }
    }
  }

  Future<void> _canjearPremio(String premio, int puntos) async {
    if (_accountData == null) return;
    
    if ((_accountData!['puntos'] as int) < puntos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes suficientes puntos para este premio.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/api/portal/redeem', data: {
        'tenantId': widget.tenantId,
        'guestEmail': _emailController.text,
        'rewardName': premio,
        'pointsToRedeem': puntos,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ¡$premio canjeado con éxito!'), backgroundColor: Colors.green),
        );
        _consultarSaldo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Error al canjear.'), backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Lealtad'), backgroundColor: Colors.indigo),
      backgroundColor: Colors.grey[100],
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : _accountData == null 
              ? _buildLogin() 
              : _buildPortal(),
    );
  }

  Widget _buildLogin() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.card_giftcard, size: 80, color: Colors.indigo),
          const SizedBox(height: 24),
          const Text('Descubre tus recompensas', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Ingresa tu correo',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _consultarSaldo,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Entrar a mi cuenta', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildPortal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.indigo, Colors.deepPurple], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Hola, ${_accountData!['cliente']}', style: const TextStyle(color: Colors.white70, fontSize: 18)),
                    const Icon(Icons.contactless, color: Colors.white54),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('PUNTOS DISPONIBLES', style: TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 1.5)),
                Text('${_accountData!['puntos']}', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(label: Text(_accountData!['nivel'], style: const TextStyle(color: Colors.white)), backgroundColor: Colors.white24),
                    Text('\$${_accountData!['saldoMonetario']} MXN', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('Mesa de Regalos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          ..._catalogo.map((regalo) {
            final bool puedeCanjear = (_accountData!['puntos'] as int) >= (regalo['puntos'] as int);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.indigo.withValues(alpha: 0.1), 
                      child: Icon(regalo['icono'], color: Colors.indigo)
                    ),
                    const SizedBox(width: 16),
                    // Usamos Expanded para que el texto ocupe el espacio disponible
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(regalo['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${regalo['puntos']} puntos', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    // 👇 ENVOLVEMOS EL BOTÓN EN UN SIZED BOX CON ANCHO FIJO PARA EVITAR EL ERROR
                    SizedBox(
                      width: 90,
                      child: ElevatedButton(
                        onPressed: puedeCanjear ? () => _canjearPremio(regalo['nombre'], regalo['puntos']) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: puedeCanjear ? Colors.green : Colors.grey[300],
                          foregroundColor: puedeCanjear ? Colors.white : Colors.grey[600],
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(puedeCanjear ? 'Canjear' : 'Faltan', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          
          TextButton(
            onPressed: () => setState(() { _accountData = null; _emailController.clear(); }), 
            child: const Text('Salir', style: TextStyle(color: Colors.grey)),
          )
        ],
      ),
    );
  }
}
