// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:mp_db/constants/styles.dart';
// import 'package:mp_db/providers/Item_provider.dart';
// import 'package:provider/provider.dart';

// class ItemDetailScreen extends StatefulWidget {
//   final String itemId;

//   const ItemDetailScreen({super.key, required this.itemId});

//   @override
//   State<ItemDetailScreen> createState() => _ItemDetailScreenState();
// }

// class _ItemDetailScreenState extends State<ItemDetailScreen>
//     with TickerProviderStateMixin {
//   late Future<DocumentSnapshot> _future;
//   final FocusNode _focusNode = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     _future = _fetchItemDetails();
//     _focusNode.requestFocus();
//   }

//   @override
//   void dispose() {
//     _focusNode.dispose();
//     super.dispose();
//   }

//   Future<DocumentSnapshot> _fetchItemDetails() {
//     return FirebaseFirestore.instance
//         .collection('Items')
//         .doc(widget.itemId)
//         .get();
//   }

//   void _refreshScreen() {
//     setState(() {
//       _future = _fetchItemDetails();
//     });
//   }

//   ///  ESC 키와 모바일 뒤로가기 버튼 클릭 시 동일한 동작 수행
//   void _handleCloseTab() {
//     final provider = Provider.of<ItemProvider>(context, listen: false);
//     final currentIndex = provider.selectedIndex;

//     // 현재 탭을 닫고 0번 탭으로 이동
//     if (currentIndex > 0) {
//       // provider.removeTab(currentIndex, this);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<ItemProvider>(context, listen: false);
//     return PopScope(
//       canPop: false,
//       onPopInvoked: (didPop) {
//         if (!didPop) {
//           _handleCloseTab(); //  ESC 키와 동일한 동작 수행
//         }
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           automaticallyImplyLeading: false,
//           title: const Text('Item Details'),
//         ),
//         body: KeyboardListener(
//           focusNode: _focusNode,
//           onKeyEvent: (KeyEvent event) {
//             if (event is KeyDownEvent &&
//                 event.logicalKey == LogicalKeyboardKey.escape) {
//               _handleCloseTab(); // ESC 키 동작 실행
//             }

//             // Tab 키 입력 시 0번 탭으로 이동
//             if (event is KeyDownEvent &&
//                 event.logicalKey == LogicalKeyboardKey.f3) {
//               provider.selectTab(0); // 0번 탭 선택
//               provider.focusSearchField();
//             }
//           },
//           child: FutureBuilder<DocumentSnapshot>(
//             future: _future,
//             builder: (context, snapshot) {
//               if (!snapshot.hasData) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//               final data = snapshot.data!.data() as Map<String, dynamic>;

//               Widget buildDataItem(String title, String? value) {
//                 if (value == null || value.isEmpty) {
//                   return const SizedBox.shrink();
//                 }
//                 final combinedText = '$title: $value';
//                 return GestureDetector(
//                   onLongPress: () {
//                     Clipboard.setData(ClipboardData(text: combinedText));
//                     final snackBar = SnackBar(
//                       behavior: SnackBarBehavior.floating,
//                       backgroundColor: AppTheme.primaryColor,
//                       width: 400.0,
//                       content: Text('[ $combinedText ]  복사되었습니다.'),
//                       action: SnackBarAction(
//                         label: 'Close',
//                         onPressed: () {},
//                       ),
//                     );

//                     ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                     ScaffoldMessenger.of(context).showSnackBar(snackBar);
//                   },
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       SelectableText(
//                         '$title: ',
//                         style: const TextStyle(
//                             fontSize: 16, fontWeight: FontWeight.bold),
//                       ),
//                       Expanded(
//                         child: SelectableText(
//                           value,
//                           style: const TextStyle(fontSize: 16),
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.copy),
//                         onPressed: () {
//                           Clipboard.setData(ClipboardData(text: combinedText));
//                           showTemporaryPopup(context, combinedText);
//                         },
//                       ),
//                     ],
//                   ),
//                 );
//               }

//               return ListView(
//                 padding: const EdgeInsets.all(16.0),
//                 children: [
//                   TextField(),
//                   const SizedBox(height: 10),
//                   buildDataItem('상호명', data['ItemName']),
//                   const SizedBox(height: 10),
//                   buildDataItem('주소', data['Location']),
//                   const SizedBox(height: 10),
//                   buildDataItem('전화번호', data['PhoneNumber']),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       showEditDialog(context, widget.itemId, data);
//                     },
//                     child: const Text('Edit'),
//                   ),
//                   const SizedBox(height: 10),
//                   ElevatedButton(
//                     style:
//                         ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                     onPressed: () {
//                       showDeleteConfirmation(context, widget.itemId);
//                     },
//                     child: const Text('Delete'),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   // Other methods remain unchanged

//   void showEditDialog(
//       BuildContext context, String itemId, Map<String, dynamic> data) {
//     final TextEditingController nameController =
//         TextEditingController(text: data['ItemName']);
//     final TextEditingController locationController =
//         TextEditingController(text: data['Location']);
//     final TextEditingController phoneController =
//         TextEditingController(text: data['PhoneNumber']);

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Edit Item'),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: nameController,
//                   decoration: const InputDecoration(labelText: 'Name'),
//                 ),
//                 const SizedBox(height: 10),
//                 TextField(
//                   controller: locationController,
//                   decoration: const InputDecoration(labelText: 'Location'),
//                 ),
//                 const SizedBox(height: 10),
//                 TextField(
//                   controller: phoneController,
//                   decoration: const InputDecoration(labelText: 'Phone Number'),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 await FirebaseFirestore.instance
//                     .collection('Items')
//                     .doc(itemId)
//                     .update({
//                   'ItemName': nameController.text,
//                   'Location': locationController.text,
//                   'PhoneNumber': phoneController.text,
//                 });
//                 Navigator.pop(context);
//                 _refreshScreen();
//               },
//               child: const Text('Save'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void showDeleteConfirmation(BuildContext context, String itemId) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Delete Item'),
//           content: const Text('Are you sure you want to delete this item?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 await FirebaseFirestore.instance
//                     .collection('Items')
//                     .doc(itemId)
//                     .delete();
//                 Navigator.pop(context);
//                 Navigator.pop(context);
//               },
//               style: TextButton.styleFrom(foregroundColor: Colors.red),
//               child: const Text('Delete'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void showTemporaryPopup(BuildContext context, String message) {
//     final overlay = Overlay.of(context);
//     final overlayEntry = OverlayEntry(
//       builder: (context) => FadeOutPopup(message: message),
//     );

//     overlay.insert(overlayEntry);

//     Future.delayed(const Duration(seconds: 1), () {
//       overlayEntry.remove();
//     });
//   }
// }

// class FadeOutPopup extends StatefulWidget {
//   final String message;

//   const FadeOutPopup({super.key, required this.message});

//   @override
//   State<FadeOutPopup> createState() => _FadeOutPopupState();
// }

// class _FadeOutPopupState extends State<FadeOutPopup>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeOut),
//     );

//     Future.delayed(const Duration(milliseconds: 200), () {
//       _controller.forward();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Positioned.fill(
//       child: FadeTransition(
//         opacity: _fadeAnimation,
//         child: Center(
//           child: Container(
//             padding: const EdgeInsets.all(16.0),
//             decoration: BoxDecoration(
//               color: Colors.black.withOpacity(0.7),
//               borderRadius: BorderRadius.circular(8.0),
//             ),
//             child: Text(
//               widget.message,
//               style: const TextStyle(fontSize: 16, color: Colors.white),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }
