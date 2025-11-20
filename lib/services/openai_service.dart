import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  // 🔑 Tu API KEY de Google AI
  static const String apiKey = "AIzaSyD-gJ8FQjHFxM9vzpkGj4Sx-3TjG3BgBMA";

  // 🌟 Modelo recomendado (rápido, barato y estable)
  static const String model = "gemini-1.5-flash";

  static Future<String?> sendMessage(String message) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey",
    );

    final body = {
      "contents": [
        {
          "role": "user",
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

      // ✔️ GEMINI siempre responde en: candidates[0].content.parts[0].text
      final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

      return text ?? "(Respuesta vacía 😅)";
    } catch (e) {
      return "Error de conexión: $e";
    }
  }
}
