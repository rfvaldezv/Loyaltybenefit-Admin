import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _isLoading = true;
  bool _isLoadingProperties = true;
  Map<String, dynamic>? _data;
  String? _error;
  
  List<dynamic> _properties = [];
  String? _selectedPropertyId; // null = Corporativo (Todos)

  @override
  void initState() {
    super.initState();
    _cargarPropiedades();
    _cargarDatos();
  }

  Future<void> _cargarPropiedades() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getProperties();
      setState(() {
        _properties = response.data;
        _isLoadingProperties = false;
      });
    } catch (e) {
      setState(() => _isLoadingProperties = false);
    }
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getAnalytics(propertyId: _selectedPropertyId);
      setState(() => _data = response.data);
    } catch (e) {
      setState(() => _error = 'Error al cargar datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Dashboard de Analítica'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          )
        ],
      ),
      body: Column(
        children: [
          // Selector de Propiedad
          if (!_isLoadingProperties)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPropertyId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E293B),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.indigoAccent),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    hint: const Text('Corporativo (Todas las Propiedades)', style: TextStyle(color: Colors.white70)),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Corporativo (Todas las Propiedades)', style: TextStyle(color: Colors.white)),
                      ),
                      ..._properties.map((p) => DropdownMenuItem<String>(
                        value: p['id'],
                        child: Text(p['name'], style: const TextStyle(color: Colors.white)),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedPropertyId = value);
                      _cargarDatos();
                    },
                  ),
                ),
              ),
            ),
            
          // Contenido del Dashboard
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                    : _data == null
                        ? const Center(child: Text('No hay datos', style: TextStyle(color: Colors.white)))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Fila de KPIs
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: [
                                    _buildKpiCard('Clientes Totales', _data!['totalClientes'].toString(), Icons.people, Colors.blueAccent),
                                    _buildKpiCard('Puntos Otorgados', _data!['puntosOtorgados'].toString(), Icons.add_circle, Colors.greenAccent),
                                    _buildKpiCard('Puntos Canjeados', _data!['puntosCanjeados'].toString(), Icons.remove_circle, Colors.redAccent),
                                    _buildKpiCard('Saldo en Circulación', _data!['saldoActualEnCirculacion'].toString(), Icons.stars, Colors.amberAccent),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                const Text(
                                  'Puntos Ganados por Propiedad',
                                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 24),
                                // Gráfico de barras
                                SizedBox(
                                  height: 300,
                                  child: _buildBarChart(_data!['chartData'] as List<dynamic>),
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<dynamic> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'Sin movimientos por propiedad aún.\nAsigna PropertyId a las transacciones en SQL.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    final maxVal = data.map((e) => e['puntosGanados'] as int).reduce((a, b) => a > b ? a : b);
    final safeMax = maxVal == 0 ? 1 : maxVal;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: data.map((item) {
        final val = item['puntosGanados'] as int;
        final heightFactor = val / safeMax;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(val.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              width: 60,
              height: 200 * heightFactor,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.indigo, Colors.indigoAccent],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(color: Colors.indigoAccent.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, -4))
                ]
              ),
            ),
            const SizedBox(height: 8),
            Text(item['propertyName'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }
}
