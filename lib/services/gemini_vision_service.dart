import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiVisionService {
  static const String _apiKey = '???';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent';

  Future<Map<String, dynamic>> analyzeImage(File imageFile, String prompt) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

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
        final candidates = json['candidates'] as List<dynamic>?;
        
        if (candidates != null && candidates.isNotEmpty) {
          final candidate = candidates[0];
          final finishReason = candidate['finishReason'];
          
          if (finishReason == 'SAFETY') {
            throw Exception('เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini กรุณาใช้ภาพอื่น');
          }

          final content = candidate['content'];
          if (content != null && content['parts'] != null) {
            final parts = content['parts'] as List<dynamic>;
            if (parts.isNotEmpty) {
               final text = parts[0]['text'] as String;
               final Map<String, dynamic> result = jsonDecode(text);
               return result;
            }
          }
          throw Exception('AI ไม่สามารถวิเคราะห์ภาพนี้ได้ อาจเข้าข่ายเนื้อหาที่ไม่เหมาะสม ลองใช้ภาพอื่น');
        } else {
          throw Exception('AI ไม่สามารถวิเคราะห์ภาพนี้ได้ อาจเข้าข่ายเนื้อหาที่ไม่เหมาะสม ลองใช้ภาพอื่น');
        }
      } else {
        throw Exception('Gemini Vision API error: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

