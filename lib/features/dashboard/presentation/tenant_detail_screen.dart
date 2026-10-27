import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class TenantDetailScreen extends ConsumerStatefulWidget {
  final String tenantId;
  const TenantDetailScreen({super.key, required this.tenantId});

  @override
  ConsumerState<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends ConsumerState<TenantDetailScreen> {
  bool _isUploading = false;

  Future<void> _subirLogo() async {
    // 1. Abrir el selector de archivos nativo del navegador
    final html.FileUploadInputElement input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    // 2. Esperar a que el usuario seleccione un archivo
    await input.onChange.first;
    if (input.files!.isEmpty) return;

    final file = input.files!.first;
    final reader = html.FileReader();

    // 3. Leer el archivo
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;

    final bytes = reader.result as Uint8List;
    final fileName = file.name;

    setState(() => _isUploading = true);

    try {
      final api = ref.read(apiClientProvider);
      // Subimos los bytes usando el método que creamos en el ApiClient
      await api.uploadLogoBytes(widget.tenantId, bytes, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Logo subido exitosamente'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Hotel'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Configuración del Hotel',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _subirLogo,
              icon: _isUploading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.upload_file),
              label: Text(_isUploading ? 'Subiendo...' : 'Subir Logo del Hotel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
