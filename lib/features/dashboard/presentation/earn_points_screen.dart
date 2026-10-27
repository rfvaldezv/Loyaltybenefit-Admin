import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class EarnPointsScreen extends ConsumerStatefulWidget {
  final String customerName;
  final String guestId;
  final String tenantId;

  const EarnPointsScreen({
    super.key, 
    required this.customerName,
    required this.guestId,
    required this.tenantId,
  });

  @override
  ConsumerState<EarnPointsScreen> createState() => _EarnPointsScreenState();
}

class _EarnPointsScreenState extends ConsumerState<EarnPointsScreen> {
  final _amountController = TextEditingController(text: '1500');
  bool _isLoading = false;

  Future<void> _registrarEstancia() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      
      // 👈 Llamamos sin el stayId porque el backend lo genera
      final response = await api.createStay(
        tenantId: widget.tenantId, 
        guestId: widget.guestId, 
        amount: amount,
      );

      if (mounted) {
        final data = response.data;
        final puntos = data['puntosGanados'] ?? data['PuntosGanados'] ?? 0;
        final mensaje = data['mensaje'] ?? data['Mensaje'] ?? 'Éxito';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $mensaje\n⭐ Puntos otorgados: $puntos'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Error desconocido';
        
        // 🔥 Extraemos el mensaje exacto del servidor
        if (e is DioException) {
          final responseData = e.response?.data;
          if (responseData is String) {
            errorMsg = responseData; // Si es un texto plano
          } else if (responseData != null) {
            errorMsg = responseData.toString(); // Si es un JSON
          } else {
            errorMsg = e.message ?? 'Error de red';
          }
        } else {
          errorMsg = e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Servidor dice: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Estancia')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cliente: ${widget.customerName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ingresa el monto total de la estancia para calcular los puntos.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monto (MXN)',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _registrarEstancia,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Calcular y Sumar Puntos'),
            ),
          ],
        ),
      ),
    );
  }
}
