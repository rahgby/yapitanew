import 'package:cloud_firestore/cloud_firestore.dart';

class BoletaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Buscar boleta por código
  Future<Map<String, dynamic>?> buscarBoletaPorCodigo(String codigoBoleta) async {
    try {
      print('🔍 [BoletaService] Iniciando búsqueda de boleta...');
      print('📝 [BoletaService] Código recibido: "$codigoBoleta"');
      print('📝 [BoletaService] Longitud del código: ${codigoBoleta.length} caracteres');
      print('📝 [BoletaService] Código trimmeado: "${codigoBoleta.trim()}"');

      // Validar que el código no esté vacío
      if (codigoBoleta.trim().isEmpty) {
        print('❌ [BoletaService] ERROR: Código de boleta está vacío');
        return null;
      }

      print('🔥 [BoletaService] Ejecutando consulta en Firestore...');
      print('📋 [BoletaService] Collection: "boletas"');
      print('🔎 [BoletaService] Where: codigoBoleta = "$codigoBoleta"');
      print('🎯 [BoletaService] Limit: 1 documento');

      final query = await _firestore
          .collection('boletas')
          .where('codigoBoleta', isEqualTo: codigoBoleta)
          .limit(1)
          .get();

      print('📊 [BoletaService] Consulta completada');
      print('📄 [BoletaService] Documentos encontrados: ${query.docs.length}');

      if (query.docs.isNotEmpty) {
        final boleta = query.docs.first;
        final boletaData = boleta.data() as Map<String, dynamic>;

        print('✅ [BoletaService] BOLETA ENCONTRADA EXITOSAMENTE');
        print('🆔 [BoletaService] ID del documento: ${boleta.id}');
        print('📦 [BoletaService] Datos de la boleta:');
        print('   - ID: ${boleta.id}');
        print('   - Código: ${boletaData['codigoBoleta']}');
        print('   - Monto Total: \$${boletaData['montoTotal']?.toStringAsFixed(2) ?? "N/A"}');
        print('   - Fecha: ${boletaData['fecha'] ?? "N/A"}');
        print('   - Campos adicionales: ${boletaData.keys.toList()}');

        return {
          'id': boleta.id,
          ...boletaData
        };
      } else {
        print('❌ [BoletaService] NO SE ENCONTRÓ NINGUNA BOLETA');
        print('💡 [BoletaService] Posibles causas:');
        print('   - El código "$codigoBoleta" no existe en la base de datos');
        print('   - Hay diferencias de mayúsculas/minúsculas');
        print('   - El campo en Firestore se llama diferente a "codigoBoleta"');
        print('   - La boleta fue eliminada');
        return null;
      }
    } catch (e) {
      print('❌ [BoletaService] ERROR en la búsqueda: $e');
      print('📋 [BoletaService] Tipo de error: ${e.runtimeType}');

      // Detalles específicos para errores comunes de Firestore
      if (e is FirebaseException) {
        print('🔥 [BoletaService] FirebaseException:');
        print('   - Código: ${e.code}');
        print('   - Mensaje: ${e.message}');
        print('   - Stack: ${e.stackTrace}');
      }

      return null;
    }
  }
}