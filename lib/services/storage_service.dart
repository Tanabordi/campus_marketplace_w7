import 'dart:convert';
import 'dart:io';

class StorageService {
  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      print('Base64 encoding error: $e');
      return 'https://picsum.photos/400/400';
    }
  }
}
