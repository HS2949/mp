// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/pages/home.dart';
import 'package:mp_db/pages/subpage/item_category_subpage.dart';
import 'package:mp_db/pages/subpage/item_field_subpage.dart';
import 'package:mp_db/pages/subpage/item_subpage.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:mp_db/utils/two_line.dart';
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
              child: OneTwoTransition(
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
      Item_Field(title: 'Default', isDefault: true),
      if (!showSecondList) ...[
        Item_Field(title: 'Resources', isDefault: false),
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
      Item_Field(title: 'Resources', isDefault: false),
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
  final FocusNode _focusNode = FocusNode(); // 키보드 이벤트 감지를 위한 FocusNode 생성

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

    Provider.of<ItemProvider>(context, listen: false).showSnackbar =
        (context, message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    };
  }

  /// TabBar에 전달할 탭 목록 생성
  /// 활성 탭은 실제 제목을 표시하고, 비활성 탭은 SizedBox.shrink()를 사용해 최소한의 공간만 차지
  List<Widget> get tabs {
    final tabProvider = Provider.of<ItemProvider>(context, listen: false);

    return List.generate(tabProvider.maxTabs, (index) {
      if (index < tabProvider.activeTabCount) {
        return SizedBox(
          width: 100,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (tabProvider.tabTitles[index].icon != null) ...[
                tabProvider.tabTitles[index].icon!,
                SizedBox(width: 8), // 아이콘과 텍스트 간격
              ],
              Text(tabProvider.tabTitles[index].text),
              if (index != 0) ...[
                // 0번 탭이 아닐 때 X 버튼 추가
                SizedBox(width: 5),
                _buildCloseButton(index, tabProvider),
              ],
            ],
          ),
        );
      } else {
        return Tab(child: SizedBox.shrink());
      }
    });
  }

// X 버튼에 마우스 오버 효과 추가
  Widget _buildCloseButton(int index, ItemProvider tabProvider) {
    return MouseRegion(
      onEnter: (_) => tabProvider.setHoverIndex(index), // 마우스 올릴 때
      onExit: (_) => tabProvider.setHoverIndex(-1), // 마우스 벗어날 때
      child: GestureDetector(
        onTap: () {
          tabProvider.removeTab(index); // 탭 닫기
        },
        child: Consumer<ItemProvider>(
          builder: (context, provider, child) {
            return Icon(
              Icons.close,
              size: 16,
              color: provider.hoverIndex == index
                  ? AppTheme.errorColor
                  : Colors.grey[300], // 마우스 오버 시 빨간색
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('현재 페이지 : Item');

    // Provider에서 관리하는 TabController와 탭 리스트를 사용합니다.
    final tabProvider = Provider.of<ItemProvider>(context);

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.f3) {
          tabProvider.selectTab(0); // 0번 탭 선택
          tabProvider.focusSearchField();
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
                            widget_second: tabProvider.tabViews[index].second),
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
            ? null // `controller`가 `null`이면 버튼 표시 안 함
            : AnimatedBuilder(
                animation: tabProvider.controller!,
                builder: (context, child) {
                  return (tabProvider.controller?.index ?? -1) ==
                          0 // 탭 인덱스가 1일 때만 표시
                      ? FloatingActionButton(
                          onPressed: () => showAddItem(context),
                          child: const Icon(Icons.add),
                        )
                      : SizedBox.shrink(); // 빈 공간 반환 (플로팅 버튼 숨김)
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
      // 커스톰스크롤 사용시 ===== index = 0  리스트 탭일 땐 아래래
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
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final Widget? widget_second;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [widget_second ?? SizedBox.shrink()];
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
