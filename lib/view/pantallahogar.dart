import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nuevoyapita/services/authservice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nuevoyapita/utils/globalcolors.dart';
import 'chat_mascota_view.dart';

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
                    // Fila con logo Yapita a la izquierda y datos a la derecha
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo Yapita (cuadrado)
                          Container(
                            width: 80,
                            height: 130,
                            decoration: BoxDecoration(
                              color: GlobalColors.mainColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.pets,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: GlobalColors.mainColor,
                                    borderRadius:
                                    BorderRadius.circular(60),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _obtenerNombreMascota(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        "Nvl ${_obtenerNivel()}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
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
                                            icon: const Icon(Icons.flash_on, size: 24),
                                            label: Text("${_obtenerEnergia()}"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: GlobalColors.mainColor,
                                              foregroundColor: Colors.white,
                                              textStyle: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () {},
                                            icon: const Icon(Icons.attach_money, size: 24),
                                            label: Text("${_obtenerCashback().toStringAsFixed(2)}"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: GlobalColors.mainColor,
                                              foregroundColor: Colors.white,
                                              textStyle: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
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

                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 40),
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.emoji_events, size: 24),
                          label: const Text(""),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlobalColors.mainColor,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 16),
                          ),
                        ),
                      ),
                    ),

                    // 🔽 IMAGEN DE LA YAPITA
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Image.asset(
                        estaDespierto
                            ? 'assets/images/despierto.png'
                            : 'assets/images/durmiendo.png',
                        width: 400,
                        height: 400,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // 🔽 BOTÓN DEL CHATBOT (MODIFICADO)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ElevatedButton.icon(
                        onPressed: estaDespierto ? () {
                          // Navegar al chatbot solo si está despierto
                          Get.to(() => const ChatPage());
                        } : null, // null desactiva el botón
                        icon: Icon(
                          Icons.chat_bubble,
                          size: 24,
                          color: estaDespierto ? Colors.white : Colors.grey,
                        ),
                        label: Text(
                          estaDespierto ? "Hablar con Chapa 🤪" : "Falta energía",
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
            icon: Icon(Icons.checkroom),
            label: 'Atuendo',
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
            // Navegar a atuendo
          } else if (index == 2) {
            // Navegar a ajustes
          }
        },
      ),
    );
  }
}