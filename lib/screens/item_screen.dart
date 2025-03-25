import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';


class ItemScreen extends StatefulWidget {
  const ItemScreen({super.key});

  @override
  ItemScreenState createState() => ItemScreenState();
}

class ItemScreenState extends State<ItemScreen> {
  bool _showOdd = true; // 초기 상태: 홀수 카드 표시
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
              SingleChildScrollView(
                child: Wrap(
                  spacing: 4.0, // 가로 간격
                  runSpacing: 4.0, // 세로 간격

                  children: List.generate(5, (index) {
                        String restaurantName = 'Restaurant $index';
                        String address = '123 Street, City $index';
                        String phone = '010-1234-56$index';
                    return Container(
                      width: 200,
                      height: 100,
                      // color: Colors.blue,
                      child: Card(
                              color: Colors.greenAccent,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.restaurant,
                                        size: 40, color: Colors.white),
                                    SizedBox(height: 8),
                                    Text(
                                      restaurantName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      address,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      phone,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    );
                  }),
                ),
              ),
              Column(
                children: [
                  // Switch와 상태를 나타내는 텍스트
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Show Odd',
                        style: TextStyle(fontSize: 16),
                      ),
                      Switch(
                        value: _showOdd,
                        onChanged: (value) {
                          setState(() {
                            _showOdd = value; // 스위치 상태 변경
                          });
                        },
                      ),
                      Text(
                        'Show Even',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  // GridView를 포함하는 컨테이너
                  Container(
                    width: 1200,
                    height: 100,
                    child: GridView.count(
                      crossAxisCount: 7, // 가로 열 개수
                      crossAxisSpacing: 8.0, // 열 간격
                      mainAxisSpacing: 8.0, // 행 간격
                      padding: EdgeInsets.all(8.0),
                      children: List.generate(9, (index) {
                        int number = index + 1; // 1부터 9까지의 숫자 생성
                        String restaurantName = 'Restaurant $number';
                        String address = '123 Street, City $number';
                        String phone = '010-1234-56$number';

                        if (_showOdd && number % 2 != 0) {
                          // 홀수 카드 표시
                          return GestureDetector(
                            onTap: () {
                              // 클릭 시 다이얼로그 띄움
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Restaurant Clicked'),
                                  content:
                                      Text('You clicked on $restaurantName'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // 다이얼로그 닫기
                                      },
                                      child: Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Card(
                              color: Colors.greenAccent,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.restaurant,
                                        size: 40, color: Colors.white),
                                    SizedBox(height: 8),
                                    Text(
                                      restaurantName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      address,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      phone,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } else if (!_showOdd && number % 2 == 0) {
                          // 짝수 카드 표시
                          return GestureDetector(
                            onTap: () {
                              // 클릭 시 다이얼로그 띄움
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Restaurant Clicked'),
                                  content:
                                      Text('You clicked on $restaurantName'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // 다이얼로그 닫기
                                      },
                                      child: Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Card(
                              color: Colors.blueAccent,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.restaurant,
                                        size: 40, color: Colors.white),
                                    SizedBox(height: 8),
                                    Text(
                                      restaurantName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      address,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      phone,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } else {
                          // 조건에 맞지 않는 경우 빈 위젯 반환
                          return SizedBox.shrink();
                        }
                      }).where((widget) => widget is! SizedBox).toList(),
                    ),
                  ),
                ],
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
                                    style: AppTheme.bodyMediumTextStyle),
                                subtitle: Text(data['Location'],
                                    style: AppTheme.bodyMediumTextStyle),
                                onTap: () {
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //     builder: (context) => ItemDetailScreen(
                                  //         itemId: items[index].id),
                                  //   ),
                                  // );
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
