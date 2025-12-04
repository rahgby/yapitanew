import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'authlayout.dart';
import 'const.dart';
import 'firebase_options.dart';
import 'setup_atuendos.dart';

void main() async {
  Gemini.init(
    apiKey: GEMINI_API_KEY,
  );
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔽 INICIALIZACIÓN DE ATUENDOS - EJECUTAR SOLO UNA VEZ
  await _inicializarFirestore();

  runApp(const MyApp());
}

// 🔽 FUNCIÓN MEJORADA CON MÁS DETALLES EN CONSOLE LOG
Future<void> _inicializarFirestore() async {
  try {
    final setup = SetupAtuendos();

    // Verificar si los atuendos ya existen para no duplicar
    final atuendosExisten = await setup.verificarAtuendosExisten();

    if (!atuendosExisten) {
      print('🔄 Inicializando estructura de atuendos...');
      await setup.inicializarAtuendos();
      print('✅ Estructura de atuendos inicializada exitosamente');
    } else {
      print('✅ Los atuendos ya existen en Firestore');

      // 🔽 NUEVO: OBTENER Y MOSTRAR LISTA DE ATUENDOS EXISTENTES
      await _mostrarAtuendosExistentes();
    }
  } catch (e) {
    print('❌ Error en inicialización de atuendos: $e');
    // No interrumpimos el flujo de la app si hay error
  }
}

// 🔽 NUEVA FUNCIÓN PARA MOSTRAR ATUENDOS EXISTENTES
Future<void> _mostrarAtuendosExistentes() async {
  try {
    final setup = SetupAtuendos();

    // Obtener todos los atuendos de Firestore
    final atuendosSnapshot = await FirebaseFirestore.instance
        .collection('atuendos')
        .get();

    print('📋 LISTA DE ATUENDOS EXISTENTES EN FIRESTORE:');
    print('==============================================');

    if (atuendosSnapshot.docs.isEmpty) {
      print('   No se encontraron atuendos');
      return;
    }

    for (final doc in atuendosSnapshot.docs) {
      final data = doc.data();
      print('   🎨 Atuendo: ${data['tituloSkin']}');
      print('      ID: ${doc.id}');
      print('      Valor: ${data['valor']} puntos');
      print('      Imagen: ${data['imagen']}');
      print('      Estado: ${data['estado']}');
      if (data['fechaCreacion'] != null) {
        print('      Creado: ${data['fechaCreacion'].toDate()}');
      }
      print('   ──────────────────────────────────────────');
    }

    print('📊 TOTAL: ${atuendosSnapshot.docs.length} atuendos encontrados');

  } catch (e) {
    print('❌ Error al obtener lista de atuendos: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthLayout(),
    );
  }
}