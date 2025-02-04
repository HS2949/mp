class Item {
  final String id; // 문서 ID
  final String categoryID; // 카테고리 ID
  final String itemName; // 아이템 이름
  final Map<String, dynamic> fields; // 🔹 동적 필드
  final List<SubItem> subItems; // 🔹 하위 컬렉션 (menu, rooms, services 등)

  Item({
    required this.id,
    required this.categoryID,
    required this.itemName,
    required this.fields,
    required this.subItems,
  });

  /// 🔹 Firestore 데이터를 `Item` 객체로 변환하는 Factory 메서드
  factory Item.fromFirestore(String docId, Map<String, dynamic> data, List<SubItem> subItems) {
    return Item(
      id: docId,
      categoryID: data['CategoryID'] ?? '',
      itemName: data['ItemName'] ?? '',
      fields: Map<String, dynamic>.from(data)..removeWhere((key, _) => key == 'CategoryID' || key == 'ItemName'),
      subItems: subItems, // 하위 컬렉션 데이터 포함
    );
  }

  /// 🔹 객체를 JSON 형태로 변환 (Firestore 저장용)
  Map<String, dynamic> toJson() {
    return {
      'CategoryID': categoryID,
      'ItemName': itemName,
      ...fields, // 동적 필드 포함
    };
  }
}


class SubItem {
  final String id; // 문서 ID (menu1, menu2, menu3 등)
  final Map<String, dynamic> fields; // 🔹 동적 필드

  SubItem({
    required this.id,
    required this.fields,
  });

  /// 🔹 Firestore 데이터를 `SubItem` 객체로 변환하는 Factory 메서드
  factory SubItem.fromFirestore(String docId, Map<String, dynamic> data) {
    return SubItem(
      id: docId,
      fields: Map<String, dynamic>.from(data),
    );
  }

  /// 🔹 객체를 JSON 형태로 변환 (Firestore 저장용)
  Map<String, dynamic> toJson() {
    return {
      ...fields, // 동적 필드 포함
    };
  }
}
