class Item {
  final String id;
  final String categoryID;
  final String itemName;
  final Map<String, dynamic> fields;
  final List<SubItem> subItems;

  Item({
    required this.id,
    required this.categoryID,
    required this.itemName,
    required this.fields,
    required this.subItems,
  });

  /// 🔹 Firestore 데이터 변환 시 `toString()`을 적용하여 에러 방지
  factory Item.fromFirestore(String docId, Map<String, dynamic> data, List<SubItem> subItems) {
    return Item(
      id: docId,
      categoryID: data['CategoryID']?.toString() ?? '', // 🔹 변환 추가
      itemName: data['ItemName']?.toString() ?? '', // 🔹 변환 추가
      fields: Map<String, dynamic>.from(data)
        ..removeWhere((key, _) => key == 'CategoryID' || key == 'ItemName'),
      subItems: subItems,
    );
  }
}


class SubItem {
  final String id;
  final Map<String, dynamic> fields;

  SubItem({
    required this.id,
    required this.fields,
  });

  /// 🔹 Firestore 데이터 변환 시 `toString()` 적용
  factory SubItem.fromFirestore(String docId, Map<String, dynamic> data) {
    return SubItem(
      id: docId,
      fields: data.map((key, value) => MapEntry(key, value?.toString() ?? '')), // 🔹 변환 추가
    );
  }
}
