import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryFirestore implements ItemRepository {
  final _items = FirebaseFirestore.instance.collection('items');

  // เมธอดนี้มาจาก Interface เดิม — ทำให้ Home เรียกใช้แหล่งข้อมูลนี้แบบเดียวกับ API ได้ทันที
  @override
  Future<List<Item>> getItems() async {
    final snapshot = await _items.get();
    return snapshot.docs
        .map((doc) => Item.fromFirestore(doc))
        .toList();
  }

  // เมธอดเฉพาะของ Firestore เท่านั้น — เรียกตรงจากหน้า Sell/My Listings ไม่ผ่าน Interface
  Future<void> postItem(Item item) async {
    await _items.add(item.toFirestore());
  }

  Stream<List<Item>> watchMyListings(String sellerId) {
    return _items
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Item.fromFirestore(doc))
            .toList());
  }
}
