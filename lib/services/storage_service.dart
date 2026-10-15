import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    // สร้างชื่อไฟล์ที่ไม่ซ้ำกันโดยใช้ sellerId ผสมกับ timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${sellerId}_$timestamp.jpg';

    // อ้างอิงพาธใน Storage: items/<fileName>
    final ref = _storage.ref().child('items').child(fileName);

    // อัปโหลดไฟล์ด้วย putFile
    final uploadTask = await ref.putFile(imageFile);

    // เรียก getDownloadURL หลังจากอัปโหลดเสร็จสมบูรณ์
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }
}
