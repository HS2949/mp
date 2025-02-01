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
    return DefaultTabController(
      length: 2, // 탭 수
      child: Expanded(
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: 0, //
            bottom: TabBar(
              indicatorColor: AppTheme.textColor,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 4.0,
              labelColor: AppTheme.textColor,
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
                child: Expanded(
                  // 선택된 화면이 'component'일 때 실행. Expanded로 레이아웃을 확장.
                  child: OneTwoTransition(
                    animation: railAnimation, // 네비게이션 레일 애니메이션을 적용.
                    one: First_Field_Page(
                      showNavBottomBar: showNavBottomBar, // 네비게이션 바 예제 표시 여부.
                      scaffoldKey: scaffoldKey, // Scaffold 상태를 전달.
                      showSecondList:
                          showMediumSizeLayout || showLargeSizeLayout,
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
    with TickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode(); // 키보드 이벤트 감지를 위한 FocusNode 생성
  @override
  void initState() {
    super.initState();
    Provider.of<ItemProvider>(context, listen: false).initTabConfiguration(
      this,
      'List',
      KeepAlivePage(
        child: Flexible(
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 0,
              // title: Item_page(padding: const EdgeInsets.fromLTRB(5, 5, 0, 0)),
            ),
            body: Column(
              children: [
                Expanded(
                  child: OneTwoTransition(
                    animation: widget.railAnimation, // 네비게이션 레일 애니메이션을 적용.
                    one: First_Item_Page(
                      showNavBottomBar:
                          widget.showNavBottomBar, // 네비게이션 바 예제 표시 여부.
                      scaffoldKey: widget.scaffoldKey, // Scaffold 상태를 전달.
                      showSecondList: widget.showMediumSizeLayout ||
                          widget.showLargeSizeLayout,
                    ),
                    two: Second_Item_Page(scaffoldKey: widget.scaffoldKey),
                  ),
                ),
              ],
            ),
            floatingActionButton: Builder(
              builder: (context) {
                return FloatingActionButton(
                  onPressed: () => showAddItem(context),
                  child: const Icon(Icons.add),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provider에서 관리하는 TabController와 탭 리스트를 사용합니다.
    final tabProvider = Provider.of<ItemProvider>(context);
    return Expanded(
      child: KeyboardListener(
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
            // toolbarHeight: 2, //
            // toolbarHeight: tabProvider.tabs.length > 1 ? 2 :
            // 탭이 2개 이상일 때 툴바 높이 지정 (탭이 없으면 0)
            toolbarHeight: kToolbarHeight,
            title: Item_page(padding: const EdgeInsets.fromLTRB(5, 5, 0, 0)),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(48),
              // preferredSize:
              //     Size.fromHeight(tabProvider.tabs.length > 1 ? 48 : 0),
              // child: SizedBox.shrink(),

              child: Container(
                height: tabProvider.tabs.length > 1 ? 48 : 0,
                child: TabBar(
                  // isScrollable: tabProvider.tabs.length > 1 ? false : true,
                  isScrollable: false,
                  controller: tabProvider.controller,
                  indicatorColor: tabProvider.tabs.length > 1
                      ? AppTheme.textColor
                      : Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 4.0,
                  labelColor: AppTheme.textColor,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: TextStyle(fontSize: 15.0),
                  tabs: List.generate(tabProvider.tabs.length, (index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 0),
                      // decoration: BoxDecoration(
                      // color: tabProvider.tabs.length > 1 && index == 0
                      //     ? const Color.fromARGB(255, 254, 248, 215)
                      //     : Colors.transparent, // 0번 탭 배경색 변경
                      // borderRadius: BorderRadius.circular(10), // 둥근 모서리 추가 (옵션)
                      // ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tabProvider.tabs.length > 1 && index == 0)
                            Icon(Icons.list,
                                color: Colors.grey), // 0번 탭에만 아이콘 추가
                          if (tabProvider.tabs.length > 1 && index == 0)
                            const SizedBox(width: 6), // 아이콘과 텍스트 간격
                          tabProvider.tabs[index], // 기존 탭 텍스트
                        ],
                      ),
                    );
                  }),
                  onTap: (index) {
                    tabProvider.selectTab(index);
                  },
                ),
              ),
            ),
          ),
          body: TabBarView(
            key: ValueKey(tabProvider.tabs.length), // 탭 개수를 Key로 사용
            controller: tabProvider.controller,
            children: tabProvider.tabViews, // Provider에서 동적으로 TabBarView 가져오기
          ),
        ),
      ),
    );
  }
}

class First_Item_Page extends StatelessWidget {
  const First_Item_Page({
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
      //위젯 입력

      if (!showSecondList) ...[
        ItemList(filterType: 0)
      ] else ...[
        ItemList(filterType: 1)
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

class Second_Item_Page extends StatelessWidget {
  const Second_Item_Page({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [ItemList(filterType: 2)];
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
