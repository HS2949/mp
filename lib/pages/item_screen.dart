import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';
import 'dialog/item_detail_dialog.dart';

class ItemScreen extends StatefulWidget {
  const ItemScreen({super.key});

  @override
  ItemScreenState createState() => ItemScreenState();
}

class ItemScreenState extends State<ItemScreen> {
  String? selectedCategory;
  final Map<String, String> categories = {};
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void fetchCategories() async {
    try {
      final query =
          await FirebaseFirestore.instance.collection('Categories').get();
      if (query.docs.isNotEmpty) {
        final data = query.docs.asMap().map((_, doc) {
          final id = doc.id;
          final categoryName = doc['CategoryName'] as String;
          return MapEntry(id, categoryName);
        });
        setState(() {
          categories.addAll(data);
        });
      } else {
        print('No categories found');
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> addItem(
      String categoryId, String itemName, String location) async {
    await FirebaseFirestore.instance.collection('Items').add({
      'CategoryID': int.parse(categoryId),
      'ItemName': itemName,
      'Location': location,
    });
  }

  void showAddItemPopup() {
    _nameController.clear();
    _locationController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty &&
                    _locationController.text.isNotEmpty &&
                    selectedCategory != null) {
                  addItem(selectedCategory!, _nameController.text,
                          _locationController.text)
                      .then((_) => Navigator.pop(context))
                      .catchError((error) {
                    print('Error adding item: $error');
                  });
                }
              },
              child: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  void showCategorySelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Select a Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...categories.entries.map((entry) {
            return ListTile(
              title: Text(entry.value),
              onTap: () {
                setState(() {
                  selectedCategory = entry.key;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
          SizedBox(height: 30.0)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text('Home Screen'),
        // ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 30.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 300.0,
                  child: ElevatedButton(
                    onPressed: showCategorySelector,
                    child: Text(
                      selectedCategory == null
                          ? 'Select Category'
                          : categories[selectedCategory!]!,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: selectedCategory == null
                    ? const Center(child: Text('Please select a category'))
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('Items')
                            .where('CategoryID',
                                isEqualTo: int.parse(selectedCategory!))
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final items = snapshot.data!.docs;
                          return ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final data =
                                  items[index].data() as Map<String, dynamic>;
                              return ListTile(
                                title: Text(data['ItemName'],
                                    style: AppTheme.subtitleTextStyle),
                                subtitle: Text(data['Location'],style: AppTheme.keyTextStyle),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ItemDetailScreen(
                                          itemId: items[index].id),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: showAddItemPopup,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
