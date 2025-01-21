import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';

class Item_Category extends StatefulWidget {
  const Item_Category({super.key});
  @override
  _Item_CategoryState createState() => _Item_CategoryState();
}

// color 와 아이콘, firebsae 기본 세팅용
// FFA500
// directions_bus
// 800080
// restaurant
// 00008B
// hotel
class _Item_CategoryState extends State<Item_Category> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _iconController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final firestoreService = FirestoreService();
  void _showDialog({DocumentSnapshot? document}) {
    if (document != null) {
      _nameController.text = document['CategoryName'];
      _iconController.text = document['Icon'];
      _colorController.text = document['Color'];
    } else {
      _nameController.clear();
      _iconController.clear();
      _colorController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(document == null ? 'Add Category' : 'Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Category Name (한글)'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _iconController,
                decoration: InputDecoration(labelText: 'Icon'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _colorController,
                decoration: InputDecoration(labelText: 'HEX Color'),
              ),
            ],
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
                      collectionName: 'Categories',
                      data: {
                        'CategoryName': _nameController.text,
                        'Icon': _iconController.text,
                        'Color': _colorController.text,
                      },
                      autoGenerateId: false);
                } else {
                  firestoreService.updateItem(
                      collectionName: 'Categories',
                      documentId: document.id,
                      updatedData: {
                        'CategoryName': _nameController.text,
                        'Icon': _iconController.text,
                        'Color': _colorController.text
                      });
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
                padding: EdgeInsets.only(bottom: 10),
                width: 500,
                child: Row(
                  children: [
                    Text('Categories',
                        style: AppTheme.titleLarge
                            .copyWith(color: AppTheme.buttonbackgroundColor)),
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
                stream: firestoreService.getItemsSnapshot('Categories'),
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
                                    Icon(getIconFromString(category['Icon']),
                                        color: hexToColor(category['Color']),
                                        size: 50),
                                    SizedBox(width: 50),
                                    Text(
                                      categoryData['CategoryName'] ?? 'No Name',
                                      style: AppTheme.titleMedium.copyWith(
                                          color: hexToColor(category['Color'])),
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
                                          collectionName: 'Categories',
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
                                    SizedBox(width: 20),
                                    Flexible(
                                      child: Text(
                                        'Icon: ${categoryData['Icon'] ?? '-'}',
                                        style: AppTheme.bodySmall,
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    Flexible(
                                      child: Text(
                                        'Color: ${categoryData['Color'] ?? '-'}',
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
            ),
            ],
          )),
    );
  }
}
