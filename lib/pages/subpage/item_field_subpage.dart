import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/utils/widget_help.dart';

class Item_Field extends StatefulWidget {
  final String title;
  final bool isDefault;
  const Item_Field({
    Key? key,
    required this.title,
    required this.isDefault,
  }) : super(key: key);

  @override
  _Item_FieldState createState() => _Item_FieldState();
}

class _Item_FieldState extends State<Item_Field> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fieldController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();
  final firestoreService = FirestoreService();

  void _showDialog({DocumentSnapshot? document}) {
    // 다이얼로그 내에서 사용되는 지역 isDefault 변수 (필요에 따라 사용자가 토글 가능)
    bool isDefaultLocal = widget.isDefault;

    if (document != null) {
      _nameController.text = document['FieldName'];
      _fieldController.text = document['FieldKey'];
      // 추가정보인 경우 Firestore에 저장된 FieldOrder에서 3을 빼서 보여준다.
      if (widget.isDefault) {
        _orderController.text = document['FieldOrder'].toString();
      } else {
        final int firestoreOrder =
            int.tryParse(document['FieldOrder'].toString()) ?? 0;
        _orderController.text = (firestoreOrder - 3).toString();
      }
    } else {
      _nameController.clear();
      _fieldController.clear();
      _orderController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true, // 내용이 길 경우 스크롤 가능
          title: Text(
            document == null ? 'Add Field' : 'Edit Field',
            style: AppTheme.appbarTitleTextStyle,
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 10),
                    FilterChip(
                      checkmarkColor: AppTheme.secondaryColor,
                      selectedColor: Colors.yellow[100],
                      backgroundColor: Colors.blue[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide.none,
                      ),
                      label: Text(isDefaultLocal ? '기본 정보' : '추가 정보'),
                      selected: isDefaultLocal,
                      onSelected: (selected) {
                        setState(() {
                          isDefaultLocal = selected;
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        suffixIcon: ClearButton(controller: _nameController),
                        labelText: 'Field Name',
                        hintText: '예) 주소, 전화번호, 휴무, 메모 ... ',
                        filled: true,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _fieldController,
                      decoration: InputDecoration(
                        suffixIcon: ClearButton(controller: _fieldController),
                        labelText: 'Field Key',
                        hintText:
                            '예) Address, PhoneNumber, Holiday, Notes ... ',
                        filled: true,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _orderController,
                      decoration: InputDecoration(
                        suffixIcon: ClearButton(controller: _orderController),
                        labelText: 'Order',
                        hintText: '예) 1, 2, 3, 4.. ',
                        filled: true,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // 사용자가 입력한 순서 값을 파싱하여 추가정보인 경우 Firestore 저장 시 3을 더한다.
                int orderInput =
                    int.tryParse(_orderController.text.trim()) ?? 0;
                final String firestoreOrder = isDefaultLocal
                    ? orderInput.toString()
                    : (orderInput + 3).toString();

                if (document == null) {
                  firestoreService.addItem(
                    collectionName: 'Fields',
                    data: {
                      'FieldName': _nameController.text.trim(),
                      'FieldKey': _fieldController.text.trim(),
                      'FieldOrder': firestoreOrder,
                      'IsDefault': isDefaultLocal,
                    },
                    autoGenerateId: true,
                  );
                } else {
                  firestoreService.updateItem(
                    collectionName: 'Fields',
                    documentId: document.id,
                    updatedData: {
                      'FieldName': _nameController.text.trim(),
                      'FieldKey': _fieldController.text.trim(),
                      'FieldOrder': firestoreOrder,
                      'IsDefault': isDefaultLocal,
                    },
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(bottom: 10),
            // width: narrowScreenWidthThreshold*1.2,
            child: Row(
              children: [
                SizedBox(width: 10),
                SizedBox(
                  height: 35,
                  child: Center(
                    child:
                        Text(widget.title, style: AppTheme.bodyLargeTextStyle),
                  ),
                ),
                if (widget.isDefault == true) ...[
                  Spacer(),
                  SizedBox(
                    width: 80,
                    height: 35,
                    child: FloatingActionButton.extended(
                      onPressed: () => _showDialog(),
                      tooltip: '필드명 추가',
                      icon: const Icon(Icons.add, color: AppTheme.primaryColor),
                      label: const Text(
                        'Add',
                        style: TextStyle(color: AppTheme.primaryColor),
                      ),
                      backgroundColor: AppTheme.buttonlightbackgroundColor,
                    ),
                  ),
                ]
              ],
            ),
          ),
          StreamBuilder(
            stream: firestoreService.getConditionSnapshot(
                'Fields', {'IsDefault': widget.isDefault}),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              // Firestore에서 받아온 문서 리스트
              final List<DocumentSnapshot> docs = snapshot.data!.docs.toList();

              // 추가정보(즉, IsDefault가 false)인 경우
              // 'SubItem', 'SubOrder', 'SubName' 키를 가진 항목은 기본 정보이므로 리스트에서 제외
              List<DocumentSnapshot> filteredCategories;
              if (!widget.isDefault) {
                filteredCategories = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final fieldKey = data['FieldKey'] ?? '';
                  return !(fieldKey == 'SubItem' ||
                      fieldKey == 'SubOrder' ||
                      fieldKey == 'SubName');
                }).toList();
              } else {
                filteredCategories = docs;
              }

              // Firestore에 저장된 FieldOrder를 기준으로 정렬
              filteredCategories.sort((a, b) {
                final Map<String, dynamic> dataA =
                    a.data() as Map<String, dynamic>;
                final Map<String, dynamic> dataB =
                    b.data() as Map<String, dynamic>;

                final String orderStrA =
                    dataA['FieldOrder']?.toString() ?? '9999';
                final String orderStrB =
                    dataB['FieldOrder']?.toString() ?? '9999';

                final int orderA = int.tryParse(orderStrA) ?? 9999;
                final int orderB = int.tryParse(orderStrB) ?? 9999;

                return orderA.compareTo(orderB);
              });

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: filteredCategories.length,
                itemBuilder: (context, index) {
                  final category = filteredCategories[index];
                  final categoryData = category.data() as Map<String, dynamic>;
                  bool isDefaultField = categoryData['IsDefault'] ?? false;

                  // 추가정보인 경우 Firestore에 저장된 FieldOrder에서 3을 빼서 표시
                  final int storedOrder = int.tryParse(
                          categoryData['FieldOrder']?.toString() ?? '0') ??
                      0;
                  final String displayOrder = widget.isDefault
                      ? storedOrder.toString()
                      : (storedOrder - 3).toString();

                  return Card(
                    margin:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 0.0),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Wrap(
                                  children: [
                                    Icon(
                                      isDefaultField
                                          ? Icons.loyalty
                                          : Icons.label_important_outline,
                                      color: isDefaultField
                                          ? Colors.yellow
                                          : Colors.blue,
                                    ),
                                    SizedBox(width: 30),
                                    SelectableText(
                                      categoryData['FieldName'] ??
                                          'No Name',
                                      style: AppTheme.bodyMediumTextStyle,
                                    ),
                                    SizedBox(width: 30),
                                    SelectableText(
                                      categoryData['FieldKey'] ?? ' - ',
                                      style: AppTheme.textLabelStyle,
                                    ),
                                  ],
                                ),
                              ),
                             
                            ],
                          ),
                          SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: SelectableText(
                                  'Order > $displayOrder',
                                  style: AppTheme.tagTextStyle
                                      .copyWith(fontSize: 13),
                                ),
                              ),
                              Flexible(
                                child: Wrap(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit,size: 20),
                                      tooltip: '수정',
                                      onPressed: () =>
                                          _showDialog(document: category),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete,size: 20),
                                      tooltip: '삭제',
                                      onPressed: () {
                                        FiDeleteDialog(
                                          context: context,
                                          deleteFunction: () async =>
                                              firestoreService.deleteItem(
                                            collectionName: 'Fields',
                                            documentId: category.id,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }
}
