import '../../../core/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getCorporateAnalytics();
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
      backgroundColor: const Color(0xFF0F172A), // Fondo oscuro
      appBar: AppBar(
        title: const Text('Dashboard Corporativo'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : _data == null
                  ? const Center(child: Text('No hay datos', style: TextStyle(color: Colors.white)))
                  : Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Fila de KPIs
                          Row(
                            children: [
                              _buildKpiCard('Clientes Totales', _data!['totalClientes'].toString(), Icons.people, Colors.blueAccent),
                              const SizedBox(width: 16),
                              _buildKpiCard('Puntos Otorgados', _data!['puntosOtorgados'].toString(), Icons.add_circle, Colors.greenAccent),
                              const SizedBox(width: 16),
                              _buildKpiCard('Puntos Canjeados', _data!['puntosCanjeados'].toString(), Icons.remove_circle, Colors.redAccent),
                              const SizedBox(width: 16),
                              _buildKpiCard('Saldo en Circulación', _data!['saldoActualEnCirculacion'].toString(), Icons.stars, Colors.amberAccent),
                            ],
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            'Puntos Ganados por Propiedad',
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          // Gráfico de barras con datos reales
                          Expanded(
                            child: _buildBarChart(_data!['chartData'] as List<dynamic>),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            )
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

    // Encontrar el valor máximo para escalar las barras
    final maxVal = data.map((e) => e['puntosGanados'] as int).reduce((a, b) => a > b ? a : b);
    // Evitar división por cero
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
              height: 250 * heightFactor, // Altura dinámica
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.indigo, Colors.indigoAccent],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigoAccent.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
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
