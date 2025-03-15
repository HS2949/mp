import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';
// Flutter의 Material Design 위젯 및 테마를 사용하기 위한 패키지.

// 색상 팔레트 화면을 정의한 모듈 가져오기.

import 'package:mp_db/material/component_screen.dart';
// 구성 요소 화면을 정의한 모듈 가져오기.

import 'package:mp_db/material/constants.dart';
// 상수값들을 정의한 모듈 가져오기.

// 고도 화면을 정의한 모듈 가져오기.
import 'package:mp_db/models/user_model.dart';
import 'package:mp_db/pages/rentacar_subpage.dart';
import 'package:mp_db/pages/subpage/home_subpage.dart';
import 'package:mp_db/pages/planing_subpage.dart';
import 'package:mp_db/pages/subpage/settings/item_category_subpage.dart';

import 'package:mp_db/pages/profile_page.dart';
import 'package:mp_db/pages/subpage/navigationbar_widget.dart';
import 'package:mp_db/providers/auth/auth_provider.dart';
import 'package:mp_db/providers/profile/profile_provider.dart';
import 'package:mp_db/utils/FileCleanerScreen.dart';
import 'package:mp_db/utils/two_line.dart';
import 'package:provider/provider.dart';

// 타이포그래피 화면을 정의한 모듈 가져오기.

// HomePage 클래스는 StatefulWidget을 상속하여 상태를 가질 수 있는 위젯으로 정의.
class Home extends StatefulWidget {
  // Home 클래스의 생성자. 외부에서 전달된 값으로 상태를 초기화함.
  const Home({
    super.key, // Widget의 고유 키. Flutter에서 위젯 식별에 사용.
  });

  static const String routeName = '/home';
  // 이 위젯의 네비게이션 경로 이름을 정의. 라우팅 시 사용.

  @override
  State<Home> createState() => _HomeState();
  // 이 StatefulWidget의 상태를 관리하는 _HomeState를 생성.
}

// _HomeState는 Home 위젯의 상태를 관리하는 클래스.
class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  // GlobalKey를 생성하여 Scaffold 상태를 관리.
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  late final AnimationController controller;
  // 애니메이션의 상태와 진행률을 제어하는 컨트롤러.

  late final CurvedAnimation railAnimation;
  // 곡선 애니메이션 정의. 네비게이션 레일의 이동 애니메이션을 담당.

  bool controllerInitialized = false;
  // 애니메이션 컨트롤러 초기화 여부를 추적.

  bool showMediumSizeLayout = false;
  // 중간 크기 레이아웃 활성화 여부.

  bool showLargeSizeLayout = false;
  // 큰 크기 레이아웃 활성화 여부.

  int screenIndex = ScreenSelected.item.value; // 초기 index 설정
  // 현재 선택된 화면 인덱스. 기본값은 'component 화면'.

  @override
  initState() {
    // 위젯이 생성될 때 한 번 호출되며 초기화 작업을 수행.
    super.initState();
    controller = AnimationController(
      duration: Duration(milliseconds: transitionLength.toInt() * 2),
      // 애니메이션의 총 지속 시간을 설정.
      value: 0, // 애니메이션 초기 값 설정.
      vsync: this, // vsync를 위해 SingleTickerProviderStateMixin을 사용.
    );
    railAnimation = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.5, 1.0),
      // 애니메이션 진행 중 50%에서 100% 구간을 사용하도록 설정.
    );
  }

  @override
  void dispose() {
    // 위젯이 제거될 때 호출되어 리소스를 정리.
    controller.dispose(); // 애니메이션 컨트롤러를 해제.
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    // 의존성이 변경될 때 호출. 화면 크기에 따라 레이아웃 상태를 업데이트.
    super.didChangeDependencies();

    final double width = MediaQuery.of(context).size.width;
    // 현재 화면의 너비를 가져옴.
    final AnimationStatus status = controller.status;
    // 애니메이션의 현재 상태를 가져옴.

    if (width > mediumWidthBreakpoint) {
      // 화면 너비가 중간 너비 기준을 초과할 때.
      if (width > largeWidthBreakpoint) {
        // 화면 너비가 큰 너비 기준을 초과할 때.
        showMediumSizeLayout = false; // 중간 레이아웃은 비활성화.
        showLargeSizeLayout = true; // 큰 레이아웃은 활성화.
      } else {
        // 화면이 중간 너비 범위에 속할 때.
        showMediumSizeLayout = true; // 중간 레이아웃 활성화.
        showLargeSizeLayout = false; // 큰 레이아웃 비활성화.
      }
      if (status != AnimationStatus.forward &&
          status != AnimationStatus.completed) {
        // 애니메이션이 진행 중이 아니거나 완료되지 않은 경우.
        controller.forward(); // 애니메이션을 앞으로 진행.
      }
    } else {
      // 화면 너비가 중간 너비 기준보다 작을 때.
      showMediumSizeLayout = false; // 중간 레이아웃 비활성화.
      showLargeSizeLayout = false; // 큰 레이아웃 비활성화.
      if (status != AnimationStatus.reverse &&
          status != AnimationStatus.dismissed) {
        // 애니메이션이 되감기 중이 아니거나 종료되지 않은 경우.
        controller.reverse(); // 애니메이션을 뒤로 진행.
      }
    }

    if (!controllerInitialized) {
      // 애니메이션 컨트롤러가 초기화되지 않은 경우.
      controllerInitialized = true; // 초기화 상태를 true로 설정.
      controller.value = width > mediumWidthBreakpoint ? 1 : 0;
      // 너비 기준에 따라 초기 애니메이션 값을 설정.
    }
  }

  void handleScreenChanged(int screenSelected) {
    // 화면 변경 이벤트를 처리.
    setState(() {
      screenIndex = screenSelected; // 현재 선택된 화면 인덱스를 업데이트.
    });
  }

  Widget createScreenFor(
    // 선택된 화면에 따라 적절한 위젯을 생성.
    ScreenSelected screenSelected,
    bool showNavBottomBar, // 네비게이션 바 예제를 표시할지 여부.
  ) =>
      switch (screenSelected) {
        // 선택된 화면에 따라 반환할 위젯을 지정.
        ScreenSelected.home => Expanded(child: HomeSubpage()),
        ScreenSelected.item => Expanded(
            child: Item_Widget(
                railAnimation: railAnimation,
                scaffoldKey: scaffoldKey,
                showNavBottomBar: showNavBottomBar,
                showMediumSizeLayout: showMediumSizeLayout,
                showLargeSizeLayout: showLargeSizeLayout),
          ),
        // ScreenSelected.temp1 => const ItemScreen(),
        // ScreenSelected.temp1 => Expanded(child: const ItemDetailScreen(itemId: 'EGA9krhnxChp3EcXHBG9')),
        ScreenSelected.temp1 => Expanded(child: PlaningSubpage()),
        ScreenSelected.setting1 => Expanded(
            child: Category_Widget(
                railAnimation: railAnimation,
                scaffoldKey: scaffoldKey,
                showNavBottomBar: showNavBottomBar,
                showMediumSizeLayout: showMediumSizeLayout,
                showLargeSizeLayout: showLargeSizeLayout),
          ),
        ScreenSelected.setting2 => Expanded(child: CombinedFileCheckerScreen()),
        // ScreenSelected.setting3 => const Item_Category(),
        ScreenSelected.temp2 => Expanded(child: RentacarSubpage()),
        ScreenSelected.setting3 => Expanded(
            // 선택된 화면이 'component'일 때 실행. Expanded로 레이아웃을 확장.
            child: OneTwoTransition(
              animation: railAnimation, // 네비게이션 레일 애니메이션을 적용.
              one: FirstComponentList(
                showNavBottomBar: showNavBottomBar, // 네비게이션 바 예제 표시 여부.
                scaffoldKey: scaffoldKey, // Scaffold 상태를 전달.
                showSecondList: showMediumSizeLayout || showLargeSizeLayout,
                // 중간 또는 큰 레이아웃일 때 두 번째 리스트를 표시.
              ), // 첫 번째 구성 요소 리스트.
              two: SecondComponentList(
                scaffoldKey: scaffoldKey, // Scaffold 상태를 전달.
              ), // 두 번째 구성 요소 리스트.
            ),
          ),
      };
  PreferredSizeWidget createAppBar(User user) {
    // 앱바(AppBar)를 생성하는 함수.
    // return AppBar(
    //   title: widget.useMaterial3
    //       ? const Text('Material 3') // Material 3 사용 시 앱바 제목.
    //       : const Text('Material 2'), // Material 2 사용 시 앱바 제목.
    //   actions: !showMediumSizeLayout && !showLargeSizeLayout
    //       ? [
    //           // 화면 크기가 작을 경우에만 동작 버튼 추가.
    //           _BrightnessButton(
    //             handleBrightnessChange: widget.handleBrightnessChange,
    //           ),
    //           _Material3Button(
    //             handleMaterialVersionChange: widget.handleMaterialVersionChange,
    //           ),
    //           _ColorSeedButton(
    //             handleColorSelect: widget.handleColorSelect,
    //             colorSelected: widget.colorSelected,
    //             colorSelectionMethod: widget.colorSelectionMethod,
    //           ),
    //           _ColorImageButton(
    //             handleImageSelect: widget.handleImageSelect,
    //             imageSelected: widget.imageSelected,
    //             colorSelectionMethod: widget.colorSelectionMethod,
    //           )
    //         ]
    //       : [Container()], // 큰 화면에서는 빈 컨테이너 반환.
    // );

    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 조건에 따른 위젯 렌더링
          if (!showMediumSizeLayout && !showLargeSizeLayout)
            Flexible(
              child: Image.asset(
                'assets/images/mp_logo.png',
                width: 100,
                height: 50,
                fit: BoxFit.scaleDown,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.error, size: 50, color: Colors.orange);
                },
              ),
            ),

          SizedBox(width: 20),
          if (showMediumSizeLayout || showLargeSizeLayout) ...[
            Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/miceplan_font.png',
                width: 250,
                height: 100,
                fit: BoxFit.scaleDown,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.error, size: 50, color: Colors.orange);
                },
              ),
            ),
            SizedBox(width: 60)
          ],
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end, // 텍스트를 바닥에 붙이기
              crossAxisAlignment: CrossAxisAlignment.start, // 텍스트 정렬
              children: [
                Text(
                  'Hello :)',
                  style: AppTheme.textCGreyStyle,
                ),
                Text(
                  '${user.name}  ${user.position}님',
                  style: AppTheme.textCGreyStyle,
                ),
              ],
            ),
          ),
        ],
      ),

      actions: !showMediumSizeLayout && !showLargeSizeLayout
          ? [
              _ProfileButton(showTooltipBelow: false),
              _SignoutButton(showTooltipBelow: false),
              _DrawerButton(showTooltipBelow: false, scaffoldKey: scaffoldKey),
            ]
          : [
              // Container()
              _DrawerButton(showTooltipBelow: false, scaffoldKey: scaffoldKey)
            ], // 큰 화면에서는 빈 컨테이너 반환.
    );
  }

  Widget _trailingActions() => Column(
        // 화면 크기가 작은 경우 추가 동작을 제공.
        mainAxisAlignment: MainAxisAlignment.end, // 아래쪽 정렬.
        children: [
          Flexible(
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/mp_logo.png',
                width: 50,
                height: 30,
                fit: BoxFit.scaleDown,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.error, size: 50, color: Colors.orange);
                },
              ),
            ),
          ),
          SizedBox(height: 5),
          Flexible(
            child: _ProfileButton(showTooltipBelow: false),
          ),
          Flexible(child: _SignoutButton(showTooltipBelow: false)),

          // Flexible(
          //     child: _DrawerButton(
          //         showTooltipBelow: false, scaffoldKey: scaffoldKey)),
          // Flexible(
          //   child: _ColorSeedButton(
          //     handleColorSelect: widget.handleColorSelect,
          //     colorSelected: widget.colorSelected,
          //     colorSelectionMethod: widget.colorSelectionMethod,
          //   ),
          // ),
          // Flexible(
          //   child: _ColorImageButton(
          //     handleImageSelect: widget.handleImageSelect,
          //     imageSelected: widget.imageSelected,
          //     colorSelectionMethod: widget.colorSelectionMethod,
          //   ),
          // ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileProvider>().state.user;
    // 위젯의 UI를 정의.
    return PopScope(
      canPop: false,
      child: AnimatedBuilder(
        animation: controller, // 애니메이션 컨트롤러를 참조.
        builder: (context, child) {
          // 애니메이션 값에 따라 UI를 빌드.
          return NavigationTransition(
            scaffoldKey: scaffoldKey, // Scaffold 상태 키.
            animationController: controller, // 애니메이션 컨트롤러.
            railAnimation: railAnimation, // 네비게이션 레일 애니메이션.
            appBar: createAppBar(user), // 앱바 생성.
            body: createScreenFor(
                ScreenSelected.values[screenIndex], controller.value == 1),
            navigationRail: NavigationRail(
              extended: showLargeSizeLayout, // 큰 화면에서는 확장 레일 표시.
              destinations: navRailDestinations, // 네비게이션 레일의 목적지.
              selectedIndex:
                  screenIndex < 4 ? screenIndex : 0, // 5번째 페이지 제외 //lym
              onDestinationSelected: (index) {
                // 네비게이션 레일에서 목적지가 선택될 때.
                setState(() {
                  screenIndex = index; // 선택된 화면 인덱스를 업데이트.
                  handleScreenChanged(screenIndex); // 화면 변경 이벤트 호출.
                });
              },
              trailing: Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: showLargeSizeLayout
                      ? _ExpandedTrailingActions(
                          scaffoldKey: scaffoldKey,
                          screenIndex: screenIndex,
                        )
                      : _trailingActions(), // 작은 화면에서는 간략한 동작 제공.
                ),
              ),
            ),
            navigationBar: NavigationBars(
              onSelectItem: (index) {
                // 네비게이션 바에서 항목이 선택될 때.
                setState(() {
                  screenIndex = index; // 선택된 화면 인덱스를 업데이트.
                  handleScreenChanged(screenIndex); // 화면 변경 이벤트 호출.
                });
              },
              selectedIndex:
                  screenIndex < 4 ? screenIndex : 0, // 5번째 페이지 제외 //lym
              isExampleBar: false, // 예제 바인지 여부.
            ),
          );
        },
      ),
    );
  }
}

class KeepAlivePage extends StatefulWidget {
  final Widget child;

  const KeepAlivePage({Key? key, required this.child}) : super(key: key);

  @override
  _KeepAlivePageState createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context); // 반드시 호출하여 상태를 유지하도록 함
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true; // 상태 유지 활성화
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({
    this.showTooltipBelow = true, // 툴팁을 아래쪽에 표시할지 여부. 기본값은 true.
    this.showTextNext = false, // 텍스트를 옆에 표시할지 여부. 기본값은 false.
  });

  final bool showTooltipBelow; // 툴팁의 위치를 제어.
  final bool showTextNext;

  // onPressed 동작을 함수로 추출
  void _onPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      preferBelow: showTooltipBelow, // 툴팁 위치를 아래로 설정 여부.
      message: '프로필 보기', // 툴팁 메시지.
      child: showTextNext
          ? TextButton.icon(
              onPressed: () => _onPressed(context), // 함수 호출로 중복 제거
              icon: Icon(Icons.account_circle, size: 25),
              label: Text('  Profile'),
            )
          : IconButton(
              onPressed: () => _onPressed(context), // 함수 호출로 중복 제거
              icon: Icon(Icons.account_circle),
            ),
    );
  }
}

class _SignoutButton extends StatelessWidget {
  const _SignoutButton({
    this.showTooltipBelow = true, // 툴팁을 아래쪽에 표시할지 여부. 기본값은 true.
    this.showTextNext = false, // 텍스트를 옆에 표시할지 여부. 기본값은 false.
  });

  final bool showTooltipBelow; // 툴팁의 위치를 제어.
  final bool showTextNext;

  // onPressed 동작을 함수로 추출
  void _onPressed(BuildContext context) {
    context.read<AuthProvider>().signout();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      preferBelow: showTooltipBelow, // 툴팁 위치를 아래로 설정 여부.
      message: 'Sign Out', // 툴팁 메시지.
      child: showTextNext
          ? TextButton.icon(
              onPressed: () => _onPressed(context), // 함수 호출로 중복 제거
              icon: Icon(Icons.exit_to_app, size: 25),
              label: Text('  Sign Out'),
            )
          : IconButton(
              onPressed: () => _onPressed(context), // 함수 호출로 중복 제거
              icon: Icon(Icons.exit_to_app),
            ),
    );
  }
}

class _DrawerButton extends StatelessWidget {
  const _DrawerButton(
      {this.showTooltipBelow = true, // 툴팁을 아래쪽에 표시할지 여부. 기본값은 true.
      required this.scaffoldKey});

  final bool showTooltipBelow; // 툴팁의 위치를 제어.
  final GlobalKey<ScaffoldState> scaffoldKey;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      preferBelow: showTooltipBelow, // 툴팁 위치를 아래로 설정 여부.
      message: 'Open Drawer', // 툴팁 메시지.
      child: IconButton(
        onPressed: () {
          scaffoldKey.currentState!.openEndDrawer();
        },
        icon: Icon(Icons.menu),
      ),
    );
  }
}

const List<NavigationDestination> appBarDestinations = [
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.widgets_outlined),
    label: 'Home',
    selectedIcon: Icon(Icons.widgets),
  ),
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.screen_search_desktop_outlined),
    label: 'Item',
    selectedIcon: Icon(Icons.screen_search_desktop_rounded),
  ),
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.schedule_outlined),
    label: 'Planing',
    selectedIcon: Icon(Icons.travel_explore),
  ),
  NavigationDestination(
    tooltip: '',
    icon: Icon(Icons.car_crash_outlined),
    label: 'Rentacar',
    selectedIcon: Icon(Icons.opacity),
  )
];

class _ExpandedTrailingActions extends StatelessWidget {
  // 확장된 추가 동작 위젯.
  const _ExpandedTrailingActions({
    required this.scaffoldKey,
    required this.screenIndex,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final int screenIndex;

  @override
  Widget build(BuildContext context) {
    // UI를 빌드.
    final screenHeight = MediaQuery.of(context).size.height;
    // 화면 높이를 가져옴.
    final trailingActionsBody = Container(
      constraints: const BoxConstraints.tightFor(width: 250),
      // 고정된 너비를 가진 컨테이너.
      padding: const EdgeInsets.symmetric(horizontal: 30),
      // 수평 패딩 추가.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/mp_logo.png',
                width: 200,
                height: 100,
                fit: BoxFit.scaleDown,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.error, size: 50, color: Colors.orange);
                },
              ),
            ),
          ),
          SizedBox(height: 20),
          _ProfileButton(showTooltipBelow: true, showTextNext: true),
          _SignoutButton(showTooltipBelow: true, showTextNext: true),
        ],
      ),
    );
    return screenHeight > (screenIndex == 3 ? 740 : 200) //740
        ? trailingActionsBody
        : trailingActionsBody; //SingleChildScrollView(child: trailingActionsBody); // 아래 정렬 또는 위 정렬렬
    // 화면 높이에 따라 스크롤 가능 여부 결정.
  }
}

class NavigationTransition extends StatefulWidget {
  // 네비게이션 전환 위젯.
  const NavigationTransition(
      {super.key,
      required this.scaffoldKey, // Scaffold 키.
      required this.animationController, // 애니메이션 컨트롤러.
      required this.railAnimation, // 레일 애니메이션.
      required this.navigationRail, // 네비게이션 레일 위젯.
      required this.navigationBar, // 네비게이션 바 위젯.
      required this.appBar, // 앱바 위젯.
      required this.body}); // 본문 위젯.

  final GlobalKey<ScaffoldState> scaffoldKey; // Scaffold 상태 관리 키.
  final AnimationController animationController; // 애니메이션 컨트롤러.
  final CurvedAnimation railAnimation; // 곡선 애니메이션.
  final Widget navigationRail; // 네비게이션 레일 위젯.
  final Widget navigationBar; // 네비게이션 바 위젯.
  final PreferredSizeWidget appBar; // 앱바 위젯.
  final Widget body; // 본문 내용.

  @override
  State<NavigationTransition> createState() => _NavigationTransitionState();
  // 상태 관리 클래스 생성.
}

class _NavigationTransitionState extends State<NavigationTransition> {
  // NavigationTransition의 상태 관리.
  late final AnimationController controller; // 애니메이션 컨트롤러.
  late final CurvedAnimation railAnimation; // 레일 애니메이션.
  late final ReverseAnimation barAnimation; // 바 애니메이션.
  bool controllerInitialized = false; // 컨트롤러 초기화 여부.
  bool showDivider = false; // 구분선 표시 여부.

  @override
  void initState() {
    super.initState();

    controller = widget.animationController; // 애니메이션 컨트롤러 초기화.
    railAnimation = widget.railAnimation; // 레일 애니메이션 초기화.

    barAnimation = ReverseAnimation(
      // 바 애니메이션을 반전 애니메이션으로 초기화.
      CurvedAnimation(
        parent: controller, // 컨트롤러 연결.
        curve: const Interval(0.0, 0.5), // 애니메이션 진행 간격.
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    // 현재 테마의 색상 스키마를 가져옴.

    return Scaffold(
      key: widget.scaffoldKey, // Scaffold 키.
      appBar: widget.appBar, // 앱바 위젯.
      body: Row(
        children: <Widget>[
          RailTransition(
            animation: railAnimation, // 레일 애니메이션.
            backgroundColor: colorScheme.surface, // 레일 배경색.
            child: Column(
              children: [
                //레일 상단에 위젯 추가 공간간
                SizedBox(height: 10),
                Expanded(child: widget.navigationRail),
              ],
            ), // 네비게이션 레일.
          ),
          widget.body, // 본문 내용.
        ],
      ),
      bottomNavigationBar: BarTransition(
        animation: barAnimation, // 바 애니메이션.
        backgroundColor: colorScheme.surface, // 바 배경색.
        child: widget.navigationBar, // 네비게이션 바.
      ),
      endDrawer: const NavigationDrawerSection(), // 우측 드로어.
    );
  }
}

final List<NavigationRailDestination> navRailDestinations = appBarDestinations
    .map(
      // appBarDestinations의 모든 항목을 NavigationRailDestination으로 변환.
      (destination) => NavigationRailDestination(
        icon: Tooltip(
          // 아이콘에 툴팁 추가.
          message: destination.label, // 툴팁 메시지는 목적지 레이블로 설정.
          child: destination.icon, // 목적지의 기본 아이콘.
        ),
        selectedIcon: Tooltip(
          // 선택된 상태의 아이콘에 툴팁 추가.
          message: destination.label, // 툴팁 메시지는 목적지 레이블로 설정.
          child: destination.selectedIcon, // 선택된 상태의 아이콘.
        ),
        label: Text(destination.label), // 목적지 레이블을 텍스트로 표시.
      ),
    )
    .toList(); // 리스트로 변환.

class NavigationDrawerSection extends StatefulWidget {
  const NavigationDrawerSection({super.key});

  @override
  State<NavigationDrawerSection> createState() =>
      _NavigationDrawerSectionState();
}

class _NavigationDrawerSectionState extends State<NavigationDrawerSection> {
  int navDrawerIndex = -1;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      onDestinationSelected: (selectedIndex) {
        setState(() {
          navDrawerIndex = selectedIndex;
          switch (navDrawerIndex) {
            case (0):
              final homeState = context.findAncestorStateOfType<_HomeState>();
              if (homeState != null) {
                homeState.setState(() {
                  // homeState.screenIndex = 1; // 원하는 Navigation Bar의 index로 설정
                  homeState.handleScreenChanged(4); // 화면 전환 로직 호출
                });
              }

            case (1):
              final homeState = context.findAncestorStateOfType<_HomeState>();
              if (homeState != null) {
                homeState.setState(() {
                  // homeState.screenIndex = 1; // 원하는 Navigation Bar의 index로 설정
                  homeState.handleScreenChanged(5); // 화면 전환 로직 호출
                });
              }

            // throw Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (context) => Item_Field(),
            //     ));

            case (2):
              final homeState = context.findAncestorStateOfType<_HomeState>();
              if (homeState != null) {
                homeState.setState(() {
                  // homeState.screenIndex = 1; // 원하는 Navigation Bar의 index로 설정
                  homeState.handleScreenChanged(6); // 화면 전환 로직 호출
                });
              }
          }
          Navigator.pop(context); // 드로어 닫기
        });
      },
      selectedIndex: navDrawerIndex,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Text(
            'Setting',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ...destinations.map((destination) {
          return NavigationDrawerDestination(
            label: Text(destination.label),
            icon: destination.icon,
            selectedIcon: destination.selectedIcon,
          );
        }),
        const Divider(indent: 28, endIndent: 28),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Text(
            'Labels',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ...labelDestinations.map((destination) {
          return NavigationDrawerDestination(
            label: Text(destination.label),
            icon: destination.icon,
            selectedIcon: destination.selectedIcon,
          );
        }),
      ],
    );
  }
}

class ExampleDestination {
  const ExampleDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}

const List<ExampleDestination> destinations = <ExampleDestination>[
  ExampleDestination('Setting', Icon(Icons.settings), Icon(Icons.settings)),
  ExampleDestination('File Cleaner', Icon(Icons.label_important_outline),
      Icon(Icons.label_important)),
  ExampleDestination(
      '업데이트 예정', Icon(Icons.favorite_outline), Icon(Icons.favorite)),
  ExampleDestination('업데이트 예정', Icon(Icons.delete_outline), Icon(Icons.delete)),
];

const List<ExampleDestination> labelDestinations = <ExampleDestination>[
  ExampleDestination('라벨1', Icon(Icons.bookmark_border), Icon(Icons.bookmark)),
  ExampleDestination('라벨2', Icon(Icons.bookmark_border), Icon(Icons.bookmark)),
  ExampleDestination('라벨3', Icon(Icons.bookmark_border), Icon(Icons.bookmark)),
];

class SizeAnimation extends CurvedAnimation {
  // 크기 애니메이션 클래스.
  SizeAnimation(Animation<double> parent)
      : super(
          parent: parent, // 부모 애니메이션 참조.
          curve: const Interval(
            0.2, // 애니메이션이 20% 진행된 시점에서 시작.
            0.8, // 애니메이션이 80% 진행된 시점에서 끝남.
            curve: Curves.easeInOutCubicEmphasized, // 커브 형태 설정.
          ),
          reverseCurve: Interval(
            0, // 애니메이션이 역방향으로 0% 진행된 시점에서 시작.
            0.2, // 역방향으로 20% 진행된 시점에서 끝남.
            curve: Curves.easeInOutCubicEmphasized.flipped, // 반전된 커브 형태.
          ),
        );
}

class OffsetAnimation extends CurvedAnimation {
  // 오프셋 애니메이션 클래스.
  OffsetAnimation(Animation<double> parent)
      : super(
          parent: parent, // 부모 애니메이션 참조.
          curve: const Interval(
            0.4, // 애니메이션이 40% 진행된 시점에서 시작.
            1.0, // 애니메이션이 100% 진행된 시점에서 끝남.
            curve: Curves.easeInOutCubicEmphasized, // 커브 형태 설정.
          ),
          reverseCurve: Interval(
            0, // 애니메이션이 역방향으로 0% 진행된 시점에서 시작.
            0.2, // 역방향으로 20% 진행된 시점에서 끝남.
            curve: Curves.easeInOutCubicEmphasized.flipped, // 반전된 커브 형태.
          ),
        );
}

class RailTransition extends StatefulWidget {
  // 네비게이션 레일 전환 위젯.
  const RailTransition(
      {super.key,
      required this.animation, // 애니메이션 컨트롤러.
      required this.backgroundColor, // 배경색.
      required this.child}); // 자식 위젯.

  final Animation<double> animation; // 애니메이션의 진행률.
  final Widget child; // 애니메이션 대상 자식 위젯.
  final Color backgroundColor; // 배경색.

  @override
  State<RailTransition> createState() => _RailTransition(); // 상태 클래스 생성.
}

class _RailTransition extends State<RailTransition> {
  // RailTransition의 상태 관리 클래스.
  late Animation<Offset> offsetAnimation; // 오프셋 애니메이션.
  late Animation<double> widthAnimation; // 너비 애니메이션.

  @override
  void didChangeDependencies() {
    // 종속성이 변경될 때 호출.
    super.didChangeDependencies();

    final bool ltr = Directionality.of(context) == TextDirection.ltr;
    // 텍스트 방향이 왼쪽에서 오른쪽인지 확인.

    widthAnimation = Tween<double>(
      begin: 0, // 초기 너비 값.
      end: 1, // 최종 너비 값.
    ).animate(SizeAnimation(widget.animation));

    offsetAnimation = Tween<Offset>(
      begin: ltr ? const Offset(-1, 0) : const Offset(1, 0),
      // 텍스트 방향에 따라 시작 위치 설정.
      end: Offset.zero, // 최종 위치는 원래 위치.
    ).animate(OffsetAnimation(widget.animation));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      // 자식 위젯을 잘라내어 애니메이션 영역을 제한.
      child: DecoratedBox(
        // 배경색이 적용된 박스 생성.
        decoration: BoxDecoration(color: widget.backgroundColor),
        child: Align(
          alignment: Alignment.topLeft, // 왼쪽 상단 정렬.
          widthFactor: widthAnimation.value, // 너비 애니메이션 값 적용.
          child: FractionalTranslation(
            // 자식 위젯을 애니메이션 값에 따라 이동.
            translation: offsetAnimation.value, // 이동 값 설정.
            child: widget.child, // 애니메이션 대상 자식 위젯.
          ),
        ),
      ),
    );
  }
}

class BarTransition extends StatefulWidget {
  // 네비게이션 바 전환 위젯.
  const BarTransition(
      {super.key,
      required this.animation, // 애니메이션 컨트롤러.
      required this.backgroundColor, // 배경색.
      required this.child}); // 자식 위젯.

  final Animation<double> animation; // 애니메이션의 진행률.
  final Color backgroundColor; // 배경색.
  final Widget child; // 자식 위젯.

  @override
  State<BarTransition> createState() => _BarTransition(); // 상태 클래스 생성.
}

class _BarTransition extends State<BarTransition> {
  // BarTransition의 상태 관리 클래스.
  late final Animation<Offset> offsetAnimation; // 오프셋 애니메이션.
  late final Animation<double> heightAnimation; // 높이 애니메이션.

  @override
  void initState() {
    super.initState();

    offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // 초기 오프셋 값.
      end: Offset.zero, // 최종 위치.
    ).animate(OffsetAnimation(widget.animation));

    heightAnimation = Tween<double>(
      begin: 0, // 초기 높이 값.
      end: 1, // 최종 높이 값.
    ).animate(SizeAnimation(widget.animation));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      // 자식 위젯을 잘라내어 애니메이션 영역을 제한.
      child: DecoratedBox(
        decoration: BoxDecoration(color: widget.backgroundColor),
        child: Align(
          alignment: Alignment.topLeft, // 왼쪽 상단 정렬.
          heightFactor: heightAnimation.value, // 높이 애니메이션 값 적용.
          child: FractionalTranslation(
            // 자식 위젯을 애니메이션 값에 따라 이동.
            translation: offsetAnimation.value, // 이동 값 설정.
            child: widget.child, // 애니메이션 대상 자식 위젯.
          ),
        ),
      ),
    );
  }
}
