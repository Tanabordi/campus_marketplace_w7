import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiVisionService {
  static const String _apiKey = '???';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent';

  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    const prompt = '''
    วิเคราะห์ภาพสินค้านี้แล้วแยกรายละเอียดออกมาเป็น JSON
    ประกอบด้วย:
    - title: ชื่อสินค้า (สั้นๆ กระชับ)
    - price: ราคาโดยประมาณ (เป็นตัวเลข)
    - category: หมวดหมู่สินค้า
    - description: คำอธิบายสินค้าสั้นๆ
    ''';

    final uri = Uri.parse('$_baseUrl?key=$_apiKey');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {
                'mimeType': 'image/jpeg',
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'title': {'type': 'STRING'},
            'price': {'type': 'NUMBER'},
            'category': {'type': 'STRING'},
            'description': {'type': 'STRING'}
          },
          'required': ['title', 'price', 'category', 'description']
        }
      }
    });

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final candidates = json['candidates'];
        
        if (candidates != null && candidates.isNotEmpty) {
          final text = candidates[0]['content']['parts'][0]['text'] as String;
          
          final Map<String, dynamic> result = jsonDecode(text);
          return result;
        } else {
          throw Exception('No candidates returned from Gemini Vision API');
        }
      } else {
        print('[GeminiVision] Error ${response.statusCode}: ${response.body}');
        throw Exception('Gemini Vision API error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('[GeminiVision] ClientException: $e');
      throw Exception('Network error: $e');
    }
  }
}
