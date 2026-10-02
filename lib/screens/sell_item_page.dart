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

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descController.dispose();
    super.dispose();
  }

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
        setState(() {
          _titleController.text = draft.title;
          _categoryController.text = draft.category;
          _descController.text = draft.description;
        });
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

  void _confirmDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกร่างประกาศเรียบร้อยแล้ว')),
    );

    setState(() {
      _imageFile = null;
      _titleController.clear();
      _categoryController.clear();
      _descController.clear();
    });
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
            const SizedBox(height: 24),
            
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'รายละเอียดสินค้า',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ชื่อสินค้า',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'หมวดหมู่',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'คำอธิบายสินค้า',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _confirmDraft,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('ยืนยันร่างประกาศ', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
