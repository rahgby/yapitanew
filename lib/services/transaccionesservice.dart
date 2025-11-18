import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TransaccionesService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Crear una transacción y actualizar la mascota
  Future<void> crearTransaccionYActualizarMascota({
    required String userId,
    required String tipoCredito, // 'energia', 'puntos', 'cashback'
    required int cantidad,
    required String tipoMovimiento, // 'aumento', 'perdida'
    required String descripcion,
  }) async {
    try {
      // Obtener la mascota del usuario
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