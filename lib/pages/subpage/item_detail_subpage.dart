import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:provider/provider.dart';

import '../../providers/Item_detail/Item_detail_provider.dart';
import '../../providers/Item_detail/Item_detail_state.dart';
import '../../models/item_model.dart';

class ItemDetailFirst extends StatefulWidget {
  const ItemDetailFirst(
      {Key? key, required this.itemId, required this.isFirstView})
      : super(key: key);

  final String itemId;
  final bool isFirstView; // 🔹 true: fields 표시 / false: sub_items 표시

  @override
  State<ItemDetailFirst> createState() => _ItemDetailFirstState();
}

class _ItemDetailFirstState extends State<ItemDetailFirst> {
  final FocusNode _focusNode = FocusNode();
  late final ItemProvider provider;

  @override
  void initState() {
    super.initState();
    provider = Provider.of<ItemProvider>(context, listen: false);

    // 🔹 Firestore 조회를 한 번만 수행 (ID 변경 시만 다시 실행)
    Future.microtask(() {
      Provider.of<ItemDetailProvider>(context, listen: false)
          .listenToItemDetail(itemId: widget.itemId);
    });
  }

  @override
  void dispose() {
    Provider.of<ItemDetailProvider>(context, listen: false)
        .cancelSubscription(widget.itemId);
    _focusNode.dispose();
    super.dispose();
  }

  /// ESC 키와 모바일 뒤로가기 버튼 클릭 시 동일한 동작 수행bool _isClosing = false; // 중복 호출 방지 플래그
  void _handleCloseTab() {
    if (provider.selectedIndex > 0) {
      provider.removeTab(provider.selectedIndex);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (provider.selectedIndex > 0) {
      Future.microtask(() => FocusScope.of(context).requestFocus(_focusNode));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ItemDetailProvider>().getState(widget.itemId);
    final itemData = context.watch<ItemDetailProvider>().getItemData(widget.itemId);

    if (state.itemDetailStatus == ItemDetailStatus.loading) {
      return widget.isFirstView
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    strokeWidth: 4.0,
                  ),
                ),
              ),
            )
          : SizedBox.shrink();
    }

    if (state.itemDetailStatus == ItemDetailStatus.error) {
      return widget.isFirstView
          ? Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('에러 발생: ${state.error.message}',
                  style: const TextStyle(color: Colors.red)),
            )
          : SizedBox.shrink();
    }

    return itemData == null
        ? const Center(child: CircularProgressIndicator())
        : widget.isFirstView
            ? KeyboardListener(
                focusNode: _focusNode,
                onKeyEvent: (KeyEvent event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.escape) {
                    _handleCloseTab(); // ESC 키 동작 실행
                  }
                },
                child: PopScope(
                    canPop: false,
                    onPopInvoked: (didPop) {
                      if (!didPop) {
                        // _handleCloseTab();
                        provider.selectTab(0);
                      }
                    },
                    child: _buildFirstView(itemData)),
              )
            : _buildSecondView(itemData);
  }

  /// 🔹 `first` UI - fields 표시
  Widget _buildFirstView(Item item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📌 기본 정보',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text('이름: ${item.itemName}'),
        Text('카테고리: ${item.categoryID}'),
        for (var entry in item.fields.entries)
          Text('  • ${entry.key}: ${entry.value}'),
      ],
    );
  }

  /// 🔹 `second` UI - sub_items 표시
  Widget _buildSecondView(Item item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🔹 하위 아이템 목록',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        for (var subItem in item.subItems)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🔹 ${subItem.id}'),
              for (var entry in subItem.fields.entries)
                Text('  • ${entry.key}: ${entry.value}'),
            ],
          ),
      ],
    );
  }
}
