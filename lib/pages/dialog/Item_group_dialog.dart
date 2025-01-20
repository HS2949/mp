import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';

class Item_Group extends StatefulWidget {
  const Item_Group({super.key});
  @override
  _Item_GroupState createState() => _Item_GroupState();
}

class _Item_GroupState extends State<Item_Group> {
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
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Category Name'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Categories'),
      ),
      body: StreamBuilder(
        stream: firestoreService.getItemsSnapshot('Categories'),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data!.docs;

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final categoryData = category.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(getIconFromString(category['Icon']),
                              color: hexToColor(category['Color']), size: 50),
                          SizedBox(width: 50),
                          Text(
                            categoryData['CategoryName'] ?? 'No Name',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Spacer(), // 텍스트와 아이콘 버튼 사이의 공간을 채움
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _showDialog(document: category),
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
          );
        },
      ),
      floatingActionButton: SizedBox(
        width: 80, // 원하는 너비
        height: 30, // 원하는 높이
        child: FloatingActionButton.extended(
          onPressed: () => _showDialog(),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add,size: 10),
              SizedBox(width: 10),
              Text('Add',style: AppTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
