// pantalla_enviar_cashback.dart - VERSIÓN ACTUALIZADA

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nuevoyapita/services/authservice.dart';
import 'package:nuevoyapita/utils/globalcolors.dart';

class PantallaEnviarCashback extends StatefulWidget {
  const PantallaEnviarCashback({super.key});

  @override
  _PantallaEnviarCashbackState createState() => _PantallaEnviarCashbackState();
}

class _PantallaEnviarCashbackState extends State<PantallaEnviarCashback> {
  final TextEditingController _montoController = TextEditingController();
  double _cashbackActual = 0.0;
  bool _cargando = true;
  Map<String, dynamic>? _mascotaData;
  String? _codigoGenerado;
  double? _montoGenerado;
  DateTime? _fechaExpiracion;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargarDatosMascota();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarDatosMascota() async {
    try {
      final mascotaSnapshot = await authService.value.getMascotaDelUsuario();
      if (mascotaSnapshot.exists) {
        setState(() {
          _mascotaData = mascotaSnapshot.data() as Map<String, dynamic>;
          _cashbackActual = (_mascotaData!['cashback'] ?? 0).toDouble();
          _cargando = false;
        });
      } else {
        setState(() {
          _cargando = false;
        });
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

  void _iniciarTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_fechaExpiracion != null && DateTime.now().isAfter(_fechaExpiracion!)) {
        timer.cancel();
        setState(() {
          _codigoGenerado = null;
          _montoGenerado = null;
          _fechaExpiracion = null;
        });
        Get.snackbar(
          'Código expirado',
          'El código ha expirado y el cashback ha sido devuelto',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _generarCodigoDescuento() async {
    final montoText = _montoController.text.trim();
    if (montoText.isEmpty) {
      Get.snackbar(
        'Error',
        'Por favor ingresa un monto',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final monto = double.tryParse(montoText);
    if (monto == null || monto <= 0) {
      Get.snackbar(
        'Error',
        'Por favor ingresa un monto válido',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (monto > _cashbackActual) {
      Get.snackbar(
        'Error',
        'No tienes suficiente cashback. Tu cashback actual es \$$_cashbackActual',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final userId = authService.value.currentUser!.uid;
      final mascotaId = _mascotaData!['id'];

      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // 1. Crear transferencia de descuento
      final resultado = await authService.value.transferenciaService.crearTransferenciaDescuento(
        userId: userId,
        mascotaId: mascotaId,
        monto: monto,
      );

      Get.back();

      if (resultado['exito']) {
        // 2. Actualizar cashback de la mascota (restar el monto)
        final nuevoCashback = _cashbackActual - monto;
        await authService.value.mascotaService.actualizarCashbackMascota(mascotaId, nuevoCashback);

        setState(() {
          _codigoGenerado = resultado['codigo'];
          _montoGenerado = monto;
          _fechaExpiracion = resultado['fechaExpiracion'];
          _cashbackActual = nuevoCashback;
        });

        _montoController.clear();
        _iniciarTimer();

        Get.snackbar(
          '✅ Código generado',
          'Tu código de descuento ha sido creado exitosamente',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          resultado['error'] ?? 'Error al generar el código',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error',
        'Error al generar código: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _copiarCodigo() {
    if (_codigoGenerado != null) {
      // Aquí puedes usar un package de clipboard como clipboard: ^0.1.3
      // Por ahora mostramos un mensaje
      Get.snackbar(
        'Código copiado',
        'El código $_codigoGenerado ha sido copiado',
        backgroundColor: GlobalColors.mainColor,
        colorText: Colors.white,
      );
    }
  }

  String _formatearTiempoRestante() {
    if (_fechaExpiracion == null) return '';

    final ahora = DateTime.now();
    final diferencia = _fechaExpiracion!.difference(ahora);

    if (diferencia.isNegative) {
      return 'Expirado';
    }

    final minutos = diferencia.inMinutes;
    final segundos = diferencia.inSeconds % 60;

    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  bool _estaExpirado() {
    if (_fechaExpiracion == null) return false;
    return DateTime.now().isAfter(_fechaExpiracion!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar Cashback'),
        backgroundColor: GlobalColors.mainColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TARJETA DE SALDO ACTUAL
            Card(
              color: GlobalColors.mainColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Cashback Disponible',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$$_cashbackActual',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // FORMULARIO PARA GENERAR CÓDIGO
            if (_codigoGenerado == null) ...[
              const Text(
                'Generar Código de Descuento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto a enviar',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                  hintText: '0.00',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              Text(
                'Máximo disponible: \$$_cashbackActual',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _generarCodigoDescuento,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalColors.mainColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Generar Código',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],

            // CÓDIGO GENERADO
            if (_codigoGenerado != null) ...[
              const SizedBox(height: 20),
              Text(
                _estaExpirado() ? '⚠️ Código Expirado' : '¡Código Generado!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _estaExpirado() ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: _estaExpirado() ? Colors.orange[50] : Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        _codigoGenerado!,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Descuento: \$$_montoGenerado',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Expira en:'),
                          Text(
                            _formatearTiempoRestante(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _estaExpirado() ? Colors.orange : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      if (_estaExpirado()) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'El cashback ha sido devuelto automáticamente',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _copiarCodigo,
                      child: const Text('Copiar Código'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _codigoGenerado = null;
                          _montoGenerado = null;
                          _fechaExpiracion = null;
                        });
                        _timer?.cancel();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlobalColors.mainColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Generar Otro'),
                    ),
                  ),
                ],
              ),
            ],

            const Spacer(),

            // INFORMACIÓN
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 Información:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• El código expira en 3 minutos\n• Si no se usa, el monto se devuelve automáticamente a tu cashback\n• Muestra este código al comercio para obtener tu descuento\n• Los códigos canjeados no se devuelven',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}