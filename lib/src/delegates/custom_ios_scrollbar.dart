import 'package:flutter/material.dart';

class CustomIOSScrollbar extends StatefulWidget {
  CustomIOSScrollbar(
      {super.key,
      required this.controller,
      required this.child,
      required this.thumbVisibility,
      required this.scrollbarOutsetPadding});

  final ScrollController controller;
  final Widget child;
  final bool? thumbVisibility;

  // 此处是滚动条的偏移量，iOS中，grid 相册顶部是有透明前景，高度和滚动条实际高度不一致
  final EdgeInsets scrollbarOutsetPadding;

  @override
  _CustomIOSScrollbarState createState() => _CustomIOSScrollbarState();
}

class _CustomIOSScrollbarState extends State<CustomIOSScrollbar> {
  double _thumbHeight = 0;
  double _thumbTop = 0; // iOS 当作 thumbBottom
  bool _isDragging = false;
  double _dragStartY = 0;
  double _dragStartThumbTop = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateThumbPosition);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateThumbPosition();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateThumbPosition);
    super.dispose();
  }

  void _updateThumbPosition() {
    // ScrollController.position：获取当前 ScrollController 绑定的 ScrollPosition，它管理当前滚动视图的滚动状态
    // 备注：Android 从上往下滑；iOS 从下往上滑

    // 当前滚动视图的滚动偏移量，也就是用户已经滚动的距离。
    // 备注：Android iOS 初始值都是0 （单位像素）, ios 是负数
    final double scrollOffset = widget.controller.position.pixels.abs();
    // maxScrollExtent：表示滚动视图可以滚动的最大偏移量。这是从滚动视图顶部滚动到底部所允许的最大值。
    // 备注：Android 默认是屏幕高度3000+ ；iOS 默认 0 （单位像素？）
    final double maxScrollExtent = widget.controller.position.maxScrollExtent;
    // android
    // final double scrollMax = maxScrollExtent;

    final double minScrollExtent =
        widget.controller.position.minScrollExtent.abs();
    // ios
    final double scrollMax = minScrollExtent;
    // 可见区域的高度（或宽度），即视口的尺寸。
    final double viewportHeight = widget.controller.position.viewportDimension -
        widget.scrollbarOutsetPadding.bottom -
        widget.scrollbarOutsetPadding.top;

    // _thumbHeight=844.0  scrollOffset=0.0 scrollMax=0.0 viewportHeight=844.0 _thumbHeight844.0  _thumbTop=NaN
    setState(() {
      // Calculate thumb height as a proportion of the visible viewport
      // 滑块的高度，占整个滚动视图高度的百分比
      // 计算规则：可见区域高度 / (滚动视图高度 + 可见区域高度) * 可见区域高度
      _thumbHeight =
          viewportHeight / (scrollMax + viewportHeight) * viewportHeight;
      if (_thumbHeight < 32) {
        _thumbHeight = 32;
      }
      // Calculate thumb position as a proportion of scroll offset

      //计算规则：滚动距离 / 滚动视图高度 * 可见区域高度
      _thumbTop = scrollOffset / scrollMax * (viewportHeight - _thumbHeight);
      //
      // debugPrint("jxxxxxx1 _thumbHeight=$_thumbHeight "
      //     // "position=${widget.controller.position}"
      //     " scrollOffset=$scrollOffset "
      //     " maxScrollExtent=$maxScrollExtent "
      //     " minScrollExtent=$minScrollExtent "
      //     " scrollMax=$scrollMax"
      //     " viewportHeight=$viewportHeight "
      //     "_thumbTop=$_thumbTop");
    });
  }

  void _onVerticalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragStartY = details.localPosition.dy;
      _dragStartThumbTop = _thumbTop;
      // debugPrint(
      //     "jxxxxxx2 _dragStartY=$_dragStartY _dragStartThumbTop=$_dragStartThumbTop");
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    setState(() {
      // 拖动距离
      // Android
      // final double dragDelta = details.localPosition.dy - _dragStartY;
      // iOS
      final double dragDelta = -details.localPosition.dy + _dragStartY;

      final double newThumbTop = _dragStartThumbTop + dragDelta;
      // final double maxThumbTop =
      //     widget.controller.position.viewportDimension  - _thumbHeight;

      final double maxThumbTop = widget.controller.position.viewportDimension -
          widget.scrollbarOutsetPadding.bottom -
          widget.scrollbarOutsetPadding.top -
          _thumbHeight;

      // Clamp the thumb's position between the top and the bottom of the scrollable area
      _thumbTop = newThumbTop.clamp(0.0, maxThumbTop);
      // Calculate the corresponding scroll offset and update the ScrollController
      double scrollRatio = _thumbTop / maxThumbTop;
      double newScrollOffset =
          scrollRatio * widget.controller.position.maxScrollExtent;

      final double maxScrollExtent = widget.controller.position.maxScrollExtent;
      final double minScrollExtent =
          widget.controller.position.minScrollExtent.abs();
      double newScrollOffset2 = scrollRatio * minScrollExtent;

      // debugPrint("jxxxxxx3 "
      //     "details.localPosition.dy=${details.localPosition.dy} "
      //     "_dragStartY=$_dragStartY "
      //     "dragDelta=$dragDelta "
      //     "newThumbTop=$newThumbTop "
      //     "maxThumbTop=$maxThumbTop "
      //     "_thumbHeight=$_thumbHeight "
      //     "_thumbTop=$_thumbTop "
      //     "scrollRatio=$scrollRatio "
      //     "newScrollOffset=$newScrollOffset "
      //     "maxScrollExtent=$maxScrollExtent "
      //     "minScrollExtentABS=$minScrollExtent "
      //     "newScrollOffset2=$newScrollOffset2");

      // Android
      // widget.controller.jumpTo(newScrollOffset);
      // iOS
      widget.controller.jumpTo(-newScrollOffset2);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Visibility(
          visible: widget.thumbVisibility ?? false,
          child: Positioned(
            right: 0,
            bottom: _thumbTop + widget.scrollbarOutsetPadding.bottom,
            child: GestureDetector(
              onVerticalDragStart: _onVerticalDragStart,
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              child: Container(
                width: 18.0,
                height: _thumbHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
