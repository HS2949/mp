import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';

class Item_Field extends StatefulWidget {
  const Item_Field({super.key});
  @override
  _Item_FieldState createState() => _Item_FieldState();
}

class _Item_FieldState extends State<Item_Field> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fieldController = TextEditingController();
  final firestoreService = FirestoreService();

  void _showDialog({DocumentSnapshot? document}) {
    if (document != null) {
      _nameController.text = document['FieldName'];
      _fieldController.text = document['FieldKey'];
    } else {
      _nameController.clear();
      _fieldController.clear();
    }

    bool isDefault = true; // Local state for the dialog

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(document == null ? 'Add Field' : 'Edit Field'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 10),
                  FilterChip(
                    checkmarkColor: AppTheme.secondaryColor,
                    selectedColor: Colors.yellow,
                    backgroundColor: Colors.white,
                    label: Text(isDefault ? 'Default Field' : 'Resources'),
                    selected: isDefault,
                    onSelected: (selected) {
                      setState(() {
                        isDefault = selected; // Update local state
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Field Name (한글)'),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _fieldController,
                    decoration:
                        InputDecoration(labelText: 'Field Key Name (영문)'),
                  ),
                ],
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
                if (document == null) {
                  firestoreService.addItem(
                    collectionName: 'Fields',
                    data: {
                      'FieldName': _nameController.text,
                      'FieldKey': _fieldController.text,
                      'IsDefault': isDefault, // Save the state
                    },
                    autoGenerateId: true,
                  );
                } else {
                  firestoreService.updateItem(
                    collectionName: 'Fields',
                    documentId: document.id,
                    updatedData: {
                      'FieldName': _nameController.text,
                      'FieldKey': _fieldController.text,
                      'IsDefault': isDefault, // Save the state
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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 500,
              child: Row(
                children: [
                  SizedBox(width: 10),
                  Text('Fields  -  ', style: AppTheme.titleLarge.copyWith(color: AppTheme.buttonbackgroundColor)),
                  Text('Default', style: AppTheme.headlineSmall),
                  Spacer(),
                  SizedBox(
                    width: 100,
                    height: 40,
                    child: TextButton.icon(
                      label: Text('Add',
                          style: AppTheme.titleMedium
                              .copyWith(color: AppTheme.backgroundColor)),
                      style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                              AppTheme.buttonbackgroundColor),
                          overlayColor:
                              WidgetStateProperty.all(AppTheme.secondaryColor)),
                      icon: Icon(
                        Icons.add,
                        size: 20,
                        color: AppTheme.backgroundColor,
                      ),
                      onPressed: () => _showDialog(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: firestoreService.getItemsSnapshot('Fields'),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
      
                  final categories = snapshot.data!.docs;
      
                  return Container(
                    width: 500,
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final categoryData =
                            category.data() as Map<String, dynamic>;
      
                        return Card(
                          margin: EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 0.0),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(Icons.loyalty, color: Colors.yellow),
                                    SizedBox(width: 20),
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        categoryData['FieldName'] ?? 'No Name',
                                        style: AppTheme.titleMedium,
                                      ),
                                    ),
                                    SizedBox(width: 30),
                                    Text(
                                      categoryData['FieldKey'] ?? ' - ',
                                      style: AppTheme.titleMedium,
                                    ),
                                    Spacer(), // 텍스트와 아이콘 버튼 사이의 공간을 채움
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () =>
                                          _showDialog(document: category),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        firestoreService.deleteItem(
                                          collectionName: 'Fields',
                                          documentId: category.id,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.0),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'ID: ${category.id}',
                                        style: AppTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
