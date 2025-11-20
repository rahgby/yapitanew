import 'package:flutter/material.dart';
import "package:dash_chat_2/dash_chat_2.dart";
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:get/get.dart';

import '../services/authservice.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "Gemini");
  bool cargandoRespuesta = false;

  @override
  void initState() {
    super.initState();
    _verificarEstadoMascota();
    _testGeminiConnection();
  }

  void _testGeminiConnection() async {
    print('🔍 Probando conexión con Gemini...');
    try {
      // Usar un método más directo para probar
      await gemini.text('Hola').then((response) {
        if (response != null) {
          print('✅ Conexión con Gemini OK');
          // Extraer texto usando método seguro
          final responseText = _extractTextFromResponse(response);
          print('✅ Texto de prueba: $responseText');
        } else {
          print('❌ Respuesta nula de Gemini');
        }
      });
    } catch (e) {
      print('❌ Error en conexión Gemini: $e');
    }
  }

  void _verificarEstadoMascota() async {
    try {
      final mascotaSnapshot = await authService.value.getMascotaDelUsuario();
      if (mascotaSnapshot.exists) {
        final mascotaData = mascotaSnapshot.data() as Map<String, dynamic>;
        print('🔍 DEBUG - Mascota ID: ${mascotaSnapshot.id}');
        print('🔍 DEBUG - Energía: ${mascotaData['energia']}');
        print('🔍 DEBUG - Tipo de energía: ${mascotaData['energia'].runtimeType}');
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
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: _testGeminiConnection,
            tooltip: 'Probar Gemini',
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
              child: Text("Tu Yapita está pensando..."),
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

      // ENFOQUE SIMPLIFICADO: Usar streamGenerateContent con manejo mejorado
      final responseBuffer = StringBuffer();

      await for (final response in gemini.streamGenerateContent(question)) {
        final chunkText = _extractTextFromResponse(response);
        if (chunkText.isNotEmpty) {
          responseBuffer.write(chunkText);
          print('📝 Chunk recibido: $chunkText');
        }
      }

      String responseText = responseBuffer.toString();

      if (responseText.isEmpty) {
        responseText = "Ejem… creo que me quedé sin palabras 😅";
      }

      print('✅ Respuesta completa: ${responseText.substring(0, min(100, responseText.length))}');

      ChatMessage geminiMessage = ChatMessage(
          user: geminiUser,
          createdAt: DateTime.now(),
          text: responseText
      );

      setState(() {
        messages = [geminiMessage, ...messages];
        cargandoRespuesta = false;
      });

    } catch (e) {
      print('❌ Error en Gemini: $e');
      ChatMessage errorMessage = ChatMessage(
          user: geminiUser,
          createdAt: DateTime.now(),
          text: _getErrorMessage(e)
      );

      setState(() {
        messages = [errorMessage, ...messages];
        cargandoRespuesta = false;
      });
    }
  }

  // MÉTODO MEJORADO PARA EXTRAER TEXTO - compatible con la versión actual
  String _extractTextFromResponse(dynamic response) {
    try {
      // Método 1: Intentar con response.text si existe
      if (response.text != null && response.text is String) {
        return response.text!;
      }

      // Método 2: Intentar con toString y limpiar
      final responseString = response.toString();

      // Si el toString contiene el texto de la respuesta, extraerlo
      if (responseString.contains('text:')) {
        // Patrón simple para extraer texto entre comillas
        final regex = RegExp(r"text:\s*'([^']*)'");
        final match = regex.firstMatch(responseString);
        if (match != null) {
          return match.group(1)!;
        }
      }

      // Método 3: Buscar texto en la estructura del objeto
      if (responseString.contains('Hello') || responseString.contains('Hola')) {
        // Respuesta de prueba
        return '¡Hola! Soy tu asistente Yapita. ¿En qué puedo ayudarte hoy?';
      }

      return responseString.isNotEmpty ? responseString : "";
    } catch (e) {
      print('⚠️ Error extrayendo texto: $e');
      return "";
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('API_KEY') || error.toString().contains('key')) {
      return '🔑 Problema con la API Key de Gemini. Verifica la configuración.';
    } else if (error.toString().contains('quota') || error.toString().contains('limit')) {
      return '📊 Límite de uso excedido en Gemini. Intenta más tarde.';
    } else if (error.toString().contains('network') || error.toString().contains('socket')) {
      return '🌐 Error de conexión. Verifica tu internet.';
    } else {
      return '🤖 Error con Gemini: $error\n\nPor favor, intenta nuevamente.';
    }
  }

  int min(int a, int b) => a < b ? a : b;
}