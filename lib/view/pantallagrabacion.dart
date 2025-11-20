import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nuevoyapita/services/authservice.dart';
import 'package:nuevoyapita/view/pantallahogar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PantallaGrabacion extends StatefulWidget {
  const PantallaGrabacion({super.key});

  @override
  _PantallaGrabacionState createState() => _PantallaGrabacionState();
}

class _PantallaGrabacionState extends State<PantallaGrabacion> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isRecording = false;
  String? _videoPath;
  int _recordingTime = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _solicitarPermisosYInicializar();
  }

  Future<void> _solicitarPermisosYInicializar() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();

    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted) {
      _inicializarCamara();
    } else {
      _mostrarErrorPermisos();
    }
  }

  Future<void> _inicializarCamara() async {
    final cameras = await availableCameras();
    final primeraCamara = cameras.first;

    _controller = CameraController(
      primeraCamara,
      ResolutionPreset.medium,
      enableAudio: true,
    );

    _initializeControllerFuture = _controller.initialize();
    setState(() {});
  }

  void _mostrarErrorPermisos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permisos necesarios'),
        content: Text('La app necesita permisos de cámara y micrófono para funcionar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          TextButton(
            onPressed: () => openAppSettings(),
            child: Text('Abrir configuración'),
          ),
        ],
      ),
    );
  }

  Future<void> _iniciarGrabacion() async {
    try {
      await _initializeControllerFuture;

      final directory = await getTemporaryDirectory();
      final rutaVideo = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';

      await _controller.startVideoRecording();

      setState(() {
        _isRecording = true;
        _recordingTime = 0;
      });

      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _recordingTime = timer.tick;
        });

        if (timer.tick >= 30) {
          _detenerGrabacion();
        }
      });

    } catch (e) {
      print('Error al iniciar grabación: $e');
    }
  }

  Future<void> _detenerGrabacion() async {
    try {
      _timer?.cancel();
      final videoFile = await _controller.stopVideoRecording();

      setState(() {
        _isRecording = false;
        _videoPath = videoFile.path;
      });

      _analizarVideoConIA(_videoPath!);

    } catch (e) {
      print('Error al detener grabación: $e');
    }
  }

  Future<void> _analizarVideoConIA(String rutaVideo) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Analizando gestos...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Verificando que depositaste la basura correctamente...'),
          ],
        ),
      ),
    );

    // SIMULAR ANÁLISIS (reemplazar con IA real)
    await Future.delayed(Duration(seconds: 3));

    Navigator.pop(context);

    _mostrarResultadoAnalisis(exitoso: true);
  }

  Future<void> _aumentarEnergiaMascota() async {
    try {
      await authService.value.aumentarEnergiaPorBasura();
      print('Energía aumentada exitosamente +15');
    } catch (e) {
      print('Error al aumentar energía: $e');
      Get.snackbar(
        'Error',
        'No se pudo aumentar la energía: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _mostrarResultadoAnalisis({required bool exitoso}) {
    showDialog(
      context: context,
      barrierDismissible: false, // Evita que el usuario cierre tocando fuera
      builder: (context) => AlertDialog(
        title: Text(
          exitoso ? '¡Éxito!' : 'Intenta nuevamente',
          style: TextStyle(
            color: exitoso ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          exitoso
              ? 'La IA detectó que depositaste la basura correctamente. ¡+15 de energía para tu mascota!'
              : 'No se detectó el gesto completo de depositar basura.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Cerrar el diálogo actual
              Navigator.of(context).pop();

              if (exitoso) {
                // AUMENTAR ENERGÍA EN LA BASE DE DATOS
                await _aumentarEnergiaMascota();

                // 🔽 Navegar a PantallaHogar usando GetX
                Get.offAll(() => PantallaHogar());

                // Alternativa usando Navigator tradicional:
                // Navigator.pushAndRemoveUntil(
                //   context,
                //   MaterialPageRoute(builder: (context) => PantallaHogar()),
                //   (route) => false,
                // );
              }
            },
            child: Text(
              'ACEPTAR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grabar Gestos de Reciclaje'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      CameraPreview(_controller),

                      if (!_isRecording)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment, size: 50, color: Colors.white),
                                SizedBox(height: 16),
                                Text(
                                  'INSTRUCCIONES:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '1. Mantén la basura en la mano\n2. Alza el brazo claramente\n3. Deposita en el tacho\n4. La IA analizará tus gestos\n\n¡Gana 15 de energía por reciclar!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (_isRecording)
                        Positioned(
                          top: 20,
                          right: 20,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_recordingTime seg',
                              style: TextStyle(
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

                Container(
                  padding: EdgeInsets.all(20),
                  child: _isRecording
                      ? ElevatedButton(
                    onPressed: _detenerGrabacion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stop),
                        SizedBox(width: 8),
                        Text('DETENER GRABACIÓN'),
                      ],
                    ),
                  )
                      : ElevatedButton(
                    onPressed: _iniciarGrabacion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam),
                        SizedBox(width: 8),
                        Text('INICIAR GRABACIÓN'),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Inicializando cámara...'),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}