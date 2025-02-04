import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:provider/provider.dart';

import 'Item_detail_provider.dart';
import 'Item_detail_state.dart';

class ItemDetailFirst extends StatefulWidget {
  const ItemDetailFirst({Key? key, required this.itemId}) : super(key: key);
  final String itemId;

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
    Future.microtask(() {
      Provider.of<ItemDetailProvider>(context, listen: false)
          .listenToItemDetail(itemId: widget.itemId);
    });
  }

  @override
  void dispose() {
    Provider.of<ItemDetailProvider>(context, listen: false)
        .cancelSubscriptions();
    _focusNode.dispose();
    super.dispose();
  }

  /// ESC 키와 모바일 뒤로가기 버튼 클릭 시 동일한 동작 수행
  void _handleCloseTab() {
    // 현재 탭을 닫고 0번 탭으로 이동
    if (provider.selectedIndex > 0) {
      provider.removeTab(provider.selectedIndex);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 자동으로 포커스를 요청하여 ESC 키가 초기 상태에서도 인식되도록 함
    if (provider.selectedIndex > 0) {
      Future.microtask(() => FocusScope.of(context).requestFocus(_focusNode));
    }
  }

  /// ESC 키 감지
  void _onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _handleCloseTab(); // ESC 키가 눌리면 탭 닫기
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemDetailProvider>();
    final itemData = provider.itemData;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop) {
            Navigator.of(context).pop();
          }
        },
        child: Consumer<ItemDetailProvider>(
          builder: (context, provider, child) {
            final state = provider.state;

            if (state.itemDetailStatus == ItemDetailStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.itemDetailStatus == ItemDetailStatus.loaded) {
              return Column(
                children: [
                  TextField(),
                  itemData == null
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('이름: ${itemData.itemName}'),
                            Text('카테고리: ${itemData.categoryID}'),
                            for (var entry in itemData.fields.entries)
                              Text('  • ${entry.key}: ${entry.value}'),
                            const SizedBox(height: 20),
                            const Text('🔹 하위 아이템 목록',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            for (var subItem in itemData.subItems)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('🔹아이템: ${subItem.id}'),
                                  for (var entry in subItem.fields.entries)
                                    Text('  • ${entry.key}: ${entry.value}'),
                                ],
                              ),
                          ],
                        ),
                ],
              );
            }

            if (state.itemDetailStatus == ItemDetailStatus.error) {
              return Text('에러 발생: ${state.error.message}',
                  style: const TextStyle(color: Colors.red));
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
