// setup_atuendos.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SetupAtuendos {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔽 MÉTODO MEJORADO CON MÁS DETALLES
  Future<void> inicializarAtuendos() async {
    try {
      print('🔄 Inicializando estructura de atuendos en Firestore...');
      print('📝 Creando 4 atuendos predeterminados...');

      // Lista de atuendos predefinidos
      final List<Map<String, dynamic>> atuendos = [
        {
          'id': 'cocayapiya',
          'tituloSkin': 'CocaYapiya',
          'valor': 100,
          'imagen': 'cocayapiya.PNG',
          'fechaCreacion': FieldValue.serverTimestamp(),
          'estado': 1,
        },
        {
          'id': 'incayapiya',
          'tituloSkin': 'IncaYapiya',
          'valor': 100,
          'imagen': 'incayapiya.PNG',
          'fechaCreacion': FieldValue.serverTimestamp(),
          'estado': 1,
        },
        {
          'id': 'fantayapiya',
          'tituloSkin': 'FantaYapiya',
          'valor': 100,
          'imagen': 'fantayapiya.PNG',
          'fechaCreacion': FieldValue.serverTimestamp(),
          'estado': 1,
        },
        {
          'id': 'spriteyapiya',
          'tituloSkin': 'SpriteYapiya',
          'valor': 100,
          'imagen': 'spriteyapiya.PNG',
          'fechaCreacion': FieldValue.serverTimestamp(),
          'estado': 1,
        },
      ];

      // Crear cada atuendo en Firestore
      for (final atuendo in atuendos) {
        await _firestore
            .collection('atuendos')
            .doc(atuendo['id'])
            .set(atuendo);
        print('   ✅ Atuendo creado: ${atuendo['tituloSkin']} (${atuendo['id']})');
      }

      print('🎉 Estructura de atuendos inicializada exitosamente!');
      print('📊 Resumen:');
      print('   - CocaYapiya (cocayapiya) - 100 puntos');
      print('   - IncaYapiya (incayapiya) - 100 puntos');
      print('   - FantaYapiya (fantayapiya) - 100 puntos');
      print('   - SpriteYapiya (spriteyapiya) - 100 puntos');

    } catch (e) {
      print('❌ Error al inicializar atuendos: $e');
      rethrow;
    }
  }

  // 🔽 MÉTODO PARA VERIFICAR SI LOS ATUENDOS YA EXISTEN
  Future<bool> verificarAtuendosExisten() async {
    try {
      print('🔍 Verificando si los atuendos ya existen en Firestore...');
      final snapshot = await _firestore.collection('atuendos').limit(1).get();
      final existen = snapshot.docs.isNotEmpty;

      if (existen) {
        print('   ✅ Se encontraron atuendos existentes');
      } else {
        print('   ℹ️ No se encontraron atuendos existentes');
      }

      return existen;
    } catch (e) {
      print('❌ Error al verificar atuendos: $e');
      return false;
    }
  }

  // 🔽 NUEVO MÉTODO PARA OBTENER CONTEO EXACTO
  Future<int> obtenerCantidadAtuendos() async {
    try {
      final snapshot = await _firestore.collection('atuendos').get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}