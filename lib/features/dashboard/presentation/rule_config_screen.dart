import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class RuleConfigScreen extends ConsumerStatefulWidget {
  final String tenantId;
  final String tenantName;

  const RuleConfigScreen({
    super.key, 
    required this.tenantId,
    required this.tenantName,
  });

  @override
  ConsumerState<RuleConfigScreen> createState() => _RuleConfigScreenState();
}

class _RuleConfigScreenState extends ConsumerState<RuleConfigScreen> {
  final _amountController = TextEditingController();
  final _pointsController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingInitial = true;

  @override
  void initState() {
    super.initState();
    _cargarReglaActual();
  }

  Future<void> _cargarReglaActual() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/api/rules/${widget.tenantId}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        _amountController.text = data['amountThreshold'].toString();
        _pointsController.text = data['points'].toString();
      }
    } catch (e) {
      _amountController.text = '100';
      _pointsController.text = '1';
    } finally {
      setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _guardarRegla() async {
    final amount = double.tryParse(_amountController.text);
    final points = int.tryParse(_pointsController.text);

    if (amount == null || amount <= 0 || points == null || points <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa valores válidos mayores a 0')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.createRule(
        tenantId: widget.tenantId,
        amountThreshold: amount,
        points: points,
      );

      if (mounted) {
        final data = response.data;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${data['mensaje'] ?? 'Regla guardada'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Error: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reglas de Lealtad')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Configuración para: ${widget.tenantName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Define cuántos puntos gana un huésped por cada monto de consumo.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                const Text('\$', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monto de consumo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _pointsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Puntos otorgados',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _guardarRegla,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Guardar Regla'),
            ),
          ],
        ),
      ),
    );
  }
}
