import 'package:flutter/material.dart';
import 'package:mp_db/pages/dialog/item_detail_dialog.dart';
import 'package:mp_db/pages/home.dart';

class FixedTabsUsingTabBarPage extends StatefulWidget {
  @override
  _FixedTabsUsingTabBarPageState createState() =>
      _FixedTabsUsingTabBarPageState();
}

class _FixedTabsUsingTabBarPageState extends State<FixedTabsUsingTabBarPage>
    with TickerProviderStateMixin {
  static const int maxTabs = 10;
  late TabController _tabController;

  /// 최대 maxTabs(10)개의 슬롯을 미리 생성합니다.
  /// 활성 탭은 제목과 컨텐츠가 채워지고, 비활성 탭은 빈 플레이스홀더로 처리합니다.
  List<String> tabTitles = List.generate(maxTabs, (index) => '');
  List<Widget> tabViews = List.generate(maxTabs, (index) => Container());
  int activeTabCount = 0; // 실제 활성 탭 개수

  @override
  void initState() {
    super.initState();
    // 최대 탭 수에 맞춰 TabController 생성
    _tabController = TabController(length: maxTabs, vsync: this);
  }

  /// 활성 탭 개수가 maxTabs 미만일 경우, 다음 빈 슬롯에 탭 추가
  void addTab(String title, Widget content) {
    if (activeTabCount >= maxTabs) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 탭 수($maxTabs개)에 도달했습니다.')),
      );
      return;
    }
    setState(() {
      tabTitles[activeTabCount] = title;
      tabViews[activeTabCount] = content;
      activeTabCount++;
      // 새 탭으로 전환
      _tabController.animateTo(activeTabCount - 1);
    });
  }

  /// 지정된 인덱스의 탭을 삭제하고, 뒤쪽 탭들을 앞으로 당긴 후 마지막 슬롯은 플레이스홀더로 복원
  void removeTab(int index) {
    if (index < 0 || index >= activeTabCount) return;
    setState(() {
      for (int i = index; i < activeTabCount - 1; i++) {
        tabTitles[i] = tabTitles[i + 1];
        tabViews[i] = tabViews[i + 1];
      }
      tabTitles[activeTabCount - 1] = '';
      tabViews[activeTabCount - 1] = Container();
      activeTabCount--;
      // 삭제 후 현재 선택 인덱스가 범위 내에 있도록 조정
      int newIndex = _tabController.index;
      if (newIndex >= activeTabCount) newIndex = activeTabCount - 1;
      _tabController.animateTo(newIndex);
    });
  }

  /// TabBar에 전달할 탭 목록 생성  
  /// 활성 탭은 실제 제목을 표시하고, 비활성 탭은 SizedBox.shrink()를 사용해 최소한의 공간만 차지
  List<Widget> get tabs {
    return List.generate(maxTabs, (index) {
      if (index < activeTabCount) {
        return Tab(text: tabTitles[index]);
      } else {
        return Tab(child: SizedBox.shrink());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fixed Tabs Using TabBar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs,
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(maxTabs, (index) {
          if (index < activeTabCount) {
            return tabViews[index];
          } else {
            return Container();
          }
        }),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 탭 추가 버튼
          FloatingActionButton(
            onPressed: () {
              addTab(
                '탭 ${activeTabCount + 1}',
                KeepAlivePage(
                  child: ItemDetailScreen(
                                itemId: "EGA9krhnxChp3EcXHBG9",
                              ),
                ),
                // Center(child: Text('탭 ${activeTabCount + 1}의 내용')),
              );
            },
            tooltip: '탭 추가',
            child: Icon(Icons.add),
          ),
          SizedBox(width: 16),
          // 현재 탭 삭제 버튼
          FloatingActionButton(
            onPressed: () {
              if (activeTabCount > 0) {
                removeTab(_tabController.index);
              }
            },
            tooltip: '현재 탭 삭제',
            child: Icon(Icons.remove),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}