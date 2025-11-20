import 'package:flutter/material.dart';
import 'package:nuevoyapita/services/openai_service.dart';
 // <-- CAMBIADO

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, String>> messages = [];
  final TextEditingController controller = TextEditingController();

  bool cargandoRespuesta = false;

  Future<void> enviarMensaje() async {
    final text = controller.text.trim();
    if (text.isEmpty || cargandoRespuesta) return;

    setState(() {
      messages.add({
        "role": "user",
        "content": text,
      });
      cargandoRespuesta = true;
    });

    controller.clear();

    try {
      final respuesta = await OpenAIService.sendMessage(text);

      setState(() {
        messages.add({
          "role": "assistant",
          "content": respuesta ?? "Ejem… creo que me quedé sin palabras 😅",
        });
      });
    } catch (e) {
      setState(() {
        messages.add({
          "role": "assistant",
          "content": "Ups, me atoré como una chapa vieja 😅\n$e",
        });
      });
    } finally {
      setState(() => cargandoRespuesta = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ChapaBot 🤪"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // LISTA DE MENSAJES
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (_, index) {
                final msg = messages[index];

                final role = msg["role"] ?? "assistant";
                final content = msg["content"] ?? "(mensaje vacío)";
                final isUser = role == "user";

                return Row(
                  mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser)
                      const CircleAvatar(
                        radius: 18,
                        child: Text("🥤"),
                      ),

                    const SizedBox(width: 6),

                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blue[300] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(content),
                      ),
                    ),

                    const SizedBox(width: 6),

                    if (isUser)
                      const CircleAvatar(
                        radius: 18,
                        child: Text("🧑"),
                      ),
                  ],
                );
              },
            ),
          ),

          if (cargandoRespuesta)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text("La Chapa está pensando... 🤔"),
            ),

          // INPUT + BOTÓN
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Escribe algo a la Chapa...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: enviarMensaje,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
