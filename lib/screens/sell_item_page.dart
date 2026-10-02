import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_vision_service.dart';
import '../models/listing_draft.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  
  bool _isAnalyzing = false;

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

  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final resultMap = await GeminiVisionService().analyzeImage(_imageFile!);
      final draft = ListingDraft.fromJson(resultMap);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'วิเคราะห์สำเร็จ!\nชื่อ: ${draft.title}\nหมวดหมู่: ${draft.category}\nรายละเอียด: ${draft.description}',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
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
              onPressed: _isAnalyzing ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('เลือกรูปภาพสินค้า'),
            ),
            const SizedBox(height: 16),
            if (_isAnalyzing)
              Column(
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI กำลังวิเคราะห์ภาพสินค้า...', style: TextStyle(color: Colors.grey)),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _imageFile == null ? null : _analyzeImage,
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

