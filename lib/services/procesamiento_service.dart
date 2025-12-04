import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nuevoyapita/services/transferencia_service.dart';

import 'boleta_service.dart';
import 'mascotaservice.dart';

class ProcesamientoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TransferenciaService _transferenciaService = TransferenciaService();
  final MascotaService _mascotaService = MascotaService();

  // 🔽 MÉTODO PRINCIPAL: Procesar cashback completo
  Future<void> procesarCashbackCompleto({
    required String userId,
    required String codigoBoleta,
    required double montoTotal,
  }) async {
    try {
      print('🔄 Iniciando procesamiento de cashback...');

      // 1. Obtener mascota del usuario
      final mascotaQuery = await _firestore
          .collection('mascotas')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (mascotaQuery.docs.isEmpty) {
        throw Exception('No se encontró mascota para el usuario');
      }

      final mascotaDoc = mascotaQuery.docs.first;
      final mascotaId = mascotaDoc.id;
      final mascotaData = mascotaDoc.data() as Map<String, dynamic>;

      // 2. Calcular cashback (1% del monto total)
      final cashback = montoTotal * 0.01;
      final cashbackActual = (mascotaData['cashback'] ?? 0).toDouble();
      final nuevoCashback = cashbackActual + cashback;

      print('💰 Cashback calculado: \$${cashback.toStringAsFixed(2)}');
      print('💰 Cashback actual: \$${cashbackActual.toStringAsFixed(2)}');
      print('💰 Nuevo cashback: \$${nuevoCashback.toStringAsFixed(2)}');

      // 3. Crear transferencia en la nueva tabla
      await _transferenciaService.crearTransferenciaCashback(
        userId: userId,
        mascotaId: mascotaId,
        codigoBoleta: codigoBoleta,
        montoTotal: montoTotal,
        montoTransferencia: cashback,
        tipo: 'mas', // Por captura de basura
      );

      // 4. Actualizar cashback de la mascota
      await _mascotaService.actualizarCashbackMascota(mascotaId, nuevoCashback);

      // 5. Aumentar energía por captura de basura (método existente)
      await _aumentarEnergiaPorBasura(mascotaId, mascotaData);

      print('✅ Procesamiento completado exitosamente');
    } catch (e) {
      print('❌ Error en procesamiento completo: $e');
      rethrow;
    }
  }

  // 🔽 MÉTODO: Aumentar energía por captura de basura
  Future<void> _aumentarEnergiaPorBasura(String mascotaId, Map<String, dynamic> mascotaData) async {
    try {
      final energiaActual = mascotaData['energia'] ?? 0;
      final nuevaEnergia = energiaActual + 15;

      await _firestore
          .collection('mascotas')
          .doc(mascotaId)
          .update({
        'energia': nuevaEnergia,
      });

      print('⚡ Energía aumentada: +15 (Total: $nuevaEnergia)');
    } catch (e) {
      print('❌ Error aumentando energía: $e');
      // No rethrow para no interrumpir el flujo principal del cashback
    }
  }

  // 🔽 MÉTODO: Verificar si boleta es válida
  Future<Map<String, dynamic>> verificarBoleta(String codigoBoleta, String userId) async {
    try {
      print('🔄 [ProcesamientoService] Iniciando verificación de boleta...');
      print('👤 [ProcesamientoService] UserID: $userId');
      print('🎫 [ProcesamientoService] Código boleta: $codigoBoleta');

      final boletaService = BoletaService();

      // Verificar si boleta existe
      print('🔍 [ProcesamientoService] Llamando a buscarBoletaPorCodigo...');
      final boleta = await boletaService.buscarBoletaPorCodigo(codigoBoleta);

      if (boleta == null) {
        print('❌ [ProcesamientoService] BoletaService retornó null');
        return {'valida': false, 'mensaje': 'Boleta no encontrada'};
      }

      print('✅ [ProcesamientoService] Boleta encontrada, verificando si ya fue usada...');

      // Verificar si ya fue usada
      final yaUsada = await _transferenciaService.boletaYaUsada(codigoBoleta, userId);
      if (yaUsada) {
        print('❌ [ProcesamientoService] Boleta ya fue canjeada por este usuario');
        return {'valida': false, 'mensaje': 'Esta boleta ya fue canjeada'};
      }

      // Calcular cashback potencial
      final montoTotal = boleta['montoTotal'].toDouble();
      final cashbackPotencial = montoTotal * 0.01;

      print('💰 [ProcesamientoService] Cálculos completados:');
      print('   - Monto Total: \$$montoTotal');
      print('   - Cashback (1%): \$${cashbackPotencial.toStringAsFixed(2)}');

      return {
        'valida': true,
        'boleta': boleta,
        'montoTotal': montoTotal,
        'cashbackPotencial': cashbackPotencial,
        'mensaje': 'Boleta válida - Cashback: \$${cashbackPotencial.toStringAsFixed(2)}'
      };
    } catch (e) {
      print('❌ [ProcesamientoService] Error en verificarBoleta: $e');
      return {'valida': false, 'mensaje': 'Error verificando boleta: $e'};
    }
  }
}