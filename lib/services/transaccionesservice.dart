import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TransaccionesService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Crear una transacción y actualizar la mascota
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
        'estado': 1, // Default 1
        'tipoCredito': tipoCredito,
        'cantidad': cantidad,
        'tipoMovimiento': tipoMovimiento,
        'descripcion': descripcion,
        'userId': userId,
        'mascotaId': mascotaDoc.id,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      // Actualizar la mascota
      await mascotaRef.update({
        tipoCredito: nuevoValor,
      });

      print('Transacción creada y mascota actualizada exitosamente');
    } catch (e) {
      print('Error en crearTransaccionYActualizarMascota: $e');
      rethrow;
    }
  }

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

        print('📊 DATOS EN TRANSACCIÓN - Energía: $energiaActual, Puntos: $puntosActual');

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

        print('✅ TRANSACCIÓN COMPLETADA DENTRO DE RUNTRANSACTION');
      });

      print('✅ TRANSACCIÓN DE CHATBOT COMPLETADA: -5 energía, +5 puntos');
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
}