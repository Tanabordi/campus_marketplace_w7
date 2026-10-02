import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงประกาศขายสินค้า'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_imageFile != null)
              Image.file(
                _imageFile!,
                height: 200,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 200,
                color: Colors.grey[200],
                child: const Icon(
                  Icons.image,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('เลือกรูปภาพสินค้า'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: เชื่อมกับ Gemini ในขั้นตอนต่อไป
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ฟังก์ชัน AI จะมาในเร็วๆ นี้')),
                );
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('ให้ AI ช่วยแนะนำ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[100],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
