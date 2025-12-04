import 'package:flutter/material.dart';
import "package:dash_chat_2/dash_chat_2.dart";
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../services/authservice.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Cambiar de flutter_gemini a google_generative_ai
  GenerativeModel? _model;
  ChatSession? _chatSession;

  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "Gemini");
  bool cargandoRespuesta = false;
  bool _initializing = true;
  String? _initError;

  // Configuración de generación optimizada
  final GenerationConfig _generationConfig = GenerationConfig(
    maxOutputTokens: 1024,
    temperature: 0.7,
    topP: 0.8,
    topK: 40,
  );

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _verificarEstadoMascota();
  }

  Future<void> _initializeModel() async {
    final modelsToTry = [
      'gemini-2.5-flash',
      'gemini-2.5-pro',
      'gemini-2.0-flash',
      'models/gemini-2.5-flash',
      'models/gemini-2.5-pro',
    ];

    try {
      // IMPORTANTE: Reemplaza con tu API key real
      const apiKey = 'AIzaSyD-gJ8FQjHFxM9vzpkGj4Sx-3TjG3BgBMA';

      if (apiKey.isEmpty) {
        throw Exception('API key no configurada');
      }

      print('🔄 Iniciando inicialización del modelo...');

      GenerativeModel? workingModel;
      String? workingModelName;

      for (final modelName in modelsToTry) {
        try {
          print('🔍 Probando modelo: $modelName');

          final testModel = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            generationConfig: _generationConfig,
          );

          // Hacer prueba simple
          final testSession = testModel.startChat();
          final testResponse = await testSession.sendMessage(
            Content.text('Hi'),
          ).timeout(const Duration(seconds: 10));

          if (testResponse.text != null) {
            workingModel = testModel;
            workingModelName = modelName;
            _chatSession = testSession;
            print('✅ Modelo $modelName funciona correctamente');
            break;
          }
        } catch (e) {
          print('❌ Modelo $modelName no disponible: $e');
          continue;
        }
      }

      if (workingModel == null) {
        throw Exception('No se encontró ningún modelo disponible');
      }

      _model = workingModel;

      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }

      print('✅ GenerativeModel inicializado con: $workingModelName');
    } catch (e) {
      print('❌ Error inicializando GenerativeModel: $e');

      if (mounted) {
        setState(() {
          _initializing = false;
          _initError = '$e';
        });
      }
    }
  }

  void _verificarEstadoMascota() async {
    try {
      final mascotaSnapshot = await authService.value.getMascotaDelUsuario();
      if (mascotaSnapshot.exists) {
        final mascotaData = mascotaSnapshot.data() as Map<String, dynamic>;
        print('🔍 DEBUG - Mascota ID: ${mascotaSnapshot.id}');
        print('🔍 DEBUG - Energía: ${mascotaData['energia']}');
        print('🔍 DEBUG - Puntos: ${mascotaData['puntos']}');

        Get.snackbar(
          'Estado de Mascota',
          'Energía: ${mascotaData['energia']} | Puntos: ${mascotaData['puntos']}',
          duration: Duration(seconds: 3),
          backgroundColor: Colors.green[100],
        );
      }
    } catch (e) {
      print('❌ Error al verificar mascota: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Yapita Chat"),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Inicializando Gemini...'),
            ],
          ),
        ),
      );
    }

    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Yapita Chat"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error al inicializar Gemini',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _initializing = true;
                      _initError = null;
                    });
                    _initializeModel();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Yapita Chat"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _verificarEstadoMascota,
            tooltip: 'Verificar energía',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.orange[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.energy_savings_leaf, size: 16, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  "Cada mensaje cuesta 5 de energía y gana 5 puntos",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildUI(),
          ),
          if (cargandoRespuesta)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text("Tu Yapita está pensando..."),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUI() {
    return DashChat(
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
      messageOptions: MessageOptions(
        currentUserContainerColor: Colors.blue[300],
        containerColor: Colors.grey,
        textColor: Colors.black,
      ),
    );
  }

  void _sendMessage(ChatMessage chatMessage) async {
    if (_chatSession == null) {
      Get.snackbar(
        'Error',
        'El chat no está inicializado. Por favor reinicia la app.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    print('🔄 Iniciando envío de mensaje...');

    // VERIFICAR ENERGÍA
    final transaccionExitosa = await authService.value.transaccionChatbot();
    if (!transaccionExitosa) {
      Get.snackbar(
        'Energía insuficiente',
        'Necesitas al menos 5 de energía para usar el chatbot. Recicla para ganar energía.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      return;
    }

    setState(() {
      messages = [chatMessage, ...messages];
      cargandoRespuesta = true;
    });

    try {
      String question = chatMessage.text;
      print('📨 Enviando pregunta a Gemini: "$question"');

      // Usar el nuevo método de google_generative_ai
      final response = await _chatSession!.sendMessage(
        Content.text(question),
      ).timeout(const Duration(seconds: 30));

      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        throw Exception('No se recibió respuesta del modelo');
      }

      print('✅ Respuesta recibida: ${responseText.substring(0, responseText.length > 100 ? 100 : responseText.length)}');

      ChatMessage geminiMessage = ChatMessage(
        user: geminiUser,
        createdAt: DateTime.now(),
        text: responseText,
      );

      setState(() {
        messages = [geminiMessage, ...messages];
        cargandoRespuesta = false;
      });

    } on TimeoutException {
      print('⏱️ Timeout en Gemini');
      ChatMessage errorMessage = ChatMessage(
        user: geminiUser,
        createdAt: DateTime.now(),
        text: '⏱️ La respuesta tardó demasiado. Intenta nuevamente.',
      );

      setState(() {
        messages = [errorMessage, ...messages];
        cargandoRespuesta = false;
      });
    } catch (e) {
      print('❌ Error en Gemini: $e');
      ChatMessage errorMessage = ChatMessage(
        user: geminiUser,
        createdAt: DateTime.now(),
        text: _getErrorMessage(e),
      );

      setState(() {
        messages = [errorMessage, ...messages];
        cargandoRespuesta = false;
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('api') || errorString.contains('key')) {
      return '🔑 Problema con la API Key de Gemini. Verifica la configuración.';
    } else if (errorString.contains('quota') || errorString.contains('limit')) {
      return '📊 Límite de uso excedido en Gemini. Intenta más tarde.';
    } else if (errorString.contains('network') || errorString.contains('socket')) {
      return '🌐 Error de conexión. Verifica tu internet.';
    } else {
      return '🤖 Error: $error\n\nPor favor, intenta nuevamente.';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}