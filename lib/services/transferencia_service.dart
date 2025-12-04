// transferencia_service.dart - VERSIÓN CON SINGLETON
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'mascotaservice.dart';

class TransferenciaService {
  // 🔥 SINGLETON: Solo una instancia en toda la app
  static final TransferenciaService _instance = TransferenciaService._internal();
  factory TransferenciaService() => _instance;
  TransferenciaService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final MascotaService _mascotaService = MascotaService();
  Timer? _timerVerificacion;

  // 🔥 MÉTODO MEJORADO: Verificar expiraciones con logs detallados
  Future<void> verificarYProcesarExpiraciones() async {
    try {
      print('🕒 [${DateTime.now()}] Verificando expiraciones...');

      final ahora = Timestamp.now();
      print('⏰ Timestamp actual: ${ahora.toDate()}');

      // 🔥 CONSULTA SIMPLIFICADA: Buscar TODAS las transferencias de tipo "menos"
      final query = await _firestore
          .collection('transferencias')
          .where('tipo', isEqualTo: 'menos')
          .get();

      print('📦 Total de transferencias tipo "menos": ${query.docs.length}');

      // 🔥 FILTRAR MANUALMENTE las que están expiradas
      int procesadas = 0;
      for (final doc in query.docs) {
        final data = doc.data();
        final disponible = data['disponible'] ?? false;
        final canjeado = data['canjeado'] ?? false;
        final expirado = data['expirado'] ?? false;
        final fechaExpiracion = data['fechaExpiracion'] as Timestamp?;

        if (fechaExpiracion == null) continue;

        final estaExpirado = ahora.toDate().isAfter(fechaExpiracion.toDate());

        print('📋 Código: ${data['codigoDescuento']}');
        print('   ├─ Disponible: $disponible');
        print('   ├─ Canjeado: $canjeado');
        print('   ├─ Expirado: $expirado');
        print('   ├─ Expira: ${fechaExpiracion.toDate()}');
        print('   └─ Está expirado: $estaExpirado');

        // 🔥 CONDICIÓN CORRECTA: Procesar si está expirado y no ha sido procesado
        if (estaExpirado && disponible && !canjeado && !expirado) {
          print('🚨 PROCESANDO código expirado: ${data['codigoDescuento']}');
          await _devolverCashbackExpirado(doc);
          procesadas++;
        }
      }

      if (procesadas > 0) {
        print('✅ Se procesaron $procesadas transferencias expiradas');
      } else {
        print('ℹ️ No hay transferencias expiradas para procesar');
      }

    } catch (e, stackTrace) {
      print('❌ ERROR en verificarYProcesarExpiraciones: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // 🔥 MÉTODO MEJORADO: Devolver cashback con transacción segura
  Future<void> _devolverCashbackExpirado(QueryDocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final transferenciaId = doc.id;
      final codigoDescuento = data['codigoDescuento'];

      print('💰 [Devolución] Iniciando para código: $codigoDescuento');

      // 🔥 VERIFICACIÓN DOBLE: Leer el documento nuevamente para evitar race conditions
      final docActual = await doc.reference.get();
      final dataActual = docActual.data() as Map<String, dynamic>;

      if (dataActual['expirado'] == true || dataActual['canjeado'] == true) {
        print('⚠️ Código ya procesado, saltando...');
        return;
      }

      final monto = (data['montoTransferencia'] as num).toDouble();
      final mascotaId = data['mascotaId'];
      final userId = data['userId'];

      print('💵 Monto a devolver: \$$monto');

      // 🔥 PASO 1: Marcar como expirado PRIMERO (evita doble procesamiento)
      await doc.reference.update({
        'disponible': false,
        'expirado': true,
        'fechaDevolucion': FieldValue.serverTimestamp(),
      });
      print('✅ Transferencia marcada como expirada');

      // 🔥 PASO 2: Devolver cashback
      final cashbackActual = await _mascotaService.obtenerCashbackActual(mascotaId);
      final nuevoCashback = cashbackActual + monto;

      await _mascotaService.actualizarCashbackMascota(mascotaId, nuevoCashback);
      print('✅ Cashback actualizado: $cashbackActual → $nuevoCashback');

      // 🔥 PASO 3: Registrar transacción de devolución
      final transaccionId = _uuid.v4();
      await _firestore.collection('transacciones').doc(transaccionId).set({
        'id': transaccionId,
        'estado': 1,
        'tipoCredito': 'cashback',
        'cantidad': monto,
        'tipoMovimiento': 'aumento',
        'descripcion': 'Devolución por código expirado: $codigoDescuento',
        'userId': userId,
        'mascotaId': mascotaId,
        'transferenciaId': transferenciaId,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      // 🔥 PASO 4: Crear transferencia de tipo "mas"
      final transferenciaDevolucionId = _uuid.v4();
      await _firestore.collection('transferencias').doc(transferenciaDevolucionId).set({
        'idTransferencia': transferenciaDevolucionId,
        'montoTransferencia': monto,
        'tipo': 'mas',
        'codigoDevolucion': 'DEV_$codigoDescuento',
        'estado': 1,
        'disponible': false,
        'userId': userId,
        'mascotaId': mascotaId,
        'fechaCreacion': FieldValue.serverTimestamp(),
        'descripcion': 'Devolución automática por expiración',
        'transferenciaOrigenId': transferenciaId,
      });

      print('🎉 DEVOLUCIÓN COMPLETADA exitosamente');

    } catch (e, stackTrace) {
      print('❌ ERROR en _devolverCashbackExpirado: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // 🔥 MÉTODO MEJORADO: Iniciar verificación con control del timer
  void iniciarVerificacionPeriodica() {
    // Cancelar timer anterior si existe
    _timerVerificacion?.cancel();

    print('🚀 [TransferenciaService] Iniciando verificación periódica...');

    // Ejecutar inmediatamente
    verificarYProcesarExpiraciones();

    // Ejecutar cada 10 segundos
    _timerVerificacion = Timer.periodic(Duration(seconds: 10), (timer) {
      verificarYProcesarExpiraciones();
    });

    print('✅ [TransferenciaService] Timer configurado (cada 10 segundos)');
  }

  // 🔥 NUEVO: Detener verificación periódica
  void detenerVerificacionPeriodica() {
    _timerVerificacion?.cancel();
    _timerVerificacion = null;
    print('🛑 Verificación periódica detenida');
  }

  // 🔥 MÉTODO DE TESTING: Forzar verificación manual
  Future<void> forzarVerificacionExpiraciones() async {
    print('🚨 FORZANDO VERIFICACIÓN MANUAL');
    await verificarYProcesarExpiraciones();
  }

  // ========== RESTO DE MÉTODOS ==========

  Future<Map<String, dynamic>> crearTransferenciaDescuento({
    required String userId,
    required String mascotaId,
    required double monto,
  }) async {
    try {
      final transferenciaId = _uuid.v4();
      final codigoDescuento = _generarCodigoDescuento();
      final fechaCreacion = DateTime.now();
      final fechaExpiracion = fechaCreacion.add(Duration(minutes: 3));

      print('🕒 Creando código - Expira: $fechaExpiracion');

      await _firestore.collection('transferencias').doc(transferenciaId).set({
        'idTransferencia': transferenciaId,
        'montoTransferencia': monto,
        'tipo': 'menos',
        'codigoDescuento': codigoDescuento,
        'estado': 1,
        'disponible': true,
        'canjeado': false,
        'userId': userId,
        'mascotaId': mascotaId,
        'fechaCreacion': Timestamp.fromDate(fechaCreacion),
        'fechaExpiracion': Timestamp.fromDate(fechaExpiracion),
        'expirado': false,
      });

      print('✅ Código creado: $codigoDescuento - Monto: \$$monto');

      return {
        'exito': true,
        'codigo': codigoDescuento,
        'monto': monto,
        'transferenciaId': transferenciaId,
        'fechaExpiracion': fechaExpiracion,
      };
    } catch (e) {
      print('❌ Error creando transferencia: $e');
      return {'exito': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> canjearCodigoDescuento({
    required String codigoDescuento,
    required String codigoBoleta,
    required double montoBoleta,
  }) async {
    try {
      print('🎫 Canjeando código: $codigoDescuento');

      // Verificar expiraciones antes de canjear
      await verificarYProcesarExpiraciones();

      final query = await _firestore
          .collection('transferencias')
          .where('codigoDescuento', isEqualTo: codigoDescuento)
          .where('disponible', isEqualTo: true)
          .where('canjeado', isEqualTo: false)
          .where('expirado', isEqualTo: false)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return {
          'exito': false,
          'mensaje': 'Código no válido o ya utilizado'
        };
      }

      final transferenciaDoc = query.docs.first;
      final data = transferenciaDoc.data();

      // Verificar expiración
      final fechaExpiracion = data['fechaExpiracion'] as Timestamp;
      if (DateTime.now().isAfter(fechaExpiracion.toDate())) {
        await _devolverCashbackExpirado(transferenciaDoc);
        return {
          'exito': false,
          'mensaje': 'El código ha expirado'
        };
      }

      final montoDescuento = (data['montoTransferencia'] as num).toDouble();
      final userId = data['userId'];
      final mascotaId = data['mascotaId'];

      // Marcar como canjeado
      await transferenciaDoc.reference.update({
        'disponible': false,
        'canjeado': true,
        'fechaCanje': FieldValue.serverTimestamp(),
        'boletaAsociada': codigoBoleta,
        'montoBoletaAsociada': montoBoleta,
      });

      print('✅ Código canjeado exitosamente');

      return {
        'exito': true,
        'montoDescuento': montoDescuento,
        'mensaje': 'Descuento aplicado: -\$$montoDescuento',
        'transferenciaId': transferenciaDoc.id,
        'userId': userId,
        'mascotaId': mascotaId,
      };

    } catch (e) {
      print('❌ Error canjeando código: $e');
      return {
        'exito': false,
        'mensaje': 'Error al canjear: $e'
      };
    }
  }

  Future<Map<String, dynamic>> verificarCodigoDescuento(String codigoDescuento) async {
    try {
      await verificarYProcesarExpiraciones();

      final query = await _firestore
          .collection('transferencias')
          .where('codigoDescuento', isEqualTo: codigoDescuento)
          .where('disponible', isEqualTo: true)
          .where('canjeado', isEqualTo: false)
          .where('expirado', isEqualTo: false)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return {'valido': false, 'mensaje': 'Código no válido o ya utilizado'};
      }

      final transferencia = query.docs.first;
      final data = transferencia.data();

      final fechaExpiracion = data['fechaExpiracion'] as Timestamp;
      if (DateTime.now().isAfter(fechaExpiracion.toDate())) {
        await _devolverCashbackExpirado(transferencia);
        return {'valido': false, 'mensaje': 'Código expirado'};
      }

      return {
        'valido': true,
        'montoDescuento': (data['montoTransferencia'] as num).toDouble(),
        'mensaje': 'Código válido - Descuento: \$${data['montoTransferencia']}'
      };
    } catch (e) {
      return {'valido': false, 'mensaje': 'Error verificando código: $e'};
    }
  }

  String _generarCodigoDescuento() {
    final ahora = DateTime.now();
    final timestamp = ahora.millisecondsSinceEpoch;
    final random = _uuid.v4().substring(0, 4).toUpperCase();
    return 'DSC${timestamp.toString().substring(7)}${random}';
  }

  Future<QuerySnapshot> getTransferenciasDescuentoByUserId(String userId) async {
    return await _firestore
        .collection('transferencias')
        .where('userId', isEqualTo: userId)
        .where('tipo', isEqualTo: 'menos')
        .orderBy('fechaCreacion', descending: true)
        .get();
  }

  // MÉTODOS DE CASHBACK
  Future<void> crearTransferenciaCashback({
    required String userId,
    required String mascotaId,
    required String codigoBoleta,
    required double montoTotal,
    required double montoTransferencia,
    required String tipo,
  }) async {
    try {
      final transferenciaId = _uuid.v4();

      await _firestore.collection('transferencias').doc(transferenciaId).set({
        'idTransferencia': transferenciaId,
        'montoTotal': montoTotal,
        'montoTransferencia': montoTransferencia,
        'tipo': tipo,
        'codigoBoleta': codigoBoleta,
        'estado': 1,
        'userId': userId,
        'mascotaId': mascotaId,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      print('✅ Transferencia creada: ID $transferenciaId, Monto: \$$montoTransferencia');
    } catch (e) {
      print('❌ Error creando transferencia: $e');
      rethrow;
    }
  }

  Future<bool> boletaYaUsada(String codigoBoleta, String userId) async {
    try {
      final query = await _firestore
          .collection('transferencias')
          .where('codigoBoleta', isEqualTo: codigoBoleta)
          .where('userId', isEqualTo: userId)
          .where('estado', isEqualTo: 1)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error verificando boleta: $e');
      return false;
    }
  }

  Future<QuerySnapshot> getTransferenciasByUserId(String userId) async {
    return await _firestore
        .collection('transferencias')
        .where('userId', isEqualTo: userId)
        .orderBy('fechaCreacion', descending: true)
        .get();
  }

  Future<double> getTotalCashback(String userId) async {
    try {
      final query = await _firestore
          .collection('transference')
          .where('userId', isEqualTo: userId)
          .where('estado', isEqualTo: 1)
          .get();

      double total = 0.0;
      for (final doc in query.docs) {
        final data = doc.data();
        total += (data['montoTransferencia'] ?? 0).toDouble();
      }
      return total;
    } catch (e) {
      print('Error calculando total cashback: $e');
      return 0.0;
    }
  }
}