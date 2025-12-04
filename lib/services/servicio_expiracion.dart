// servicio_expiracion.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nuevoyapita/services/mascotaservice.dart';

class ServicioExpiracion {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MascotaService _mascotaService = MascotaService();

  // Verificar y procesar transferencias expiradas
  Future<void> procesarExpiraciones() async {
    try {
      final ahora = Timestamp.now();

      final expiradas = await _firestore
          .collection('transferencias')
          .where('tipo', isEqualTo: 'menos')
          .where('disponible', isEqualTo: true)
          .where('fechaExpiracion', isLessThan: ahora)
          .get();

      for (final doc in expiradas.docs) {
        await _devolverCashbackExpirado(doc);
      }

      print('✅ Procesadas ${expiradas.docs.length} transferencias expiradas');
    } catch (e) {
      print('❌ Error procesando expiraciones: $e');
    }
  }

  Future<void> _devolverCashbackExpirado(QueryDocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final monto = data['montoTransferencia'].toDouble();
      final mascotaId = data['mascotaId'];

      // Obtener cashback actual de la mascota
      final cashbackActual = await _mascotaService.obtenerCashbackActual(mascotaId);
      final nuevoCashback = cashbackActual + monto;

      // Actualizar cashback de la mascota
      await _mascotaService.actualizarCashbackMascota(mascotaId, nuevoCashback);

      // Marcar transferencia como expirada
      await doc.reference.update({
        'disponible': false,
        'expirado': true,
        'fechaDevolucion': FieldValue.serverTimestamp(),
      });

      print('✅ Cashback devuelto: \$$monto a mascota $mascotaId');
    } catch (e) {
      print('❌ Error devolviendo cashback expirado: $e');
    }
  }
}