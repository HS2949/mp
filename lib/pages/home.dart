// Copyright 2021 The Flutter team. All rights reserved.
// Flutter 팀의 소스 코드. BSD-style 라이선스에 따라 배포 가능. 자세한 내용은 LICENSE 파일 참조.

import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';
// Flutter의 Material Design 위젯 및 테마를 사용하기 위한 패키지.

import 'package:mp_db/material/color_palettes_screen.dart';
// 색상 팔레트 화면을 정의한 모듈 가져오기.

import 'package:mp_db/material/component_screen.dart';
// 구성 요소 화면을 정의한 모듈 가져오기.

import 'package:mp_db/material/constants.dart';
// 상수값들을 정의한 모듈 가져오기.

import 'package:mp_db/material/elevation_screen.dart';
// 고도 화면을 정의한 모듈 가져오기.

import 'package:mp_db/material/typography_screen.dart';
import 'package:mp_db/models/user_model.dart';
import 'package:mp_db/pages/dialog/Item_Category_dialog.dart';
import 'package:mp_db/pages/dialog/test.dart';
import 'package:mp_db/pages/profile_page.dart';
import 'package:mp_db/providers/auth/auth_provider.dart';
import 'package:mp_db/providers/profile/profile_provider.dart';
import 'package:mp_db/pages/item_screen.dart';
import 'package:provider/provider.dart';

import 'dialog/Item_Field_dialog.dart';
// 타이포그래피 화면을 정의한 모듈 가져오기.

// HomePage 클래스는 StatefulWidget을 상속하여 상태를 가질 수 있는 위젯으로 정의.
class Home extends StatefulWidget {
  // Home 클래스의 생성자. 외부에서 전달된 값으로 상태를 초기화함.
  const Home({
    super.key, // Widget의 고유 키. Flutter에서 위젯 식별에 사용.
    required this.useLightMode, // 라이트 모드 활성화 여부.
    required this.useMaterial3, // Material 3 활성화 여부.
    required this.colorSelected, // 선택된 색상.
    required this.handleBrightnessChange, // 밝기 전환 핸들러 함수.
    required this.handleMaterialVersionChange, // Material 버전 전환 핸들러 함수.
    required this.handleColorSelect, // 색상 선택 핸들러 함수.
    required this.handleImageSelect, // 이미지 선택 핸들러 함수.
    required this.colorSelectionMethod, // 색상 선택 방식.
    required this.imageSelected, // 선택된 이미지.
  });

  static const String routeName = '/home';
  // 이 위젯의 네비게이션 경로 이름을 정의. 라우팅 시 사용.

  final bool useLightMode; // 라이트 모드 사용 여부를 나타내는 변수.
  final bool useMaterial3; // Material 3 활성화 여부를 나타내는 변수.
  final ColorSeed colorSelected; // 현재 선택된 색상을 저장.
  final ColorImageProvider imageSelected; // 현재 선택된 이미지 정보.
  final ColorSelectionMethod colorSelectionMethod; // 색상 선택 방식을 정의.

  // 아래는 각각의 상호작용 이벤트를 처리하기 위한 함수들.
  final void Function(bool useLightMode)
      handleBrightnessChange; // 밝기 변경 이벤트 핸들러.
  final void Function() handleMaterialVersionChange; // Material 버전 변경 이벤트 핸들러.
  final void Function(int value) handleColorSelect; // 색상 선택 이벤트 핸들러.
  final void Function(int value) handleImageSelect; // 이미지 선택 이벤트 핸들러.

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

  int screenIndex = ScreenSelected.component.value;
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
    bool showNavBarExample, // 네비게이션 바 예제를 표시할지 여부.
  ) =>
      switch (screenSelected) {
        // ScreenSelected.component => Expanded(
        //     // 선택된 화면이 'component'일 때 실행. Expanded로 레이아웃을 확장.
        //     child: OneTwoTransition(
        //       animation: railAnimation, // 네비게이션 레일 애니메이션을 적용.
        //       one: FirstComponentList(
        //         // 첫 번째 구성 요소 리스트.
        //         showNavBottomBar: showNavBarExample, // 네비게이션 바 예제 표시 여부.
        //         scaffoldKey: scaffoldKey, // Scaffold 상태를 전달.
        //         showSecondList: showMediumSizeLayout || showLargeSizeLayout,
        //         // 중간 또는 큰 레이아웃일 때 두 번째 리스트를 표시.
        //       ),
        //       two: SecondComponentList(
        //         // 두 번째 구성 요소 리스트.
        //         scaffoldKey: scaffoldKey, // Scaffold 상태를 전달.
        //       ),
        //     ),
        //   ),

        // 선택된 화면에 따라 반환할 위젯을 지정.
        ScreenSelected.component => const ItemScreen(),
        ScreenSelected.color => const ColorPalettesScreen(),
        ScreenSelected.typography => const TypographyScreen(),
        ScreenSelected.elevation => const ElevationScreen(),
        ScreenSelected.setting1 => const Item_Category(),
        ScreenSelected.setting2 => const Item_Field(),
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
                  style: AppTheme.textfieldStyle,
                ),
                Text(
                  '${user.name}  ${user.position}님',
                  style: AppTheme.textfieldStyle,
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
                          // 큰 화면에서는 확장된 동작 제공.
                          useLightMode: widget.useLightMode,
                          handleBrightnessChange: widget.handleBrightnessChange,
                          useMaterial3: widget.useMaterial3,
                          handleMaterialVersionChange:
                              widget.handleMaterialVersionChange,
                          handleImageSelect: widget.handleImageSelect,
                          handleColorSelect: widget.handleColorSelect,
                          colorSelectionMethod: widget.colorSelectionMethod,
                          imageSelected: widget.imageSelected,
                          colorSelected: widget.colorSelected,
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
              label: Text('  Profile',
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppTheme.primaryColor)),
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
              label: Text('  Sign Out',
                  style: AppTheme.bodyMedium
                      .copyWith(color: AppTheme.primaryColor)),
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

class _ColorSeedButton extends StatelessWidget {
  // 색상 선택 버튼 위젯.
  const _ColorSeedButton({
    required this.handleColorSelect, // 색상 선택 이벤트 핸들러 함수 참조.
    required this.colorSelected, // 현재 선택된 색상.
    required this.colorSelectionMethod, // 색상 선택 방식.
  });

  final void Function(int) handleColorSelect; // 색상 선택 이벤트 핸들러 함수.
  final ColorSeed colorSelected; // 선택된 색상 데이터를 저장.
  final ColorSelectionMethod colorSelectionMethod; // 색상 선택 방식을 정의.

  @override
  Widget build(BuildContext context) {
    // 위젯의 UI 빌드.
    return PopupMenuButton(
      icon: const Icon(
        Icons.palette_outlined, // 색상 팔레트 아이콘.
      ),
      tooltip: 'Select a seed color', // 툴팁 메시지.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      // 메뉴의 모서리를 둥글게 설정.
      itemBuilder: (context) {
        // 메뉴 아이템을 빌드.
        return List.generate(ColorSeed.values.length, (index) {
          // ColorSeed 열거형의 모든 값에 대해 반복.
          ColorSeed currentColor = ColorSeed.values[index];
          // 현재 색상을 가져옴.

          return PopupMenuItem(
            value: index, // 현재 색상의 인덱스를 값으로 설정.
            enabled: currentColor != colorSelected ||
                colorSelectionMethod != ColorSelectionMethod.colorSeed,
            // 선택된 색상이 현재 색상이 아니거나 선택 방식이 이미지가 아닐 때 활성화.
            child: Wrap(
              // 자식 위젯들을 가로로 나란히 배치.
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Icon(
                    currentColor == colorSelected &&
                            colorSelectionMethod != ColorSelectionMethod.image
                        ? Icons.color_lens // 선택된 색상 아이콘.
                        : Icons.color_lens_outlined, // 비활성화 색상 아이콘.
                    color: currentColor.color, // 아이콘 색상을 현재 색상으로 설정.
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(currentColor.label), // 색상 이름 표시.
                ),
              ],
            ),
          );
        });
      },
      onSelected: handleColorSelect, // 색상이 선택되었을 때 이벤트 핸들러 호출.
    );
  }
}

// class _ColorImageButton extends StatelessWidget {
//   // 색상 추출 이미지를 선택하는 버튼 위젯.
//   const _ColorImageButton({
//     required this.handleImageSelect, // 이미지 선택 이벤트 핸들러 함수.
//     required this.imageSelected, // 현재 선택된 이미지.
//     required this.colorSelectionMethod, // 색상 선택 방식.
//   });

//   final void Function(int) handleImageSelect; // 이미지 선택 이벤트 핸들러 함수.
//   final ColorImageProvider imageSelected; // 선택된 이미지 정보.
//   final ColorSelectionMethod colorSelectionMethod; // 색상 선택 방식.

//   @override
//   Widget build(BuildContext context) {
//     // 위젯의 UI를 빌드.
//     return PopupMenuButton(
//       icon: const Icon(
//         Icons.image_outlined, // 이미지 선택 아이콘.
//       ),
//       tooltip: 'Select a color extraction image', // 툴팁 메시지.
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       // 팝업 메뉴의 모서리를 둥글게 설정.
//       itemBuilder: (context) {
//         // 팝업 메뉴 항목을 생성.
//         return List.generate(ColorImageProvider.values.length, (index) {
//           // ColorImageProvider 열거형의 값들로 항목을 생성.
//           final currentImageProvider = ColorImageProvider.values[index];
//           // 현재 반복 중인 이미지 제공자.

//           return PopupMenuItem(
//             value: index, // 선택된 값의 인덱스.
//             enabled: currentImageProvider != imageSelected ||
//                 colorSelectionMethod != ColorSelectionMethod.image,
//             // 현재 선택된 이미지가 아니거나 선택 방식이 이미지가 아닌 경우 활성화.
//             child: Wrap(
//               // 아이콘과 텍스트를 가로로 나란히 배치.
//               crossAxisAlignment: WrapCrossAlignment.center, // 세로 중앙 정렬.
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.only(left: 10),
//                   child: ConstrainedBox(
//                     constraints: const BoxConstraints(maxWidth: 48),
//                     // 최대 너비를 48로 제한.
//                     child: Padding(
//                       padding: const EdgeInsets.all(4.0),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(8.0),
//                         // 이미지의 모서리를 둥글게 처리.
//                         child: Image(
//                           image: NetworkImage(currentImageProvider.url),
//                           // 네트워크 이미지를 가져옴.
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(left: 20),
//                   child: Text(currentImageProvider.label),
//                   // 이미지 제공자의 레이블을 텍스트로 표시.
//                 ),
//               ],
//             ),
//           );
//         });
//       },
//       onSelected: handleImageSelect, // 이미지가 선택되었을 때 이벤트 핸들러 호출.
//     );
//   }
// }
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
    required this.useLightMode, // 라이트 모드 활성화 여부.
    required this.handleBrightnessChange, // 밝기 변경 이벤트 핸들러.
    required this.useMaterial3, // Material 3 활성화 여부.
    required this.handleMaterialVersionChange, // Material 버전 변경 이벤트 핸들러.
    required this.handleColorSelect, // 색상 선택 이벤트 핸들러.
    required this.handleImageSelect, // 이미지 선택 이벤트 핸들러.
    required this.imageSelected, // 선택된 이미지.
    required this.colorSelected, // 선택된 색상.
    required this.colorSelectionMethod, // 색상 선택 방식.
    required this.scaffoldKey,
    required this.screenIndex,
  });

  final void Function(bool) handleBrightnessChange; // 밝기 전환 이벤트 핸들러.
  final void Function() handleMaterialVersionChange; // Material 버전 전환 이벤트 핸들러.
  final void Function(int) handleImageSelect; // 이미지 선택 이벤트 핸들러.
  final void Function(int) handleColorSelect; // 색상 선택 이벤트 핸들러.

  final bool useLightMode; // 라이트 모드 여부.
  final bool useMaterial3; // Material 3 여부.

  final ColorImageProvider imageSelected; // 현재 선택된 이미지.
  final ColorSeed colorSelected; // 현재 선택된 색상.
  final ColorSelectionMethod colorSelectionMethod; // 색상 선택 방식.
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
          
          if (screenIndex == 3) ...[
            const Divider(), // 구분선.
            _ExpandedColorSeedAction(
              // 색상 선택 동작.
              handleColorSelect: handleColorSelect,
              colorSelected: colorSelected,
              colorSelectionMethod: colorSelectionMethod,
            ),
            const Divider(), // 구분선.
            _ExpandedImageColorAction(
              // 이미지 색상 선택 동작.
              handleImageSelect: handleImageSelect,
              imageSelected: imageSelected,
              colorSelectionMethod: colorSelectionMethod,
            ),
          ]
        ],
      ),
    );
    return screenHeight > (screenIndex == 3 ? 740 : 200) //740
        ? trailingActionsBody
        : SingleChildScrollView(child: trailingActionsBody);
    // 화면 높이에 따라 스크롤 가능 여부 결정.
  }
}

class _ExpandedColorSeedAction extends StatelessWidget {
  // 확장된 색상 선택 동작.
  const _ExpandedColorSeedAction({
    required this.handleColorSelect, // 색상 선택 이벤트 핸들러.
    required this.colorSelected, // 현재 선택된 색상.
    required this.colorSelectionMethod, // 색상 선택 방식.
  });

  final void Function(int) handleColorSelect; // 색상 선택 이벤트 핸들러.
  final ColorSeed colorSelected; // 선택된 색상.
  final ColorSelectionMethod colorSelectionMethod; // 색상 선택 방식.

  @override
  Widget build(BuildContext context) {
    // UI를 빌드.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200.0),
      // 최대 높이를 제한.
      child: GridView.count(
        crossAxisCount: 3, // 3열로 구성된 그리드.
        children: List.generate(
          ColorSeed.values.length,
          // ColorSeed 열거형 값에 따라 버튼 생성.
          (i) => IconButton(
            icon: const Icon(Icons.radio_button_unchecked),
            color: ColorSeed.values[i].color, // 버튼 색상을 설정.
            isSelected: colorSelected.color == ColorSeed.values[i].color &&
                colorSelectionMethod == ColorSelectionMethod.colorSeed,
            // 현재 색상이 선택된 색상인지 여부 확인.
            selectedIcon: const Icon(Icons.circle), // 선택된 아이콘.
            onPressed: () {
              handleColorSelect(i); // 색상 선택 이벤트 호출.
            },
            tooltip: ColorSeed.values[i].label, // 툴팁으로 색상 이름 표시.
          ),
        ),
      ),
    );
  }
}

class _ExpandedImageColorAction extends StatelessWidget {
  // 확장된 이미지 색상 선택 동작.
  const _ExpandedImageColorAction({
    required this.handleImageSelect, // 이미지 선택 이벤트 핸들러.
    required this.imageSelected, // 선택된 이미지.
    required this.colorSelectionMethod, // 색상 선택 방식.
  });

  final void Function(int) handleImageSelect; // 이미지 선택 이벤트 핸들러.
  final ColorImageProvider imageSelected; // 선택된 이미지.
  final ColorSelectionMethod colorSelectionMethod; // 색상 선택 방식.

  @override
  Widget build(BuildContext context) {
    // UI를 빌드.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 150.0),
      // 최대 높이를 제한.
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: GridView.count(
          crossAxisCount: 3, // 3열로 구성된 그리드.
          children: List.generate(
            ColorImageProvider.values.length,
            // ColorImageProvider 열거형 값에 따라 버튼 생성.
            (i) => Tooltip(
              message: ColorImageProvider.values[i].name, // 툴팁 메시지 설정.
              child: InkWell(
                // 클릭 가능한 위젯.
                borderRadius: BorderRadius.circular(4.0), // 둥근 모서리.
                onTap: () => handleImageSelect(i), // 이미지 선택 이벤트 호출.
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Material(
                    borderRadius: BorderRadius.circular(4.0), // 둥근 모서리.
                    elevation: imageSelected == ColorImageProvider.values[i] &&
                            colorSelectionMethod == ColorSelectionMethod.image
                        ? 3 // 선택된 경우 그림자 높이 증가.
                        : 0, // 선택되지 않은 경우 그림자 없음.
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4.0), // 둥근 모서리.
                        child: Image(
                          image: NetworkImage(ColorImageProvider.values[i].url),
                          // 이미지 URL을 네트워크에서 가져옴.
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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

            case (3):
              // throw Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (context) => Test(),
              //     ));
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
  ExampleDestination('Edit - Item Categories', Icon(Icons.category_outlined),
      Icon(Icons.category)),
  ExampleDestination('Edit - Item Fields', Icon(Icons.label_important_outline),
      Icon(Icons.label_important)),
  ExampleDestination(
      'Favorites', Icon(Icons.favorite_outline), Icon(Icons.favorite)),
  ExampleDestination('Trash', Icon(Icons.delete_outline), Icon(Icons.delete)),
];

const List<ExampleDestination> labelDestinations = <ExampleDestination>[
  ExampleDestination(
      'Family', Icon(Icons.bookmark_border), Icon(Icons.bookmark)),
  ExampleDestination(
      'School', Icon(Icons.bookmark_border), Icon(Icons.bookmark)),
  ExampleDestination('Work', Icon(Icons.bookmark_border), Icon(Icons.bookmark)),
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

class OneTwoTransition extends StatefulWidget {
  // 하나에서 두 개로 전환하는 애니메이션.
  const OneTwoTransition({
    super.key,
    required this.animation, // 애니메이션 컨트롤러.
    required this.one, // 첫 번째 위젯.
    required this.two, // 두 번째 위젯.
  });

  final Animation<double> animation; // 애니메이션의 진행률.
  final Widget one; // 첫 번째 위젯.
  final Widget two; // 두 번째 위젯.

  @override
  State<OneTwoTransition> createState() =>
      _OneTwoTransitionState(); // 상태 클래스 생성.
}

class _OneTwoTransitionState extends State<OneTwoTransition> {
  // OneTwoTransition의 상태 관리 클래스.
  late final Animation<Offset> offsetAnimation; // 오프셋 애니메이션.
  late final Animation<double> widthAnimation; // 너비 애니메이션.

  @override
  void initState() {
    super.initState();

    offsetAnimation = Tween<Offset>(
      begin: const Offset(1, 0), // 초기 오프셋 값.
      end: Offset.zero, // 최종 위치.
    ).animate(OffsetAnimation(widget.animation));

    widthAnimation = Tween<double>(
      begin: 0, // 초기 너비 값.
      end: mediumWidthBreakpoint, // 너비 기준점.
    ).animate(SizeAnimation(widget.animation));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Flexible(
          flex: mediumWidthBreakpoint.toInt(), // 첫 번째 위젯 너비 설정.
          child: widget.one, // 첫 번째 위젯.
        ),
        if (widthAnimation.value.toInt() > 0) ...[
          Flexible(
            flex: widthAnimation.value.toInt(), // 두 번째 위젯 너비 설정.
            child: FractionalTranslation(
              translation: offsetAnimation.value, // 이동 애니메이션 적용.
              child: widget.two, // 두 번째 위젯.
            ),
          )
        ],
      ],
    );
  }
}
