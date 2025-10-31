import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  final String apiKey = "AIzaSyAtTUJdTkjaH3j1loEsLR6h_2JwefA2BoM";

  Future<String> sendMessage(String userMessage) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-latest:generateContent?key=$apiKey",
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": userMessage}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
      return text ?? "No response from AI.";
    } else {
      print(response.body); // debug log
      return "Error ${response.statusCode}: ${response.reasonPhrase}";
    }
  }
}
