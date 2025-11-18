import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'mascotaservice.dart';
import 'transaccionesservice.dart'; // Importa el nuevo servicio

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final MascotaService mascotaService = MascotaService();
  final TransaccionesService transaccionesService = TransaccionesService(); // Nuevo servicio

  User? get currentUser => firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password
    );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String nombre,
    required String dni,
    required String telefono,
    required DateTime fechaNacimiento,
  }) async {
    try {
      final UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      final String userId = userCredential.user!.uid;

      await firestore
          .collection('users')
          .doc(userId)
          .set({
        'email': email,
        'nombre': nombre,
        'dni': dni,
        'telefono': telefono,
        'fechaNacimiento': fechaNacimiento,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': userId,
      });

      await mascotaService.crearMascotaParaUsuario(userId);

      return userCredential;
    } catch (e) {
      if (firebaseAuth.currentUser != null) {
        await firebaseAuth.currentUser!.delete();
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<DocumentSnapshot> getMascotaDelUsuario() async {
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }
    return await mascotaService.getMascotaByUserId(currentUser!.uid);
  }

  // NUEVO MÉTODO: Aumentar energía por atrapar basura
  Future<void> aumentarEnergiaPorBasura() async {
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }

    final userId = currentUser!.uid;

    await transaccionesService.crearTransaccionYActualizarMascota(
      userId: userId,
      tipoCredito: 'energia',
      cantidad: 15,
      tipoMovimiento: 'aumento',
      descripcion: 'Energía obtenida por atrapar basura correctamente',
    );
  }
}