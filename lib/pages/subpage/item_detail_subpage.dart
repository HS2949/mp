import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:provider/provider.dart';

import '../../providers/Item_detail/Item_detail_provider.dart';
import '../../providers/Item_detail/Item_detail_state.dart';
import '../../models/item_model.dart';

class ItemDetailSubpage extends StatefulWidget {
  const ItemDetailSubpage(
      {super.key, required this.itemId, required this.isFirstView});

  final String itemId;
  final bool isFirstView; // 🔹 true: fields 표시 / false: sub_items 표시

  @override
  State<ItemDetailSubpage> createState() => _ItemDetailSubpageState();
}

class _ItemDetailSubpageState extends State<ItemDetailSubpage> {
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

    // // 🔹 initState에서 포커스 요청
    // Future.delayed(Duration(milliseconds: 100), () {
    //   FocusScope.of(context).requestFocus(_focusNode);
    // });
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
    // // 🔹 키보드 입력을 항상 받을 수 있도록 설정
    // if (provider.selectedIndex > 0) {
    //   Future.microtask(() => FocusScope.of(context).requestFocus(_focusNode));
    // }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ItemDetailProvider>().getState(widget.itemId);
    final itemData =
        context.watch<ItemDetailProvider>().getItemData(widget.itemId);

    if (state.itemDetailStatus == ItemDetailStatus.loading) {
      return widget.isFirstView
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(50.0),
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
              padding: const EdgeInsets.all(50.0),
              child: Text('에러 발생: ${state.error.message}',
                  style: const TextStyle(color: Colors.red)),
            )
          : SizedBox.shrink();
    }

    return itemData == null
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(50.0),
              child: SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  strokeWidth: 4.0,
                ),
              ),
            ),
          )
        : widget.isFirstView
            ? _buildFirstView(itemData)
            : _buildSecondView(itemData);
  }

  /// 🔹 `first` UI - fields 표시
  Widget _buildFirstView(Item item) {
    final matchedCategory = provider.categories.firstWhere(
      (cat) => cat['itemID'] == item.categoryID,
      orElse: () => {'Color': 'Silver', 'Icon': 'List'},
    );

    final color = ColorLabel.values
        .firstWhere((e) => e.label == matchedCategory['Color'],
            orElse: () => ColorLabel.silver)
        .color;
    final icon = IconLabel.values
        .firstWhere((e) => e.label == matchedCategory['Icon'],
            orElse: () => IconLabel.smile)
        .icon;

    double screenWidth = MediaQuery.of(context).size.width;
    return KeyboardListener(
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
            //_handleCloseTab();
            provider.selectTab(0);
          }
        },
        child: Padding(
          padding: screenWidth < 500
              ? const EdgeInsets.fromLTRB(5, 5, 5, 0) // 1단
              : const EdgeInsets.fromLTRB(5, 5, 0, 5), // 2단
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(icon, color: color, size: 50),
                      SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText('${matchedCategory['Name']}',
                              style: AppTheme.textHintTextStyle),
                          SelectableText('${item.itemName}',
                              style: AppTheme.titleLargeTextStyle),
                        ],
                      ),
                      SizedBox(width: 30),
                      Flexible(
                        child: SelectableText(
                          '${item.itemTag}',
                          style: AppTheme.tagTextStyle,
                          maxLines: 2,
                          textAlign: TextAlign.justify,
                          cursorColor: AppTheme.text6Color, // 선택 커서 색상
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                SingleChildScrollView(
                  child: Wrap(
                    spacing: 5.0, // 가로 간격
                    runSpacing: 5.0, // 세로 간격
                    children: [
                      for (var entry in item.fields.entries)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // 텍스트 길이에 따라 카드의 너비를 동적으로 설정
                            final dynamicWidth = (entry.value.length * 11.0)
                                .clamp(
                                    150.0,
                                    constraints.maxWidth *
                                        0.8); // 최소 150, 최대 화면의 80%

                            return Card(
                              elevation: 3, // 그림자 효과 추가
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12.0), // 모서리 둥글게
                              ),
                              child: Container(
                                width: dynamicWidth, // 동적으로 계산된 카드 너비 적용
                                padding: EdgeInsets.all(10), // 내부 패딩 추가
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start, // 라벨 정렬
                                  children: [
                                    Text(entry.key, // 라벨 표시
                                        style: AppTheme.fieldTextStyle),
                                    SizedBox(height: 5), // 라벨과 입력 필드 사이 간격
                                    TextField(
                                      controller: TextEditingController(
                                        text: entry
                                            .value, // entry.value를 초기값으로 설정
                                      ),
                                      readOnly: true, // 값 수정 불가
                                      decoration: InputDecoration(
                                        border: InputBorder.none, // 테두리 제거
                                        enabledBorder: InputBorder
                                            .none, // 활성화 상태에서도 테두리 없음
                                        focusedBorder: InputBorder
                                            .none, // 포커스 상태에서도 테두리 없음
                                        contentPadding:
                                            EdgeInsets.zero, // 내부 패딩 제거
                                        isDense: true, // 추가 패딩 제거
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 `second` UI - sub_items 표시
  Widget _buildSecondView(Item item) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: screenWidth < 500
          ? const EdgeInsets.fromLTRB(5, 0, 5, 5) // 1단
          : const EdgeInsets.fromLTRB(0, 5, 0, 5), // 2단
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
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
          ),
        ),
      ),
    );
  }
}
