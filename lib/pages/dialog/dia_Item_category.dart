import 'package:flutter/material.dart';

class Item {
  int id;
  String koreanName;
  String englishName;
  bool isDefault;
  int groupCount;

  Item({
    required this.id,
    required this.koreanName,
    required this.englishName,
    required this.isDefault,
    required this.groupCount,
  });
}

class Item_category extends StatefulWidget {
  const Item_category({super.key});

  @override
  _Item_categoryState createState() => _Item_categoryState();
}

class _Item_categoryState extends State<Item_category> {
  final _formKey = GlobalKey<FormState>();

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  List<Item> items = [];
  int nextId = 0;

  // Controllers for input fields
  final TextEditingController koreanNameController = TextEditingController();
  final TextEditingController englishNameController = TextEditingController();
  final WidgetStateProperty<Icon?> thumbIcon =
      WidgetStateProperty.resolveWith<Icon?>((states) {
    if (states.contains(WidgetState.selected)) {
      return const Icon(Icons.check);
    }
    return const Icon(Icons.close);
  });

  bool isDefault = false;
  int groupCount = 0;

  // Add or Edit Item
  void showItemDialog({Item? item}) {
  if (item != null) {
    koreanNameController.text = item.koreanName;
    englishNameController.text = item.englishName;
    isDefault = item.isDefault;
    groupCount = item.groupCount;
  } else {
    koreanNameController.clear();
    englishNameController.clear();
    isDefault = false;
    groupCount = 0;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter dialogSetState) {
          return AlertDialog(
            title: Text(item == null ? "아이템 항목 추가" : "아이템 항목 수정"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: koreanNameController,
                  decoration: InputDecoration(labelText: "항목명(한글)"),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: englishNameController,
                  decoration: InputDecoration(labelText: "항목명(영어)"),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Default"),
                    Switch(
                      value: isDefault,
                      onChanged: (bool value) {
                        dialogSetState(() {
                          isDefault = value;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('Count : ${groupCount}')
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("취소"),
              ),
              TextButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? true) {
                    if (item == null) {
                      // New item
                      setState(() {
                        items.add(
                          Item(
                            id: nextId++,
                            koreanName: koreanNameController.text,
                            englishName: englishNameController.text,
                            isDefault: isDefault,
                            groupCount: groupCount,
                          ),
                        );
                      });
                    } else {
                      // Update existing item
                      setState(() {
                        item.koreanName = koreanNameController.text;
                        item.englishName = englishNameController.text;
                        item.isDefault = isDefault;
                        item.groupCount = groupCount;
                      });
                    }
                    Navigator.of(context).pop();
                  }
                },
                child: Text("저장"),
              ),
            ],
          );
        },
      );
    },
  );
}


  // Delete Item
  void deleteItem(int id) {
    setState(() {
      items.removeWhere((item) => item.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("아이템 항목 관리"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => showItemDialog(),
                child: Text("Item Add"),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text("${item.koreanName} (${item.englishName})"),
                  subtitle: Text(
                      "Default : ${item.isDefault ? "Yes" : "No"}  |  소속 개수: ${item.groupCount}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => showItemDialog(item: item),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => deleteItem(item.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
