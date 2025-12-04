import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TransaccionesService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // 🔽 MÉTODO ACTUALIZADO: Verificar y actualizar nivel basado en puntos
  Future<Map<String, dynamic>> _verificarYActualizarNivel({
    required String mascotaId,
    required int nuevosPuntos,
    required int nivelActual,
  }) async {
    print('🔄 Verificando nivel - Puntos: $nuevosPuntos, Nivel actual: $nivelActual');

    // Calcular nuevo nivel (cada 100 puntos = 1 nivel)
    final nuevoNivel = nuevosPuntos ~/ 100;

    print('📊 Cálculo de nivel: $nuevosPuntos puntos / 100 = nivel $nuevoNivel');

    if (nuevoNivel > nivelActual) {
      print('🎉 ¡SUBIDA DE NIVEL! De $nivelActual a $nuevoNivel');

      // Actualizar nivel en la mascota
      await firestore.collection('mascotas').doc(mascotaId).update({
        'nivel': nuevoNivel,
      });

      // Crear transacción de subida de nivel
      final transaccionNivelDoc = firestore.collection('transacciones').doc();
      await transaccionNivelDoc.set({
        'id': transaccionNivelDoc.id,
        'estado': 1,
        'tipoCredito': 'nivel',
        'cantidad': nuevoNivel - nivelActual, // Cantidad de niveles subidos
        'tipoMovimiento': 'aumento',
        'descripcion': '¡Subida de nivel! De nivel $nivelActual a $nuevoNivel',
        'userId': await _getUserIdFromMascota(mascotaId),
        'mascotaId': mascotaId,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      return {
        'nivelSubido': true,
        'nivelAnterior': nivelActual,
        'nuevoNivel': nuevoNivel,
        'puntosRestantes': nuevosPuntos, // Los puntos se mantienen
      };
    }

    return {'nivelSubido': false};
  }

  // 🔽 MÉTODO AUXILIAR: Obtener userId desde mascotaId
  Future<String> _getUserIdFromMascota(String mascotaId) async {
    final mascotaDoc = await firestore.collection('mascotas').doc(mascotaId).get();
    return mascotaDoc['userId'];
  }

  // 🔽 MÉTODO ACTUALIZADO: Crear transacción y actualizar mascota CON SISTEMA DE NIVELES
  Future<void> crearTransaccionYActualizarMascota({
    required String userId,
    required String tipoCredito, // 'energia', 'puntos', 'cashback'
    required int cantidad,
    required String tipoMovimiento,
    required String descripcion,
  }) async {
    try {
      final mascotaQuery = await firestore
          .collection('mascotas')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (mascotaQuery.docs.isEmpty) {
        throw Exception('No se encontró mascota para el usuario');
      }

      final mascotaDoc = mascotaQuery.docs.first;
      final mascotaData = mascotaDoc.data();
      final mascotaRef = mascotaDoc.reference;
      final mascotaId = mascotaDoc.id;

      // Calcular nuevo valor según el tipo de movimiento
      int nuevoValor;
      final valorActual = mascotaData[tipoCredito] ?? 0;

      if (tipoMovimiento == 'aumento') {
        nuevoValor = valorActual + cantidad;
      } else if (tipoMovimiento == 'perdida') {
        nuevoValor = valorActual - cantidad;
        if (nuevoValor < 0) nuevoValor = 0;
      } else {
        throw Exception('Tipo de movimiento no válido');
      }

      // Crear la transacción
      final transaccionDoc = firestore.collection('transacciones').doc();
      await transaccionDoc.set({
        'id': transaccionDoc.id,
        'estado': 1,
        'tipoCredito': tipoCredito,
        'cantidad': cantidad,
        'tipoMovimiento': tipoMovimiento,
        'descripcion': descripcion,
        'userId': userId,
        'mascotaId': mascotaId,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      // Actualizar la mascota
      await mascotaRef.update({
        tipoCredito: nuevoValor,
      });

      // 🔽 VERIFICAR SUBIDA DE NIVEL SI ES QUE SE AUMENTARON PUNTOS
      if (tipoCredito == 'puntos' && tipoMovimiento == 'aumento') {
        final nivelActual = mascotaData['nivel'] ?? 0;
        await _verificarYActualizarNivel(
          mascotaId: mascotaId,
          nuevosPuntos: nuevoValor,
          nivelActual: nivelActual,
        );
      }

      print('Transacción creada y mascota actualizada exitosamente');
    } catch (e) {
      print('Error en crearTransaccionYActualizarMascota: $e');
      rethrow;
    }
  }

  // 🔽 MÉTODO ACTUALIZADO: Crear transacción chatbot CON SISTEMA DE NIVELES
  Future<void> crearTransaccionChatbot({
    required String userId,
    required String mascotaId,
  }) async {
    print('🔄 INICIANDO crearTransaccionChatbot...');
    print('🔍 Parámetros - userId: $userId, mascotaId: $mascotaId');

    try {
      final mascotaRef = firestore.collection('mascotas').doc(mascotaId);

      // Usar una transacción de Firestore para asegurar consistencia
      await firestore.runTransaction((transaction) async {
        print('📋 Obteniendo datos de mascota...');

        // Obtener datos actuales de la mascota
        final mascotaDoc = await transaction.get(mascotaRef);
        if (!mascotaDoc.exists) {
          throw Exception('Mascota no encontrada con ID: $mascotaId');
        }

        final mascotaData = mascotaDoc.data()!;
        final energiaActual = mascotaData['energia'] ?? 0;
        final puntosActual = mascotaData['puntos'] ?? 0;
        final nivelActual = mascotaData['nivel'] ?? 0;

        print('📊 DATOS MASCOTA - Energía: $energiaActual, Puntos: $puntosActual, Nivel: $nivelActual');

        // Verificar que tenga suficiente energía
        if (energiaActual < 5) {
          throw Exception('Energía insuficiente para usar el chatbot. Tiene: $energiaActual, Necesita: 5');
        }

        // Calcular nuevos valores
        final nuevaEnergia = energiaActual - 5;
        final nuevosPuntos = puntosActual + 5;

        print('🔄 CALCULANDO - Nueva energía: $nuevaEnergia, Nuevos puntos: $nuevosPuntos');

        // Actualizar mascota
        print('📝 Actualizando mascota en Firestore...');
        transaction.update(mascotaRef, {
          'energia': nuevaEnergia,
          'puntos': nuevosPuntos,
        });

        // Crear transacción de energía (pérdida)
        final transaccionEnergiaDoc = firestore.collection('transacciones').doc();
        transaction.set(transaccionEnergiaDoc, {
          'id': transaccionEnergiaDoc.id,
          'estado': 1,
          'tipoCredito': 'energia',
          'cantidad': 5,
          'tipoMovimiento': 'perdida',
          'descripcion': 'Energía utilizada para consultar en el chatbot',
          'userId': userId,
          'mascotaId': mascotaId,
          'fechaCreacion': FieldValue.serverTimestamp(),
        });

        // Crear transacción de puntos (aumento)
        final transaccionPuntosDoc = firestore.collection('transacciones').doc();
        transaction.set(transaccionPuntosDoc, {
          'id': transaccionPuntosDoc.id,
          'estado': 1,
          'tipoCredito': 'puntos',
          'cantidad': 5,
          'tipoMovimiento': 'aumento',
          'descripcion': 'Puntos ganados por usar el chatbot',
          'userId': userId,
          'mascotaId': mascotaId,
          'fechaCreacion': FieldValue.serverTimestamp(),
        });

        // 🔽 VERIFICAR SUBIDA DE NIVEL DESPUÉS DE LA TRANSACCIÓN
        final nuevoNivel = nuevosPuntos ~/ 100;
        if (nuevoNivel > nivelActual) {
          print('🎉 ¡SUBIDA DE NIVEL DENTRO DE TRANSACCIÓN! De $nivelActual a $nuevoNivel');

          transaction.update(mascotaRef, {
            'nivel': nuevoNivel,
          });

          // Crear transacción de nivel
          final transaccionNivelDoc = firestore.collection('transacciones').doc();
          transaction.set(transaccionNivelDoc, {
            'id': transaccionNivelDoc.id,
            'estado': 1,
            'tipoCredito': 'nivel',
            'cantidad': nuevoNivel - nivelActual,
            'tipoMovimiento': 'aumento',
            'descripcion': '¡Subida de nivel por acumulación de puntos! De nivel $nivelActual a $nuevoNivel',
            'userId': userId,
            'mascotaId': mascotaId,
            'fechaCreacion': FieldValue.serverTimestamp(),
          });
        }

        print('✅ TRANSACCIÓN COMPLETADA DENTRO DE RUNTRANSACTION');
      });

      print('✅ TRANSACCIÓN DE CHATBOT COMPLETADA: -5 energía, +5 puntos + verificación de nivel');
    } catch (e) {
      print('❌ ERROR CRÍTICO en crearTransaccionChatbot: $e');
      print('🔍 Stack trace completo: ${e.toString()}');
      rethrow;
    }
  }

  // Obtener transacciones por usuario
  Future<QuerySnapshot> getTransaccionesByUserId(String userId) async {
    try {
      return await firestore
          .collection('transacciones')
          .where('userId', isEqualTo: userId)
          .orderBy('fechaCreacion', descending: true)
          .get();
    } catch (e) {
      print('Error al obtener transacciones: $e');
      rethrow;
    }
  }

  // 🔽 MÉTODOS PARA MANEJAR ATUENDOS EN TRANSACCIONESSERVICE
  Future<void> comprarAtuendo({
    required String userId,
    required String mascotaId,
    required String atuendoId,
    required int valor,
  }) async {
    try {
      // Verificar si la mascota ya tiene el atuendo
      final atuendoExistente = await firestore
          .collection('mascota_atuendo')
          .where('mascotaId', isEqualTo: mascotaId)
          .where('atuendoId', isEqualTo: atuendoId)
          .get();

      if (atuendoExistente.docs.isNotEmpty) {
        throw Exception('Ya tienes este atuendo');
      }

      // Verificar puntos suficientes
      final mascotaDoc = await firestore.collection('mascotas').doc(mascotaId).get();
      final puntosActuales = mascotaDoc['puntos'] ?? 0;

      if (puntosActuales < valor) {
        throw Exception('Puntos insuficientes');
      }

      // Usar transacción para asegurar consistencia
      await firestore.runTransaction((transaction) async {
        // Restar puntos
        final nuevosPuntos = puntosActuales - valor;
        transaction.update(firestore.collection('mascotas').doc(mascotaId), {
          'puntos': nuevosPuntos,
        });

        // Crear relación mascota-atuendo
        final relacionDoc = firestore.collection('mascota_atuendo').doc();
        transaction.set(relacionDoc, {
          'id': relacionDoc.id,
          'mascotaId': mascotaId,
          'atuendoId': atuendoId,
          'habilitado': true,
          'enUso': false,
          'fechaAdquisicion': FieldValue.serverTimestamp(),
        });

        // Crear transacción de compra
        final transaccionDoc = firestore.collection('transacciones').doc();
        transaction.set(transaccionDoc, {
          'id': transaccionDoc.id,
          'estado': 1,
          'tipoCredito': 'puntos',
          'cantidad': valor,
          'tipoMovimiento': 'perdida',
          'descripcion': 'Compra de atuendo',
          'userId': userId,
          'mascotaId': mascotaId,
          'atuendoId': atuendoId,
          'fechaCreacion': FieldValue.serverTimestamp(),
        });
      });

      print('✅ Atuendo comprado exitosamente');
    } catch (e) {
      print('❌ Error al comprar atuendo: $e');
      rethrow;
    }
  }

  Future<void> equiparAtuendo({
    required String mascotaId,
    required String atuendoId,
  }) async {
    try {
      // Verificar que el atuendo esté habilitado para la mascota
      final atuendoHabilitado = await firestore
          .collection('mascota_atuendo')
          .where('mascotaId', isEqualTo: mascotaId)
          .where('atuendoId', isEqualTo: atuendoId)
          .where('habilitado', isEqualTo: true)
          .get();

      if (atuendoHabilitado.docs.isEmpty) {
        throw Exception('Atuendo no disponible para esta mascota');
      }

      // Usar transacción para asegurar consistencia
      await firestore.runTransaction((transaction) async {
        // Quitar enUso de todos los atuendos de la mascota
        final todosAtuendos = await firestore
            .collection('mascota_atuendo')
            .where('mascotaId', isEqualTo: mascotaId)
            .get();

        for (final doc in todosAtuendos.docs) {
          transaction.update(doc.reference, {'enUso': false});
        }

        // Poner enUso al atuendo seleccionado
        transaction.update(atuendoHabilitado.docs.first.reference, {'enUso': true});

        // Actualizar la mascota con el atuendo equipado
        final atuendoDoc = await firestore.collection('atuendos').doc(atuendoId).get();
        final imagenAtuendo = atuendoDoc['imagen'];

        transaction.update(firestore.collection('mascotas').doc(mascotaId), {
          'atuendoEquipado': imagenAtuendo,
        });
      });

      print('✅ Atuendo equipado exitosamente');
    } catch (e) {
      print('❌ Error al equipar atuendo: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerAtuendosDisponibles() async {
    try {
      final atuendosSnapshot = await firestore
          .collection('atuendos')
          .where('estado', isEqualTo: 1)
          .get();

      return atuendosSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'tituloSkin': data['tituloSkin'],
          'valor': data['valor'],
          'imagen': data['imagen'],
          'fechaCreacion': data['fechaCreacion'],
        };
      }).toList();
    } catch (e) {
      print('❌ Error al obtener atuendos: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> obtenerAtuendosMascota(String mascotaId) async {
    try {
      final atuendosMascotaSnapshot = await firestore
          .collection('mascota_atuendo')
          .where('mascotaId', isEqualTo: mascotaId)
          .where('habilitado', isEqualTo: true)
          .get();

      final atuendosMascota = <Map<String, dynamic>>[];

      for (final doc in atuendosMascotaSnapshot.docs) {
        final data = doc.data();
        final atuendoId = data['atuendoId'];

        // Obtener información del atuendo
        final atuendoDoc = await firestore.collection('atuendos').doc(atuendoId).get();
        if (atuendoDoc.exists) {
          final atuendoData = atuendoDoc.data()!;
          atuendosMascota.add({
            'id': doc.id,
            'atuendoId': atuendoId,
            'tituloSkin': atuendoData['tituloSkin'],
            'imagen': atuendoData['imagen'],
            'enUso': data['enUso'] ?? false,
            'fechaAdquisicion': data['fechaAdquisicion'],
          });
        }
      }

      return atuendosMascota;
    } catch (e) {
      print('❌ Error al obtener atuendos de mascota: $e');
      return [];
    }
  }
  // 🔽 NUEVO MÉTODO: Obtener historial de transacciones con filtro por tipo
  Future<QuerySnapshot> getTransaccionesConFiltro({
    required String userId,
    String? tipoCredito,
  }) async {
    try {
      Query query = firestore
          .collection('transacciones')
          .where('userId', isEqualTo: userId)
          .orderBy('fechaCreacion', descending: true);

      if (tipoCredito != null) {
        query = query.where('tipoCredito', isEqualTo: tipoCredito);
      }

      return await query.get();
    } catch (e) {
      print('Error al obtener transacciones filtradas: $e');
      rethrow;
    }
  }
}