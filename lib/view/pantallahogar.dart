import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nuevoyapita/services/authservice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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

        // Escuchar cambios en tiempo real
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/fondo.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: const Color(0xFFFFEA96),
              child: Image.asset(
                'assets/yapitatext.png',
                height: 80,
                width: 200,
                fit: BoxFit.contain,
              ),
            ),
            Expanded(
              child: SafeArea(
                child: _cargando
                    ? const Center(
                  child: CircularProgressIndicator(),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 0),

                    // Información de la mascota
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Energía
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.flash_on, size: 24),
                          label: Text("${_obtenerEnergia()}"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFEA96),
                            foregroundColor: const Color(0xFF9A2727),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                          ),
                        ),
                        // Cashback
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.attach_money, size: 24),
                          label: Text("${_obtenerCashback().toStringAsFixed(2)}"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFEA96),
                            foregroundColor: const Color(0xFF9A2727),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Puntos y Nivel
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Puntos
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.star, size: 24),
                          label: Text("${_obtenerPuntos()}"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFEA96),
                            foregroundColor: const Color(0xFF9A2727),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                          ),
                        ),
                        // Nivel
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.trending_up, size: 24),
                          label: Text("Nvl ${_obtenerNivel()}"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFEA96),
                            foregroundColor: const Color(0xFF9A2727),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Nombre de la mascota
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEA96),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _obtenerNombreMascota(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9A2727),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),



                    const SizedBox(height: 20),

                    // BOTÓN DE RANKING
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.emoji_events, size: 24),
                      label: const Text("Ranking"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEA96),
                        foregroundColor: const Color(0xFF9A2727),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                      ),
                    ),

                    const Spacer(),

                    // Información del estado
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _estaDespierto()
                              ? '¡${_obtenerNombreMascota()} está activo!'
                              : '${_obtenerNombreMascota()} está durmiendo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // 🔽 Menú inferior
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFFFEA96),
        selectedItemColor: const Color(0xFF9A2727),
        unselectedItemColor: const Color(0xFF9A2727),
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