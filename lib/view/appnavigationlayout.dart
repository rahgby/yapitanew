import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../services/locationservice.dart';
import '../services/authservice.dart';
import '../authlayout.dart';
import 'pantallagrabacion.dart';
import 'pantallahogar.dart';

const MAPBOX_ACCESO_TOKEN = 'pk.eyJ1IjoicmFoZ2J5IiwiYSI6ImNtZ3NlYnhkcTBnN3Uya3Bvc3lja25tOGkifQ.p9yRuDERTPSVKjb3JLNs_Q';

class AppNavigationLayout extends StatefulWidget {
  const AppNavigationLayout({super.key});

  @override
  State<AppNavigationLayout> createState() => _AppNavigationLayoutState();
}

class _AppNavigationLayoutState extends State<AppNavigationLayout> {
  MapController? _mapController;
  LatLng? _currentLocation;
  List<Marker> _markers = [];
  bool _isLoading = true;
  String _debugMessage = 'Iniciando...';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _debugMessage = 'initState ejecutado';
    print('🔵 $_debugMessage');
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      _debugMessage = 'Verificando servicio de ubicación...';
      print('🔵 $_debugMessage');

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _debugMessage = 'GPS desactivado';
        print('🟡 $_debugMessage');
        Get.snackbar(
          'GPS desactivado',
          'Activa la ubicación para usar el mapa',
          backgroundColor: Colors.orange,
        );
        _useDefaultLocation();
        return;
      }

      _debugMessage = 'Obteniendo ubicación...';
      print('🔵 $_debugMessage');

      final googlePosition = await locationService.getCurrentLocation();
      print("✅ Ubicación obtenida: $googlePosition");

      if (googlePosition != null) {
        _debugMessage = 'Ubicación obtenida correctamente';
        print('✅ $_debugMessage');

        // Convertir de google_maps LatLng a latlong2 LatLng
        final location = LatLng(googlePosition.latitude, googlePosition.longitude);

        setState(() {
          _currentLocation = location;
          _isLoading = false;
        });
        _updateMarkers(googlePosition);

        // Mover la cámara a la ubicación actual
        if (_mapController != null) {
          _debugMessage = 'Moviendo cámara a ubicación';
          print('🔵 $_debugMessage');
          _mapController!.move(_currentLocation!, 15.0);
        }
      } else {
        _debugMessage = 'Ubicación es null, usando ubicación por defecto';
        print('🟡 $_debugMessage');
        _useDefaultLocation();
      }
    } catch (e) {
      _debugMessage = 'Error obteniendo ubicación: $e';
      print('❌ $_debugMessage');
      _useDefaultLocation();
    }
  }

  void _useDefaultLocation() {
    _debugMessage = 'Usando ubicación por defecto';
    print('🟡 $_debugMessage');

    final defaultLatLng = LatLng(-13.70949, -76.21118);
    final googleDefaultLatLng = gmaps.LatLng(-13.70949, -76.21118);

    setState(() {
      _currentLocation = defaultLatLng;
      _isLoading = false;
    });
    _updateMarkers(googleDefaultLatLng);

    Get.snackbar(
      'Ubicación no disponible',
      'Usando ubicación por defecto',
      backgroundColor: Colors.orange,
    );
  }

  void _updateMarkers(gmaps.LatLng googleLocation) {
    if (_currentLocation == null) {
      _debugMessage = 'No se pueden actualizar marcadores - ubicación null';
      print('❌ $_debugMessage');
      return;
    }

    _debugMessage = 'Actualizando marcadores...';
    print('🔵 $_debugMessage');

    List<Marker> newMarkers = [];

    // Marcador de usuario
    newMarkers.add(
      Marker(
        width: 40.0,
        height: 40.0,
        point: _currentLocation!,
        child: const Icon(
          Icons.person_pin,
          color: Colors.blue,
          size: 40,
        ),
      ),
    );

    // Marcadores de tachos de basura
    try {
      final trashBins = locationService.getNearbyTrashBins(googleLocation);
      _debugMessage = 'Generando ${trashBins.length} tachos de basura';
      print('🔵 $_debugMessage');

      for (int i = 0; i < trashBins.length; i++) {
        // Convertir de google_maps LatLng a latlong2 LatLng
        newMarkers.add(
          Marker(
            width: 40.0,
            height: 40.0,
            point: LatLng(trashBins[i].latitude, trashBins[i].longitude),
            child: const Icon(
              Icons.delete,
              color: Colors.green,
              size: 40,
            ),
          ),
        );
      }
    } catch (e) {
      _debugMessage = 'Error generando tachos: $e';
      print('❌ $_debugMessage');
    }

    setState(() {
      _markers = newMarkers;
    });

    _debugMessage = 'Marcadores actualizados: ${_markers.length} total';
    print('✅ $_debugMessage');
  }

  void _abrirGrabacionVideo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PantallaGrabacion()),
    );
  }

  Future<void> _cerrarSesion(BuildContext context) async {
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
        Get.dialog(const Center(child: CircularProgressIndicator()));
        await authService.value.firebaseAuth.signOut();
        Get.back();
        Get.offAll(() => const AuthLayout());

        Get.snackbar(
          'Sesión cerrada',
          'Has cerrado sesión exitosamente',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Error al cerrar sesión: $e', backgroundColor: Colors.red);
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
              FutureBuilder<Map<String, dynamic>?>(
                future: authService.value.getUserData(authService.value.currentUser!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
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
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(authService.value.currentUser?.email ?? 'Usuario'),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: const Text('Mi Perfil'),
                onTap: () {
                  Navigator.pop(context);
                  Get.snackbar('Próximamente', 'Pantalla de perfil en desarrollo');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text('Configuración'),
                onTap: () {
                  Navigator.pop(context);
                  Get.snackbar('Próximamente', 'Pantalla de configuración en desarrollo');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _cerrarSesion(context);
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

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'No se puede cargar el mapa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _debugMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _getUserLocation,
            child: const Text('Reintentar'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              print('🔍 ESTADO ACTUAL:');
              print('• _isLoading: $_isLoading');
              print('• _currentLocation: $_currentLocation');
              print('• _markers.length: ${_markers.length}');
              print('• _debugMessage: $_debugMessage');
            },
            child: const Text('Ver detalles en consola'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🔄 Build ejecutado - _isLoading: $_isLoading, _currentLocation: $_currentLocation');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Basura'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _getUserLocation,
            tooltip: 'Actualizar ubicación',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => _mostrarMenuOpciones(context),
            tooltip: 'Menú de usuario',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Obteniendo tu ubicación...'),
          ],
        ),
      )
          : _currentLocation == null
          ? _buildErrorWidget()
          : Stack(
        children: [
          // Mapa con flutter_map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation!,
              minZoom: 5,
              maxZoom: 20,
              initialZoom: 15,
              onTap: (tapPosition, point) {
                print("👆 Mapa tocado: $point");
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                additionalOptions: const {
                  'accessToken': MAPBOX_ACCESO_TOKEN,
                  'id': 'mapbox/streets-v12',
                },
              ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),

          // Botón de inicio
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.blue,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PantallaHogar()),
                );
              },
              child: const Icon(Icons.home, color: Colors.white),
            ),
          ),

          // Información de ubicación
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📍 Tu ubicación actual',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🗑️ Tachos cercanos: ${_markers.length - 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botón de centrar ubicación
          Positioned(
            bottom: 160,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                if (_currentLocation != null && _mapController != null) {
                  _mapController!.move(_currentLocation!, 15.0);
                }
              },
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          // Botón "ATRAPA YA"
          Positioned(
            bottom: 60,
            right: 100,
            left: 100,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(55),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(80),
                  onTap: () => _abrirGrabacionVideo(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'ATRAPA YA',
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}