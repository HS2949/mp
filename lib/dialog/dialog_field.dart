import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/utils/widget_help.dart';

class DialogField extends StatefulWidget {
  final bool isDefault;
  final DocumentSnapshot? document;

  const DialogField({
    Key? key,
    required this.isDefault,
    this.document,
  }) : super(key: key);

  @override
  _DialogFieldState createState() => _DialogFieldState();
}

class _DialogFieldState extends State<DialogField> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fieldController = TextEditingController();
  final TextEditingController _orderController = TextEditingController();
  final FirestoreService firestoreService = FirestoreService();
  late bool isDefaultLocal;

  @override
  void initState() {
    super.initState();
    isDefaultLocal = widget.isDefault;

    // 편집 시 기존 데이터 초기화
    if (widget.document != null) {
      _nameController.text = widget.document!['FieldName'];
      _fieldController.text = widget.document!['FieldKey'];
      if (widget.isDefault) {
        _orderController.text = widget.document!['FieldOrder'].toString();
      } else {
        final int firestoreOrder =
            int.tryParse(widget.document!['FieldOrder'].toString()) ?? 0;
        _orderController.text = (firestoreOrder - 3).toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fieldController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(
        widget.document == null ? 'Add Field' : 'Edit Field',
        style: AppTheme.appbarTitleTextStyle,
      ),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
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
                const SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    suffixIcon: ClearButton(controller: _nameController),
                    labelText: 'Field Name',
                    hintText: '예) 주소, 전화번호, 휴무, 메모 ... ',
                    filled: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _fieldController,
                  decoration: InputDecoration(
                    suffixIcon: ClearButton(controller: _fieldController),
                    labelText: 'Field Key',
                    hintText: '예) Address, PhoneNumber, Holiday, Notes ... ',
                    filled: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _orderController,
                  decoration: InputDecoration(
                    suffixIcon: ClearButton(controller: _orderController),
                    labelText: 'Order',
                    hintText: '예) 1, 2, 3, 4.. ',
                    filled: true,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                    child: Text('순번 50 이하만 변경 기록(history)이 표시됩니다.\n30일 이상된 기록은 분홍색 표시됨',
                        style: AppTheme.tagTextStyle.copyWith(fontSize: 11)))
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            int orderInput = int.tryParse(_orderController.text.trim()) ?? 0;
            final String firestoreOrder = isDefaultLocal
                ? orderInput.toString()
                : (orderInput + 3).toString();

            if (widget.document == null) {
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
                documentId: widget.document!.id,
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
          child: const Text('Save'),
        ),
      ],
    );
  }
}
