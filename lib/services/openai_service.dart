import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  // 🔑 Tu NUEVA API KEY de Google AI
  static const String apiKey = "AIzaSyBdTbeYxsvokHXvBFb2KRc85VTMy2NIItM";

  // 🌟 Modelos disponibles (usa uno de estos)
  static const String model = "gemini-pro"; // Modelo estable y disponible
  // static const String model = "gemini-1.0-pro"; // Alternativa

  static Future<String?> sendMessage(String message) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey",
    );

    final body = {
      "contents": [
        {
          "parts": [
            {"text": message}
          ]
        }
      ]
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        return "Error del servidor (${response.statusCode}): ${response.body}";
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      // ✔️ GEMINI responde en: candidates[0].content.parts[0].text
      final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

      return text ?? "(Respuesta vacía 😅)";
    } catch (e) {
      return "Error de conexión: $e";
    }
  }
}