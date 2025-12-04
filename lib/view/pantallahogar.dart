import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nuevoyapita/services/authservice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nuevoyapita/utils/globalcolors.dart';
import 'package:nuevoyapita/view/pantalla_enviar_cashback.dart';
import 'chat_mascota_view.dart';
import '../authlayout.dart';

class PantallaHogar extends StatefulWidget {
  const PantallaHogar({super.key});

  @override
  _PantallaHogarState createState() => _PantallaHogarState();
}

class _PantallaHogarState extends State<PantallaHogar> {
  Map<String, dynamic>? _mascotaData;
  bool _cargando = true;
  StreamSubscription<DocumentSnapshot>? _mascotaSubscription;

  @override
  void initState() {
    super.initState();
    _cargarDatosMascota();
  }

  Future<void> _cargarDatosMascota() async {
    try {
      final mascotaSnapshot = await authService.value.getMascotaDelUsuario();

      if (mascotaSnapshot.exists) {
        setState(() {
          _mascotaData = mascotaSnapshot.data() as Map<String, dynamic>;
          _cargando = false;
        });

        _mascotaSubscription = FirebaseFirestore.instance
            .collection('mascotas')
            .doc(mascotaSnapshot.id)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            setState(() {
              _mascotaData = snapshot.data() as Map<String, dynamic>;
            });
          }
        });
      } else {
        setState(() {
          _cargando = false;
        });
        Get.snackbar(
          'Error',
          'No se encontró la mascota',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      setState(() {
        _cargando = false;
      });
      Get.snackbar(
        'Error',
        'Error al cargar los datos de la mascota: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  bool _estaDespierto() {
    if (_mascotaData == null) return false;
    final energia = _mascotaData!['energia'] ?? 0;
    return energia > 0;
  }

  String _obtenerNombreMascota() {
    return _mascotaData?['nombre'] ?? 'Mascota';
  }

  int _obtenerEnergia() {
    return _mascotaData?['energia'] ?? 0;
  }

  int _obtenerPuntos() {
    return _mascotaData?['puntos'] ?? 0;
  }

  double _obtenerCashback() {
    final cashback = _mascotaData?['cashback'] ?? 0;
    return cashback.toDouble();
  }

  int _obtenerNivel() {
    return _mascotaData?['nivel'] ?? 0;
  }

  // 🔽 MÉTODO PARA MOSTRAR INFORMACIÓN DE NIVEL Y PUNTOS
  void _mostrarInfoNivel() {
    final nivel = _obtenerNivel();
    final puntos = _obtenerPuntos();
    final puntosParaSiguienteNivel = 100 - (puntos % 100);
    final progreso = (puntos % 100) / 100;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            SizedBox(width: 8),
            Text(
              'Progreso de Nivel',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: GlobalColors.mainColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nivel actual
            Center(
              child: Text(
                'Nivel $nivel',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: GlobalColors.mainColor,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Puntos actuales
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Puntos acumulados:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '$puntos puntos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: GlobalColors.mainColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Barra de progreso
            Text(
              'Progreso al siguiente nivel:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: progreso,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(GlobalColors.mainColor),
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progreso * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Faltan $puntosParaSiguienteNivel puntos',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Información del sistema de niveles
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Sistema de Niveles',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cada 100 puntos = 1 nivel\nLos puntos se mantienen después de subir de nivel',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ENTENDIDO',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: GlobalColors.mainColor,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // 🔽 MÉTODO ACTUALIZADO PARA INCLUIR SKIN POR DEFECTO
  void _mostrarAtuendos() {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder(
        future: Future.wait([
          authService.value.obtenerAtuendosDisponibles(),
          authService.value.obtenerAtuendosMascota(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              title: Text('Cargando atuendos...'),
              content: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Error al cargar atuendos: ${snapshot.error}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cerrar'),
                ),
              ],
            );
          }

          final atuendosDisponibles = snapshot.data![0] as List<Map<String, dynamic>>;
          final atuendosMascota = snapshot.data![1] as List<Map<String, dynamic>>;

          // 🔽 CREAR ATUENDO POR DEFECTO
          final atuendoDefault = {
            'atuendoId': 'default',
            'tituloSkin': 'Yapita Original',
            'imagen': 'despierto.png',
            'enUso': _mascotaData?['atuendoEquipado'] == null ||
                _mascotaData?['atuendoEquipado'] == 'despierto.png',
          };

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.palette, color: GlobalColors.mainColor),
                    SizedBox(width: 8),
                    Text(
                      'Tienda de Atuendos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: GlobalColors.mainColor,
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔽 ATUENDO POR DEFECTO SIEMPRE DISPONIBLE
                      Text(
                        'Atuendo Base',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: GlobalColors.mainColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      _buildAtuendoItem(
                        atuendo: atuendoDefault,
                        esComprado: true,
                        onEquipar: () async {
                          try {
                            await _equiparAtuendoPorDefecto();
                            setDialogState(() {});
                            // Recargar datos de mascota
                            final mascotaSnapshot = await authService.value.getMascotaDelUsuario();
                            if (mascotaSnapshot.exists) {
                              setState(() {
                                _mascotaData = mascotaSnapshot.data() as Map<String, dynamic>;
                              });
                            }
                            Get.snackbar(
                              '¡Éxito!',
                              'Atuendo equipado: Yapita Original',
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
                          } catch (e) {
                            Get.snackbar(
                              'Error',
                              'No se pudo equipar el atuendo: $e',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        },
                      ),
                      SizedBox(height: 16),

                      // Atuendos ya comprados
                      if (atuendosMascota.isNotEmpty) ...[
                        Text(
                          'Tus Atuendos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: GlobalColors.mainColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...atuendosMascota.map((atuendo) => _buildAtuendoItem(
                          atuendo: atuendo,
                          esComprado: true,
                          onEquipar: () async {
                            try {
                              await authService.value.equiparAtuendo(atuendo['atuendoId']);
                              setDialogState(() {});
                              // Recargar datos de mascota
                              final mascotaSnapshot = await authService.value.getMascotaDelUsuario();
                              if (mascotaSnapshot.exists) {
                                setState(() {
                                  _mascotaData = mascotaSnapshot.data() as Map<String, dynamic>;
                                });
                              }
                              Get.snackbar(
                                '¡Éxito!',
                                'Atuendo equipado: ${atuendo['tituloSkin']}',
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            } catch (e) {
                              Get.snackbar(
                                'Error',
                                'No se pudo equipar el atuendo: $e',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          },
                        )),
                        SizedBox(height: 16),
                      ],

                      // Atuendos disponibles para comprar
                      Text(
                        'Tienda',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: GlobalColors.mainColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...atuendosDisponibles.map((atuendo) {
                        final yaComprado = atuendosMascota
                            .any((a) => a['atuendoId'] == atuendo['id']);

                        return _buildAtuendoItem(
                          atuendo: atuendo,
                          esComprado: yaComprado,
                          onComprar: yaComprado ? null : () async {
                            try {
                              await authService.value.comprarAtuendo(
                                atuendo['id'],
                                atuendo['valor'],
                              );
                              setDialogState(() {});
                              // Actualizar puntos localmente
                              setState(() {
                                _mascotaData?['puntos'] = _obtenerPuntos() - atuendo['valor'];
                              });
                              Get.snackbar(
                                '¡Éxito!',
                                'Atuendo comprado: ${atuendo['tituloSkin']}',
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            } catch (e) {
                              Get.snackbar(
                                'Error',
                                'No se pudo comprar el atuendo: $e',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          },
                        );
                      }),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CERRAR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: GlobalColors.mainColor,
                      ),
                    ),
                  ),
                ],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🔽 NUEVO MÉTODO PARA EQUIPAR ATUENDO POR DEFECTO
  Future<void> _equiparAtuendoPorDefecto() async {
    try {
      final mascotaSnapshot = await authService.value.getMascotaDelUsuario();
      if (mascotaSnapshot.exists) {
        final mascotaId = mascotaSnapshot.id;

        // Usar transacción para asegurar consistencia
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // Quitar enUso de todos los atuendos de la mascota
          final todosAtuendos = await FirebaseFirestore.instance
              .collection('mascota_atuendo')
              .where('mascotaId', isEqualTo: mascotaId)
              .get();

          for (final doc in todosAtuendos.docs) {
            transaction.update(doc.reference, {'enUso': false});
          }

          // Actualizar la mascota con el atuendo por defecto (null o 'despierto.png')
          transaction.update(FirebaseFirestore.instance.collection('mascotas').doc(mascotaId), {
            'atuendoEquipado': FieldValue.delete(), // Eliminar el campo para usar por defecto
          });
        });

        // Actualizar estado local
        setState(() {
          _mascotaData?.remove('atuendoEquipado');
        });
      }
    } catch (e) {
      print('❌ Error al equipar atuendo por defecto: $e');
      rethrow;
    }
  }

  Widget _buildAtuendoItem({
    required Map<String, dynamic> atuendo,
    required bool esComprado,
    VoidCallback? onComprar,
    VoidCallback? onEquipar,
  }) {
    final enUso = atuendo['enUso'] == true;
    final puntosSuficientes = _obtenerPuntos() >= (atuendo['valor'] ?? 100);
    final esDefault = atuendo['atuendoId'] == 'default';

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      color: enUso ? GlobalColors.mainColor.withOpacity(0.1) : null,
      child: ListTile(
        leading: Image.asset(
          'assets/images/${atuendo['imagen']}',
          width: 50,
          height: 50,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.pets, size: 40, color: GlobalColors.mainColor);
          },
        ),
        title: Text(atuendo['tituloSkin'] ?? 'Atuendo'),
        subtitle: esComprado
            ? Text(enUso ? 'Equipado' : 'Disponible')
            : Text(esDefault ? 'Gratuito' : '${atuendo['valor'] ?? 100} puntos'),
        trailing: esComprado
            ? enUso
            ? Icon(Icons.check_circle, color: Colors.green)
            : ElevatedButton(
          onPressed: onEquipar,
          child: Text('Equipar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: GlobalColors.mainColor,
            foregroundColor: Colors.white,
          ),
        )
            : ElevatedButton(
          onPressed: puntosSuficientes ? onComprar : null,
          child: Text('Comprar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: puntosSuficientes ? GlobalColors.mainColor : Colors.grey,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    try {
      bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Cerrar Sesión'),
            content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );

      if (confirmar == true) {
        Get.dialog(
          const Center(
            child: CircularProgressIndicator(),
          ),
          barrierDismissible: false,
        );

        await authService.value.firebaseAuth.signOut();

        Get.back();

        Get.offAll(() => const AuthLayout());

        Get.snackbar(
          'Sesión cerrada',
          'Has cerrado sesión exitosamente',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back();

      Get.snackbar(
        'Error',
        'Error al cerrar sesión: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _mostrarDialogoEditarNombre() {
    final nombreActual = _obtenerNombreMascota();
    final TextEditingController controller = TextEditingController(text: nombreActual);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar nombre de mascota'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ingresa el nuevo nombre',
            border: OutlineInputBorder(),
          ),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nuevoNombre = controller.text.trim();
              if (nuevoNombre.isNotEmpty && nuevoNombre != nombreActual) {
                Navigator.pop(context);
                await _actualizarNombreMascota(nuevoNombre);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalColors.mainColor,
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Future<void> _actualizarNombreMascota(String nuevoNombre) async {
    try {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      await authService.value.actualizarNombreMascota(nuevoNombre);

      Get.back();
      final mascotaSnapshot = await authService.value.getMascotaDelUsuario();
      if (mascotaSnapshot.exists) {
        setState(() {
          _mascotaData = mascotaSnapshot.data() as Map<String, dynamic>;
        });
      }

      Get.snackbar(
        '¡Éxito!',
        'Nombre actualizado a: $nuevoNombre',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error',
        'No se pudo actualizar el nombre: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _mostrarMenuAjustes() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<Map<String, dynamic>?>(
                future: authService.value.getUserData(authService.value.currentUser!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text('Cargando...'),
                    );
                  }

                  if (snapshot.hasData && snapshot.data != null) {
                    final userData = snapshot.data!;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: GlobalColors.mainColor,
                        child: Text(
                          userData['nombre']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(userData['nombre'] ?? 'Usuario'),
                      subtitle: Text(userData['email'] ?? ''),
                    );
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: GlobalColors.mainColor,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(authService.value.currentUser?.email ?? 'Usuario'),
                  );
                },
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _cerrarSesion();
                },
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _mascotaSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estaDespierto = _estaDespierto();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(),
        child: Column(
          children: [
            Expanded(
              child: SafeArea(
                child: _cargando
                    ? const Center(
                  child: CircularProgressIndicator(),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 130,
                            decoration: BoxDecoration(
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(0),
                              child: Image.asset(
                                'assets/images/iconaso.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal:20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: GlobalColors.mainColor,
                                    borderRadius: BorderRadius.circular(60),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _obtenerNombreMascota(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                          maxLines: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: _mostrarDialogoEditarNombre,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.edit,
                                            size: 12,
                                            color: GlobalColors.mainColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () {},
                                            icon: const Icon(Icons.flash_on, size: 14),
                                            label: Text("${_obtenerEnergia()}"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: GlobalColors.mainColor,
                                              foregroundColor: Colors.white,
                                              textStyle: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () {},
                                            icon: const Icon(Icons.attach_money, size: 14),
                                            label: Text("${_obtenerCashback().toStringAsFixed(2)}"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: GlobalColors.mainColor,
                                              foregroundColor: Colors.white,
                                              textStyle: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 🔽 FILA CON BOTONES DE ATUENDOS Y NIVEL
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botón de Atuendos (izquierda)
                        Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: ElevatedButton.icon(
                            onPressed: _mostrarAtuendos,
                            icon: const Icon(Icons.palette, size: 24),
                            label: const Text(""),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlobalColors.mainColor,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        // Botón de Nivel (derecha)
                        Padding(
                          padding: const EdgeInsets.only(right: 40),
                          child: ElevatedButton.icon(
                            onPressed: _mostrarInfoNivel,
                            icon: const Icon(Icons.emoji_events, size: 24),
                            label: Text("${_obtenerPuntos()}"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlobalColors.mainColor,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 🔽 IMAGEN DE LA YAPITA CON SISTEMA DE ATUENDOS MEJORADO
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Image.asset(
                        estaDespierto
                            ? 'assets/images/${_mascotaData?['atuendoEquipado'] ?? 'despierto.png'}'
                            : 'assets/images/durmiendo.png',
                        width: 300,
                        height: 300,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            estaDespierto
                                ? 'assets/images/despierto.png'
                                : 'assets/images/durmiendo.png',
                            width: 300,
                            height: 300,
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                    ),

                    // 🔽 BOTÓN DEL CHATBOT
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: ElevatedButton.icon(
                        onPressed: estaDespierto ? () {
                          Get.to(() => const ChatPage());
                        } : null,
                        icon: Icon(
                          Icons.chat_bubble,
                          size: 14,
                          color: estaDespierto ? Colors.white : Colors.grey,
                        ),
                        label: Text(
                          estaDespierto ? "Hablar con tu Yapita" : "Falta energía",
                          style: TextStyle(
                            color: estaDespierto ? Colors.white : Colors.grey,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: estaDespierto
                              ? GlobalColors.mainColor
                              : Colors.grey[300],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // 🔽 Menú inferior
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: GlobalColors.mainColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.wallet_giftcard),
            label: 'Enviar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports),
            label: 'Atrapar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.pop(context);
          } else if (index == 0) {
            Get.to(() => PantallaEnviarCashback());
          } else if (index == 2) {
            _mostrarMenuAjustes();
          }
        },
      ),
    );
  }
}