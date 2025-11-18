import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:nuevoyapita/services/authservice.dart';
import '../authlayout.dart';
import 'pantallagrabacion.dart';
import 'pantallahogar.dart';

const MAPBOX_ACCESO_TOKEN = 'pk.eyJ1IjoicmFoZ2J5IiwiYSI6ImNtZ3NlYnhkcTBnN3Uya3Bvc3lja25tOGkifQ.p9yRuDERTPSVKjb3JLNs_Q';
final myPosition = LatLng(40.97934, -73.939257);

class AppNavigationLayout extends StatelessWidget {
  const AppNavigationLayout({super.key});

  void _abrirGrabacionVideo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PantallaGrabacion()),
    );
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    try {
      // Mostrar diálogo de confirmación
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
        // Mostrar loading
        Get.dialog(
          const Center(
            child: CircularProgressIndicator(),
          ),
          barrierDismissible: false,
        );

        // Cerrar sesión en Firebase
        await authService.value.firebaseAuth.signOut();

        // Cerrar loading
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
      // Cerrar loading si hay error
      Get.back();

      Get.snackbar(
        'Error',
        'Error al cerrar sesión: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _mostrarMenuOpciones(BuildContext context) {
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
              // Información del usuario
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
                        backgroundColor: Colors.blue,
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
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(authService.value.currentUser?.email ?? 'Usuario'),
                  );
                },
              ),

              const Divider(),

              // Opción de perfil
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: const Text('Mi Perfil'),
                onTap: () {
                  Navigator.pop(context);
                  // Aquí puedes navegar a la pantalla de perfil
                  Get.snackbar(
                    'Próximamente',
                    'Pantalla de perfil en desarrollo',
                    backgroundColor: Colors.blue,
                    colorText: Colors.white,
                  );
                },
              ),

              // Opción de configuración
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text('Configuración'),
                onTap: () {
                  Navigator.pop(context);
                  // Aquí puedes navegar a la pantalla de configuración
                  Get.snackbar(
                    'Próximamente',
                    'Pantalla de configuración en desarrollo',
                    backgroundColor: Colors.blue,
                    colorText: Colors.white,
                  );
                },
              ),

              // Opción de cerrar sesión
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _cerrarSesion(context);
                },
              ),

              const SizedBox(height: 10),

              // Botón cancelar
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Basura'),
        centerTitle: true,
        actions: [
          // Botón de menú de usuario
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => _mostrarMenuOpciones(context),
            tooltip: 'Menú de usuario',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            options: MapOptions(
              initialCenter: myPosition,
              minZoom: 5,
              maxZoom: 20,
              initialZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                additionalOptions: {
                  'accessToken': MAPBOX_ACCESO_TOKEN,
                  'id': 'mapbox/streets-v12',
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: myPosition,
                    child: const Icon(
                      Icons.person_pin,
                      color: Colors.blueAccent,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Botón Home
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.orange,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PantallaHogar()),
                );
              },
              child: const Icon(Icons.home, color: Colors.white),
            ),
          ),

          // Botón rectangular personalizado - GRABACIÓN DE VIDEO
          Positioned(
            bottom: 20,
            right: 20,
            left: 20,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => _abrirGrabacionVideo(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'GRABAR GESTOS DE BASURA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}