import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/item.dart';
import '../repositories/item_repository_firestore.dart';
import '../repositories/listing_draft_repository_drift.dart';
import '../services/storage_service.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository repository;

  const MyDraftsPage({super.key, required this.repository});

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  void _loadDrafts() {
    setState(() {
      _draftsFuture = widget.repository.getAllDrafts();
    });
  }

  Future<void> _deleteDraft(int id) async {
    await widget.repository.deleteDraft(id);
    _loadDrafts();
  }

  Future<void> _publishDraft(ListingDraftRow draft) async {
    final priceController = TextEditingController();

    // 1. แสดง Dialog ถามราคาสินค้าก่อนเสมอ
    final price = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('ตั้งราคาสินค้า'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ระบุราคาก่อนโพสต์ขาย "${draft.title}"'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'ราคา (บาท)',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                      prefixText: '฿ ',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final enteredPrice = double.tryParse(priceController.text.trim());
                    if (enteredPrice == null || enteredPrice <= 0) {
                      setDialogState(() {
                        errorText = 'กรุณากรอกราคาที่มากกว่า 0';
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, enteredPrice);
                  },
                  child: const Text('ตกลงและโพสต์'),
                ),
              ],
            );
          },
        );
      },
    );

    if (price == null || !mounted) return;

    // 2. แสดง Progress Indicator ระหว่างอัปโหลดและบันทึก
    setState(() {
      _isPublishing = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('กรุณาเข้าสู่ระบบก่อนโพสต์ขายสินค้า');
      }

      // 3. อัปโหลดรูปภาพขึ้น Storage ก่อนเพื่อรับ Download URL
      // 3. ตรวจสอบการเชื่อมต่อเครือข่ายจริงก่อนเริ่มส่ง
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบสัญญาณเครือข่าย');
        }
      } catch (_) {
        throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบสัญญาณเครือข่าย');
      }

      final imageFile = File(draft.imagePath);
      if (!await imageFile.exists()) {
        throw Exception('ไม่พบไฟล์รูปภาพในเครื่อง');
      }

      final downloadUrl = await StorageService().uploadListingImage(
        imageFile,
        user.uid,
      );

      // 4. สร้าง Item แล้วโพสต์ลง Firestore (ใช้ draft.id เพื่อให้เป็น ID เดียวกันเสมอ ป้องกันส่งซ้ำ)
      final newItem = Item(
        id: draft.id,
        title: draft.title,
        price: price,
        description: draft.description,
        category: draft.category,
        imageUrl: downloadUrl,
        sellerId: user.uid,
      );

      await ItemRepositoryFirestore()
          .postItem(newItem)
          .timeout(const Duration(seconds: 5));

      // 5. ลบร่างออกจาก Local Database และ Refresh หน้าจอ
      await widget.repository.deleteDraft(draft.id);
      _loadDrafts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('โพสต์ขาย "${draft.title}" เรียบร้อยแล้ว!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString().replaceFirst('Exception: ', '');
        if (message.contains('TimeoutException') || message.contains('SocketException')) {
          message = 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบสัญญาณเครือข่าย';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ร่างประกาศของฉัน'),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<ListingDraftRow>>(
            future: _draftsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('ยังไม่มีร่างประกาศสินค้า'));
              }

              final drafts = snapshot.data!;
              return ListView.builder(
                itemCount: drafts.length,
                itemBuilder: (context, index) {
                  final draft = drafts[index];
                  return ListTile(
                    leading: Image.file(
                      File(draft.imagePath),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                    ),
                    title: Text(draft.title),
                    subtitle: Text(
                        '${draft.category} • อัปเดตเมื่อ ${draft.updatedAt.toLocal().toString().split('.')[0]}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isPublishing ? null : () => _publishDraft(draft),
                          icon: const Icon(Icons.cloud_upload, size: 18),
                          label: const Text('โพสต์ขายจริง'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: _isPublishing ? null : () => _deleteDraft(draft.id),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          if (_isPublishing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('กำลังอัปโหลดรูปและโพสต์สินค้า...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
