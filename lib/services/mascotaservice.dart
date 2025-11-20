import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MascotaService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Crear una nueva mascota para un usuario
  Future<void> crearMascotaParaUsuario(String userId) async {
    try {
      // Generar un ID único para la mascota
      final mascotaDoc = firestore.collection('mascotas').doc();
      final mascotaId = mascotaDoc.id;

      await mascotaDoc.set({
        'id': mascotaId,
        'estado': 1, // Default 1
        'nombre': 'Mascota$mascotaId', // Nombre por defecto
        'energia': 30, // Comienza con 30 para testing
        'puntos': 0, // Comienza en 0
        'cashback': 0, // Comienza en 0
        'nivel': 0, // Comienza en 0
        'fechaRegistro': FieldValue.serverTimestamp(),
        'userId': userId, // Relación con el usuario
      });

      print('Mascota creada exitosamente: $mascotaId');
    } catch (e) {
      print('Error al crear mascota: $e');
      rethrow;
    }
  }

  // Obtener mascota por usuario
  Future<DocumentSnapshot> getMascotaByUserId(String userId) async {
    try {
      print('🔍 Buscando mascota para usuario: $userId');

      final query = await firestore
          .collection('mascotas')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final mascota = query.docs.first;
        print('✅ Mascota encontrada: ${mascota.id}');
        return mascota;
      }

      print('❌ No se encontró mascota para este usuario: $userId');
      throw Exception('No se encontró mascota para este usuario');
    } catch (e) {
      print('❌ Error al obtener mascota: $e');
      rethrow;
    }
  }

  // Actualizar energía de la mascota
  Future<void> actualizarEnergiaMascota(String mascotaId, int nuevaEnergia) async {
    try {
      await firestore
          .collection('mascotas')
          .doc(mascotaId)
          .update({
        'energia': nuevaEnergia,
      });
    } catch (e) {
      print('Error al actualizar energía: $e');
      rethrow;
    }
  }
}