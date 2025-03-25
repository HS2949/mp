// ignore_for_file: non_constant_identifier_names, camel_case_types, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/dialog/dialog_field.dart';
import 'package:mp_db/pages/home.dart';
import 'package:mp_db/pages/subpage/item_detail_subpage.dart';
import 'package:mp_db/pages/subpage/settings/item_category_subpage.dart';
import 'package:mp_db/pages/subpage/settings/item_field_subpage.dart';
import 'package:mp_db/pages/subpage/item_subpage.dart';
import 'package:mp_db/providers/Item_detail/Item_detail_provider.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:mp_db/utils/formatters.dart';
import 'package:mp_db/utils/two_line.dart';
import 'package:mp_db/utils/widget_help.dart';
import 'package:provider/provider.dart';

class Category_Widget extends StatelessWidget {
  final Animation<double> railAnimation;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool showNavBottomBar;
  final bool showMediumSizeLayout;
  final bool showLargeSizeLayout;

  const Category_Widget({
    Key? key,
    required this.railAnimation,
    required this.scaffoldKey,
    required this.showNavBottomBar,
    required this.showMediumSizeLayout,
    required this.showLargeSizeLayout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('현재 페이지 : Home');
    return DefaultTabController(
      length: 2, // 탭 수
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 0, //
          bottom: TabBar(
            indicatorColor: AppTheme.text2Color,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.grey[300],
            indicatorWeight: 4.0,
            labelColor: AppTheme.text2Color,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.list), text: 'Categories'),
              Tab(icon: Icon(Icons.label), text: 'Fields'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1번 탭
            KeepAlivePage(child: Item_Category()),
            // 2번 탭
            KeepAlivePage(
              child: Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  surfaceTintColor: AppTheme.textStrongColor.withOpacity(0.1),
                  title: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('아이템 항목 편집'),
                        SizedBox(
                          width: 80,
                          height: 35,
                          child: FloatingActionButton.extended(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return DialogField(
                                    isDefault:
                                        true, // 필요한 경우 기본 정보(true) 또는 추가 정보(false)로 설정
                                    document:
                                        null, // 추가 시 새 항목을 위한 null, 편집 시 해당 DocumentSnapshot 전달
                                  );
                                },
                              );
                            },
                            tooltip: '필드명 추가',
                            icon: const Icon(Icons.add,
                                color: AppTheme.primaryColor),
                            label: const Text(
                              'Add',
                              style: TextStyle(color: AppTheme.primaryColor),
                            ),
                            backgroundColor:
                                AppTheme.buttonlightbackgroundColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                body: OneTwoTransition(
                  animation: railAnimation, // 네비게이션 레일 애니메이션을 적용.
                  one: First_Field_Page(
                    showNavBottomBar: showNavBottomBar, // 네비게이션 바 예제 표시 여부.
                    scaffoldKey: scaffoldKey, // Scaffold 상태를 전달.
                    showSecondList: showMediumSizeLayout || showLargeSizeLayout,
                    // 중간 또는 큰 레이아웃일 때 두 번째 리스트를 표시.
                  ), // 첫 번째 구성 요소 리스트.
                  two: Second_Field_Page(
                    scaffoldKey: scaffoldKey, // Scaffold 상태를 전달.
                  ), // 두 번째 구성 요소 리스트.
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class First_Field_Page extends StatelessWidget {
  const First_Field_Page({
    super.key,
    required this.showNavBottomBar,
    required this.scaffoldKey,
    required this.showSecondList,
  });

  final bool showNavBottomBar;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool showSecondList;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      Item_Field(title: '기본 항목', isDefault: true),
      if (!showSecondList) ...[
        Item_Field(title: '추가 항목', isDefault: false),
      ]
    ];
    List<double?> heights = List.filled(children.length, null);

    // Fully traverse this list before moving on.
    return FocusTraversalGroup(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: showSecondList
                ? const EdgeInsetsDirectional.only(end: smallSpacing)
                : EdgeInsets.zero,
            sliver: SliverList(
              delegate: BuildSlivers(
                heights: heights,
                builder: (context, index) {
                  return CacheHeight(
                    heights: heights,
                    index: index,
                    child: children[index],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Second_Field_Page extends StatelessWidget {
  const Second_Field_Page({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      Item_Field(title: '추가 정보', isDefault: false),
    ];
    List<double?> heights = List.filled(children.length, null);

    // Fully traverse this list before moving on.
    return FocusTraversalGroup(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsetsDirectional.only(end: smallSpacing),
            sliver: SliverList(
              delegate: BuildSlivers(
                heights: heights,
                builder: (context, index) {
                  return CacheHeight(
                    heights: heights,
                    index: index,
                    child: children[index],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Item_Widget extends StatefulWidget {
  final Animation<double> railAnimation;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool showNavBottomBar;
  final bool showMediumSizeLayout;
  final bool showLargeSizeLayout;

  const Item_Widget({
    Key? key,
    required this.railAnimation,
    required this.scaffoldKey,
    required this.showNavBottomBar,
    required this.showMediumSizeLayout,
    required this.showLargeSizeLayout,
  }) : super(key: key);

  @override
  State<Item_Widget> createState() => _Item_WidgetState();
}

class _Item_WidgetState extends State<Item_Widget>
    with SingleTickerProviderStateMixin {
  late List<ValueNotifier<bool>> hoverStates;
  @override
  void initState() {
    super.initState();
    Provider.of<ItemProvider>(context, listen: false).initController(this);

    Provider.of<ItemProvider>(context, listen: false).tabTitles[0].icon = Icon(
      Icons.list,
      color: Colors.grey,
    );
    Provider.of<ItemProvider>(context, listen: false).tabTitles[0].text =
        "List";

    Provider.of<ItemProvider>(context, listen: false).tabViews[0].all =
        ItemList(filterType: 0);
    Provider.of<ItemProvider>(context, listen: false).tabViews[0].first =
        ItemList(filterType: 1);
    Provider.of<ItemProvider>(context, listen: false).tabViews[0].second =
        ItemList(filterType: 2);

    hoverStates = List.generate(
        Provider.of<ItemProvider>(context, listen: false).maxTabs,
        (_) => ValueNotifier(false));
  }

  /// TabBar에 전달할 탭 목록 생성
  /// 활성 탭은 실제 제목을 표시하고, 비활성 탭은 SizedBox.shrink()를 사용해 최소한의 공간만 차지
  List<Widget> get tabs {
    final tabProvider = Provider.of<ItemProvider>(context, listen: false);

    return List.generate(tabProvider.maxTabs, (index) {
      hoverStates[index].value = false;
      if (index < tabProvider.activeTabCount) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 120,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (tabProvider.tabTitles[index].icon != null) ...[
                    tabProvider.tabTitles[index].icon!,
                    SizedBox(width: 8), // 아이콘과 텍스트 간격
                  ],
                  Flexible(
                      child: copyTextWidget(context,
                          text: tabProvider.tabTitles[index].text,
                          widgetType: TextWidgetType.plain)),
                  if (index != 0) ...[
                    // 0번 탭이 아닐 때 X 버튼 추가
                    MouseRegion(
                      onEnter: (_) => hoverStates[index].value = true,
                      onExit: (_) => hoverStates[index].value = false,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: hoverStates[index],
                        builder: (context, isHovered, child) {
                          return IconButton(
                            onPressed: () {
                              tabProvider.removeTab(index);
                            },
                            icon: Icon(
                              Icons.close,
                              color: isHovered
                                  ? AppTheme.errorColor
                                  : AppTheme.textHintColor,
                              size: 16,
                            ),
                            padding:
                                EdgeInsets.symmetric(horizontal: 5), // 내부 여백 제거
                            constraints: BoxConstraints(), // 기본 크기 제한 제거
                          );
                        },
                      ),
                    )
                  ],
                ],
              ),
            ),
          ),
        );
      } else {
        return Tab(child: SizedBox.shrink());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('현재 페이지 : Item');

    // Provider에서 관리하는 TabController와 탭 리스트를 사용합니다.
    final tabProvider = Provider.of<ItemProvider>(context);

    return RawKeyboardListener(
      focusNode: tabProvider.keyboardFocusNode,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          tabProvider.selectTab(0); // 0번 탭 선택
          tabProvider.focusSearchField();
          print("esc 눌림");
        }
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.space) {
          Provider.of<ItemDetailProvider>(context, listen: false)
              .toggleAllItem();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: kToolbarHeight,
          title: Item_page(padding: const EdgeInsets.fromLTRB(5, 5, 0, 0)),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(48),
            child: SizedBox(
              height: 40,
              child: TabBar(
                isScrollable: true,
                controller: tabProvider.controller,
                dividerColor: Colors.grey[300],
                indicatorColor: tabProvider.activeTabCount > 1
                    ? AppTheme.text2Color
                    : Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 4.0,
                labelColor: AppTheme.text2Color,
                unselectedLabelColor: Colors.grey,
                labelStyle: TextStyle(fontSize: 15.0),
                tabs: tabs,
                onTap: (index) {
                  tabProvider.selectTab(index);
                  tabProvider.focusKeyboard();
                },
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: tabProvider.controller,
          children: List.generate(tabProvider.maxTabs, (index) {
            if (index < tabProvider.activeTabCount) {
              return KeepAlivePage(
                child: Column(
                  children: [
                    Expanded(
                      child: OneTwoTransition(
                        animation: widget.railAnimation, // 네비게이션 레일 애니메이션을 적용.
                        one: First_Item_Page(
                          showNavBottomBar:
                              widget.showNavBottomBar, // 네비게이션 바 예제 표시 여부.
                          scaffoldKey: widget.scaffoldKey, // Scaffold 상태를 전달.
                          useScroll: index == 0 ? true : false,
                          showSecondList: widget.showMediumSizeLayout ||
                              widget.showLargeSizeLayout,
                          widget_first: tabProvider.tabViews[index].first,
                          widget_second: tabProvider.tabViews[index].second,
                          widget_all: tabProvider.tabViews[index].all,
                        ),
                        two: Second_Item_Page(
                          scaffoldKey: widget.scaffoldKey,
                          widget_second: tabProvider.tabViews[index].second,
                          useScroll: index == 0 ? true : false,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Container();
            }
          }),
        ),
        floatingActionButton: tabProvider.controller == null
            ? null // controller가 null이면 버튼 표시 안 함
            : AnimatedBuilder(
                animation: tabProvider.controller!,
                builder: (context, child) {
                  if ((tabProvider.controller?.index ?? -1) == 0) {
                    // 탭 인덱스가 0인 경우
                    if (tabProvider.filteredItem.isEmpty) {
                      // filteredItem이 비어있을 때만 "장소 추가" 버튼 표시
                      return FloatingActionButton.extended(
                        heroTag: null,
                        tooltip: 'Add Item',
                        label: Text('장소 추가',
                            style: AppTheme.bodySmallTextStyle.copyWith(
                              color: Colors.white,
                            )),
                        onPressed: () => showAddItem(context, ''),
                        icon: const Icon(
                          Icons.add,
                        ),
                      );
                    } else {
                      // filteredItem에 값이 있다면 아무것도 표시하지 않음
                      return SizedBox.shrink();
                    }
                  } else {
                    // 탭 인덱스가 0이 아닌 경우 "정보 추가" 버튼 표시
                    return SizedBox(
                      height: 42,
                      child: FloatingActionButton.extended(
                        heroTag: null,
                        label: Text('정보 추가', style: TextStyle(fontSize: 13)),
                        backgroundColor: AppTheme.text5Color.withOpacity(0.4),
                        hoverColor: AppTheme.text5Color.withOpacity(0.8),
                        tooltip: '추가 정보 입력',
                        onPressed: () async {
                          await showAddDialogSubItem(
                            context,
                            tabProvider,
                            (tabProvider.tabViews[tabProvider.selectedIndex]
                                    .second as ItemDetailSubpage)
                                .getItemId,
                            null,
                          );
                        },
                        icon: const Icon(
                          Icons.add,
                          size: 13,
                        ),
                      ),
                    );
                  }
                },
              ),
      ),
    );
  }
}

class First_Item_Page extends StatelessWidget {
  const First_Item_Page(
      {super.key,
      required this.showNavBottomBar,
      required this.scaffoldKey,
      required this.showSecondList,
      required this.useScroll,
      required this.widget_first,
      this.widget_second,
      this.widget_all});

  final bool showNavBottomBar;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool useScroll;
  final bool showSecondList;
  final Widget widget_first;
  final Widget? widget_second;
  final Widget? widget_all;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      //위젯 입력

      if (!showSecondList) ...[
        if (widget_all == null) ...[
          widget_first,
          widget_second ?? SizedBox.shrink()
        ] else ...[
          widget_all ?? SizedBox.shrink()
        ]
      ] else ...[
        widget_first
      ]
    ];
    List<double?> heights = List.filled(children.length, null);

    // CustomScrollView 제거 후 Column으로 변경
    if (!useScroll) {
      // 스크롤 없이 사용
      return FocusTraversalGroup(
        child: Column(
          children: List.generate(children.length, (index) {
            return Expanded(
              child: CacheHeight(
                heights: heights,
                index: index,
                child: children[index],
              ),
            );
          }),
        ),
      );
    } else {
      // 커스톰스크롤 사용시 ---------------------
      // Case : index = 0  리스트 탭 ☞ 스크롤 사용
      // Fully traverse this list before moving on.
      return FocusTraversalGroup(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: showSecondList
                  ? const EdgeInsetsDirectional.only(end: smallSpacing)
                  : EdgeInsets.zero,
              sliver: SliverList(
                delegate: BuildSlivers(
                  heights: heights,
                  builder: (context, index) {
                    return CacheHeight(
                      heights: heights,
                      index: index,
                      child: children[index],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

class Second_Item_Page extends StatelessWidget {
  const Second_Item_Page({
    super.key,
    required this.scaffoldKey,
    required this.widget_second,
    required this.useScroll,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final Widget? widget_second;
  final bool useScroll;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [widget_second ?? SizedBox.shrink()];
    List<double?> heights = List.filled(children.length, null);

    // CustomScrollView 제거 후 Column으로 변경
    if (!useScroll) {
      // 스크롤 없이 사용
      return FocusTraversalGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Column의 크기를 children에 맞춤
          children: List.generate(children.length, (index) {
            return Expanded(
              child: CacheHeight(
                heights: heights,
                index: index,
                child: children[index],
              ),
            );
          }),
        ),
      );
    } else {
      // 커스톰스크롤 사용시 ---------------------
      // Case : index = 0  리스트 탭 ☞ 스크롤 사용
      // Fully traverse this list before moving on.
      return FocusTraversalGroup(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding:
                  const EdgeInsetsDirectional.only(end: 0.0), //smallSpacing
              sliver: SliverList(
                delegate: BuildSlivers(
                  heights: heights,
                  builder: (context, index) {
                    return CacheHeight(
                      heights: heights,
                      index: index,
                      child: children[index],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
