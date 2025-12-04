import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'dart:math';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Ahora retorna gmaps.LatLng en lugar de LatLng de latlong2
  Future<gmaps.LatLng?> getCurrentLocation() async {
    try {
      // Verificar si los permisos están concedidos
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Solicitar permisos
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Permisos de ubicación denegados por el usuario');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Permisos de ubicación denegados permanentemente');
        return null;
      }

      // Obtener ubicación
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return gmaps.LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      return null;
    }
  }

  // Ahora usa gmaps.LatLng en lugar de LatLng de latlong2
  List<gmaps.LatLng> getNearbyTrashBins(gmaps.LatLng userLocation) {
    List<gmaps.LatLng> trashBins = [];
    final random = Random();

    int binCount = 8 + random.nextInt(5);

    for (int i = 0; i < binCount; i++) {
      double offsetLat = (random.nextDouble() - 0.5) * 0.009;
      double offsetLng = (random.nextDouble() - 0.5) * 0.009;

      trashBins.add(gmaps.LatLng(
        userLocation.latitude + offsetLat,
        userLocation.longitude + offsetLng,
      ));
    }

    return trashBins;
  }
}

final locationService = LocationService();
