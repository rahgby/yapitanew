import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nuevoyapita/services/procesamiento_service.dart';
import 'package:nuevoyapita/services/transferencia_service.dart';
import 'mascotaservice.dart';
import 'transaccionesservice.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final MascotaService mascotaService = MascotaService();
  final TransaccionesService transaccionesService = TransaccionesService();
  final TransferenciaService transferenciaService = TransferenciaService();
  final ProcesamientoService procesamientoService = ProcesamientoService();

  User? get currentUser => firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  // 🔽 CONSTRUCTOR CON INICIALIZACIÓN DE SERVICIOS
  AuthService() {
    _iniciarServicios();
  }

  // 🔽 INICIAR SERVICIOS EN BACKGROUND
  void _iniciarServicios() {
    // Iniciar verificación periódica de expiraciones de códigos de descuento
    transferenciaService.iniciarVerificacionPeriodica();
    print('✅ [AuthService] Servicios de expiración iniciados');
  }

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

  // En AuthService - agregar este método
  Future<void> actualizarNombreMascota(String nuevoNombre) async {
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      final mascotaSnapshot = await getMascotaDelUsuario();
      if (mascotaSnapshot.exists) {
        final mascotaId = mascotaSnapshot.id;
        await mascotaService.actualizarNombreMascota(mascotaId, nuevoNombre);
      }
    } catch (e) {
      print('❌ Error en AuthService.actualizarNombreMascota: $e');
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

  // 🔽 MÉTODO MEJORADO: Transacción para usar el chatbot con mejor logging
  Future<bool> transaccionChatbot() async {
    print('🔄 INICIANDO transaccionChatbot...');

    if (currentUser == null) {
      print('❌ ERROR: Usuario no autenticado');
      return false;
    }

    final userId = currentUser!.uid;
    print('🔍 Usuario actual: $userId');

    try {
      // Primero verificamos si tiene suficiente energía
      print('📋 Obteniendo mascota del usuario...');
      final mascotaSnapshot = await getMascotaDelUsuario();

      if (mascotaSnapshot.exists) {
        final mascotaData = mascotaSnapshot.data() as Map<String, dynamic>;
        final energiaActual = mascotaData['energia'] ?? 0;
        final mascotaId = mascotaSnapshot.id;

        print('📊 DATOS MASCOTA - ID: $mascotaId, Energía: $energiaActual, Tipo: ${energiaActual.runtimeType}');

        if (energiaActual < 5) {
          print('❌ ENERGÍA INSUFICIENTE: Tiene $energiaActual, necesita 5');
          return false;
        }

        print('✅ ENERGÍA SUFICIENTE: Procediendo con transacción...');

        // Realizar la transacción (restar 5 energía, sumar 5 puntos)
        print('🔄 Llamando a crearTransaccionChatbot...');
        await transaccionesService.crearTransaccionChatbot(
          userId: userId,
          mascotaId: mascotaId,
        );

        print('✅ TRANSACCIÓN EXITOSA');
        return true;
      } else {
        print('❌ ERROR: No se encontró mascota para el usuario');
        return false;
      }
    } catch (e) {
      print('❌ ERROR CRÍTICO en transaccionChatbot: $e');
      print('🔍 Stack trace: ${e.toString()}');
      return false;
    }
  }


  // En AuthService - agregar estos métodos
  Future<List<Map<String, dynamic>>> obtenerAtuendosDisponibles() async {
    return await transaccionesService.obtenerAtuendosDisponibles();
  }

  Future<List<Map<String, dynamic>>> obtenerAtuendosMascota() async {
    if (currentUser == null) throw Exception('Usuario no autenticado');

    final mascotaSnapshot = await getMascotaDelUsuario();
    if (!mascotaSnapshot.exists) throw Exception('Mascota no encontrada');

    return await transaccionesService.obtenerAtuendosMascota(mascotaSnapshot.id);
  }

  Future<void> comprarAtuendo(String atuendoId, int valor) async {
    if (currentUser == null) throw Exception('Usuario no autenticado');

    final mascotaSnapshot = await getMascotaDelUsuario();
    if (!mascotaSnapshot.exists) throw Exception('Mascota no encontrada');

    await transaccionesService.comprarAtuendo(
      userId: currentUser!.uid,
      mascotaId: mascotaSnapshot.id,
      atuendoId: atuendoId,
      valor: valor,
    );
  }

  Future<void> equiparAtuendo(String atuendoId) async {
    if (currentUser == null) throw Exception('Usuario no autenticado');

    final mascotaSnapshot = await getMascotaDelUsuario();
    if (!mascotaSnapshot.exists) throw Exception('Mascota no encontrada');

    await transaccionesService.equiparAtuendo(
      mascotaId: mascotaSnapshot.id,
      atuendoId: atuendoId,
    );
  }

  Future<void> forzarVerificacionExpiraciones() async {
    await transferenciaService.forzarVerificacionExpiraciones();
  }
  // Método temporal para debugging
  Future<void> debugForzarEnergia(int energia) async {
    if (currentUser == null) return;

    try {
      final mascotaSnapshot = await getMascotaDelUsuario();
      if (mascotaSnapshot.exists) {
        await firestore
            .collection('mascotas')
            .doc(mascotaSnapshot.id)
            .update({
          'energia': energia,
        });
        print('✅ Energía forzada a $energia para debugging');
      }
    } catch (e) {
      print('❌ Error al forzar energía: $e');
    }
  }
}