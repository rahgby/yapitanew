import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nuevoyapita/services/authservice.dart';
import 'package:nuevoyapita/view/pantallahogar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/transferencia_service.dart';
import '../services/procesamiento_service.dart';

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
  final ProcesamientoService _procesamientoService = ProcesamientoService();
  final TextEditingController _codigoBoletaController = TextEditingController();
  bool _mostrarCampoBoleta = false;
  Map<String, dynamic>? _boletaEncontrada;
  bool _boletaValida = false;
  double _cashbackPotencial = 0.0;

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

  Future<void> _verificarBoleta() async {
    final codigo = _codigoBoletaController.text.trim();

    print('🎫 [PantallaGrabacion] _verificarBoleta llamado');
    print('📝 [PantallaGrabacion] Código ingresado: "$codigo"');

    if (codigo.isEmpty) {
      print('⚠️ [PantallaGrabacion] Código vacío, limpiando estado');
      setState(() {
        _boletaEncontrada = null;
        _boletaValida = false;
        _cashbackPotencial = 0.0;
      });
      return;
    }

    try {
      final userId = authService.value.currentUser!.uid;
      print('👤 [PantallaGrabacion] UserID: $userId');

      print('🔄 [PantallaGrabacion] Llamando a procesamientoService.verificarBoleta...');
      final resultado = await _procesamientoService.verificarBoleta(codigo, userId);

      print('📊 [PantallaGrabacion] Resultado recibido: $resultado');

      if (resultado['valida']) {
        print('✅ [PantallaGrabacion] Boleta VÁLIDA - Actualizando estado UI');
        setState(() {
          _boletaEncontrada = resultado['boleta'];
          _boletaValida = true;
          _cashbackPotencial = resultado['cashbackPotencial'];
        });

        Get.snackbar(
          '✅ Boleta válida',
          resultado['mensaje'],
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        print('❌ [PantallaGrabacion] Boleta NO VÁLIDA - Motivo: ${resultado['mensaje']}');
        setState(() {
          _boletaEncontrada = null;
          _boletaValida = false;
          _cashbackPotencial = 0.0;
        });

        Get.snackbar(
          '❌ Boleta no válida',
          resultado['mensaje'],
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('💥 [PantallaGrabacion] ERROR CRÍTICO en _verificarBoleta: $e');
      setState(() {
        _boletaEncontrada = null;
        _boletaValida = false;
        _cashbackPotencial = 0.0;
      });

      Get.snackbar(
        'Error',
        'No se pudo verificar la boleta: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  Future<void> _procesarCashback() async {
    try {
      if (_boletaEncontrada != null && _boletaValida) {
        final userId = authService.value.currentUser!.uid;
        final codigoBoleta = _boletaEncontrada!['codigoBoleta'];
        final montoTotal = _boletaEncontrada!['montoTotal'].toDouble();

        await _procesamientoService.procesarCashbackCompleto(
          userId: userId,
          codigoBoleta: codigoBoleta,
          montoTotal: montoTotal,
        );

        print('✅ Cashback procesado exitosamente en tabla transferencias');
      }
    } catch (e) {
      print('❌ Error procesando cashback: $e');
      // No mostramos error al usuario para no interrumpir el flujo principal
    }
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
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          exitoso ? '¡Éxito!' : 'Intenta nuevamente',
          style: TextStyle(
            color: exitoso ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exitoso
                  ? 'La IA detectó que depositaste la basura correctamente. ¡+15 de energía para tu mascota!'
                  : 'No se detectó el gesto completo de depositar basura.',
            ),
            if (exitoso) ...[
              SizedBox(height: 16),
              // Recompensa base por reciclar
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡+15 de energía!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            'Por reciclar correctamente',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Cashback adicional si hay boleta válida
            if (exitoso && _boletaValida) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Cashback adicional!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'Boleta: ${_boletaEncontrada!['codigoBoleta']}',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Monto: \$${_cashbackPotencial.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              if (exitoso) {
                // AUMENTAR ENERGÍA EN LA BASE DE DATOS
                await _aumentarEnergiaMascota();

                // PROCESAR CASHBACK SI HAY BOLETA VÁLIDA
                if (_boletaValida) {
                  await _procesarCashback();
                }

                // Navegar a PantallaHogar
                Get.offAll(() => PantallaHogar());
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
    _codigoBoletaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grabar Gestos de Reciclaje'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(
              _mostrarCampoBoleta ? Icons.receipt : Icons.receipt_outlined,
              color: _mostrarCampoBoleta ? Colors.yellow : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _mostrarCampoBoleta = !_mostrarCampoBoleta;
                if (!_mostrarCampoBoleta) {
                  _codigoBoletaController.clear();
                  _boletaEncontrada = null;
                  _boletaValida = false;
                  _cashbackPotencial = 0.0;
                }
              });
            },
            tooltip: _mostrarCampoBoleta
                ? 'Ocultar boleta (opcional)'
                : 'Agregar boleta para cashback (opcional)',
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                // 🔽 NUEVA SECCIÓN: Campo de código de boleta
                if (_mostrarCampoBoleta)
                  Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.grey[50],
                    child: Column(
                      children: [
                        Text(
                          'CÓDIGO DE BOLETA (OPCIONAL)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Ingresa tu código de boleta para obtener cashback adicional del 1%',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _codigoBoletaController,
                                decoration: InputDecoration(
                                  hintText: 'Ingresa código de boleta',
                                  border: OutlineInputBorder(),
                                  suffixIcon: _boletaEncontrada != null
                                      ? Icon(
                                    _boletaValida ? Icons.check_circle : Icons.warning,
                                    color: _boletaValida ? Colors.green : Colors.orange,
                                  )
                                      : null,
                                ),
                                onChanged: (value) => _verificarBoleta(),
                              ),
                            ),
                          ],
                        ),
                        if (_boletaEncontrada != null) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _boletaValida ? Colors.green[50] : Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _boletaValida ? Colors.green : Colors.orange,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _boletaValida ? Icons.attach_money : Icons.warning,
                                  color: _boletaValida ? Colors.green : Colors.orange,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _boletaValida ? '✅ Boleta válida' : '⚠️ Boleta no válida',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _boletaValida ? Colors.green : Colors.orange,
                                        ),
                                      ),
                                      Text(
                                        'Monto: \$${_boletaEncontrada!['montoTotal'].toStringAsFixed(2)}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      if (_boletaValida)
                                        Text(
                                          'Cashback: \$${_cashbackPotencial.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

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
                                  '1. Mantén la basura en la mano\n2. Alza el brazo claramente\n3. Deposita en el tacho\n4. La IA analizará tus gestos',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                                SizedBox(height: 16),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green[800],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '¡Gana 15 de energía por reciclar!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '+ Cashback del 1% si agregas una boleta válida',
                                        style: TextStyle(
                                          color: Colors.yellow,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                if (_mostrarCampoBoleta && _boletaValida) ...[
                                  SizedBox(height: 16),
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.attach_money, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          '+ Cashback disponible',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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