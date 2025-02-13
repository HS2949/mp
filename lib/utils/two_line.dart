import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/pages/home.dart';

const smallSpacing = 10.0;


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



class BuildSlivers extends SliverChildBuilderDelegate {
  BuildSlivers({
    required NullableIndexedWidgetBuilder builder,
    required this.heights,
  }) : super(builder, childCount: heights.length);

  final List<double?> heights;

  @override
  double? estimateMaxScrollOffset(int firstIndex, int lastIndex,
      double leadingScrollOffset, double trailingScrollOffset) {
    return heights.reduce((sum, height) => (sum ?? 0) + (height ?? 0))!;
  }
}
class CacheHeight extends SingleChildRenderObjectWidget {
  const CacheHeight({
    super.child,
    required this.heights,
    required this.index,
  });

  final List<double?> heights;
  final int index;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderCacheHeight(
      heights: heights,
      index: index,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderCacheHeight renderObject) {
    renderObject
      ..heights = heights
      ..index = index;
  }
}

class _RenderCacheHeight extends RenderProxyBox {
  _RenderCacheHeight({
    required List<double?> heights,
    required int index,
  })  : _heights = heights,
        _index = index,
        super();

  List<double?> _heights;
  List<double?> get heights => _heights;
  set heights(List<double?> value) {
    if (value == _heights) {
      return;
    }
    _heights = value;
    markNeedsLayout();
  }

  int _index;
  int get index => _index;
  set index(int value) {
    if (value == index) {
      return;
    }
    _index = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    super.performLayout();
    heights[index] = size.height;
  }
}
