import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = '???';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent';

  Future<String> generateText(String prompt) async {
    final uri = Uri.parse('$_baseUrl?key=$_apiKey');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    });

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final candidates = json['candidates'];
        if (candidates != null && candidates.isNotEmpty) {
          final text =
              candidates[0]['content']['parts'][0]['text'] as String? ?? '';
          print('[GeminiService] Response: $text');
          return text;
        } else {
          throw Exception('No candidates returned from Gemini API');
        }
      } else {
        print('[GeminiService] Error ${response.statusCode}: ${response.body}');
        throw Exception('Gemini API error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('[GeminiService] ClientException: $e');
      throw Exception('Network error: $e');
    }
  }
}
